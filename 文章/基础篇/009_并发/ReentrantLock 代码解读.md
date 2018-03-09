## 基础铺垫

> node包装的状态:
- SIGNAL(-1) ：线程的后继线程正/已被阻塞，当该线程release或cancel时要重新这个后继线程(unpark)  
- CANCELLED(1)：因为超时或中断，该线程已经被取消  
- CONDITION(-2)：表明该线程被处于条件队列，就是因为调用了Condition.await而被阻塞
- PROPAGATE(-3)：传播共享锁
- 0：0代表无状态

### AQS的属性结构

```java

// ---------------需要注意的是这个head和tail是一个双向链表--------------------------

// 头结点，你直接把它当做 当前持有锁的线程 可能是最好理解的
private transient volatile Node head;
// 阻塞的尾节点，每个新的节点进来，都插入到最后，也就形成了一个隐视的链表
private transient volatile Node tail;
// 这个是最重要的，不过也是最简单的，代表当前锁的状态，0代表没有被占用，大于0代表有线程持有当前锁
// 之所以说大于0，而不是等于1，是因为锁可以重入嘛，每次重入都加上1
private volatile int state;
// 代表当前持有独占锁的线程，举个最重要的使用例子，因为锁可以重入
// reentrantLock.lock()可以嵌套调用多次，所以每次用这个来判断当前线程是否已经拥有了锁
// if (currentThread == getExclusiveOwnerThread()) {state++}
private transient Thread exclusiveOwnerThread; //继承自AbstractOwnableSynchronizer
```

### Node的结构

```java
static final class Node {
    /** Marker to indicate a node is waiting in shared mode */
    // 标识节点当前在共享模式下
    static final Node SHARED = new Node();
    /** Marker to indicate a node is waiting in exclusive mode */
    // 标识节点当前在独占模式下
    static final Node EXCLUSIVE = null;
  
    // ======== 下面的几个int常量是给waitStatus用的 ===========
    /** waitStatus value to indicate thread has cancelled */
    // 代表此线程取消了争抢这个锁
    static final int CANCELLED =  1;
    /** waitStatus value to indicate successor's thread needs unparking */
    // 官方的描述是，其表示当前node的后继节点对应的线程需要被唤醒
    static final int SIGNAL    = -1;
    /** waitStatus value to indicate thread is waiting on condition */
    // 表示线程处于等待的条件下的值，与下面的waitStatus对应，这在Lock中的condition中会使用
    static final int CONDITION = -2;
    /**
     * waitStatus value to indicate the next acquireShared should
     * unconditionally propagate
     */
    static final int PROPAGATE = -3;
    // =====================================================
  
    // 取值为上面的1、-1、-2、-3，或者0(以后会讲到)
    // 这么理解，暂时只需要知道如果这个值 大于0 代表此线程取消了等待，
    // 也许就是说半天抢不到锁，不抢了，ReentrantLock是可以指定timeouot的。。。
    volatile int waitStatus;
    // 前驱节点的引用
    volatile Node prev;
    // 后继节点的引用
    volatile Node next;
    // 这个就是线程本尊
    volatile Thread thread;
}
```

**这里需要搞清楚的一个概念**:

1. `head`和`tail`分别代表的是当前链表的`第一个`和`最后一个`
2. Node中的`prev`和`next`代表的是链表内的`前继节点`和`后继节点`



## lock 方法调用过程:

```java
        // step : 1
        final void lock() {
            // 如果state状态为0的话,就为他设置初始状态
            if (compareAndSetState(0, 1))
                // 绑定当前线程,表示为当前线程的独占锁
                setExclusiveOwnerThread(Thread.currentThread());
            else
                acquire(1);
        }
        
        // step : 2
        public final void acquire(int arg) {
        // 2.1 tryAcquire尝试判断是否锁为抢占或者是否是重入锁
        // 2.2 addWaiter方法负责把当前无法获得锁的线程包装为一个Node添加到队尾
        // 2.3 acquireQueued
        if (!tryAcquire(arg) &&
            acquireQueued(addWaiter(Node.EXCLUSIVE), arg))
            selfInterrupt();
        }
        
        
        ////////////////////2.1///////////////////
        // step : 2.1
        protected final boolean tryAcquire(int acquires) {
            return nonfairTryAcquire(acquires);
        }
        
        // step : 2.2 
        final boolean nonfairTryAcquire(int acquires) {
            // 获取当前线程
            final Thread current = Thread.currentThread();
            // 获取当前锁的状态
            // 0代表没有被占用，大于0代表有线程持有当前锁
            int c = getState();
            // 如果当前锁没有被占用的时候,不存在竞争的时候
            if (c == 0) {
                //通过cas将初始值0设置为1
                //如果CAS设置成功，则可以预计其他任何线程调用CAS都不会再成功，也就认为当前线程得到了该锁，也作为Running线程，
                //很显然这个Running线程并未进入等待队列。
                // 如果抢占成功....最终会返回fasle
                if (compareAndSetState(0, acquires)) {
                    //绑定当前线程
                    setExclusiveOwnerThread(current);
                    return true;
                }
            }
            // 如果已经被占用了,先判断是否是当前线程抢占的
            // 换句话说就是判断是否是重入锁
            else if (current == getExclusiveOwnerThread()) {
                // 如果是重入锁,或者是当前线程抢占的
                // 则将state的值+1 , 表示重入次数
                int nextc = c + acquires;
                if (nextc < 0) // overflow
                    throw new Error("Maximum lock count exceeded");
                // 设置重入状态
                setState(nextc);
                return true;
            }
            return false;
        } 
        
        
        /////////////////////////2.2//////////////////////
        // addWaiter方法负责把当前无法获得锁的线程包装为一个Node添加到队尾
        private Node addWaiter(Node mode) {
        // 为当前线程构建一个新的链表
        // 其中参数mode是独占锁还是共享锁，默认为null，独占锁
        Node node = new Node(Thread.currentThread(), mode);
        // Try the fast path of enq; backup to full enq on failure
    
        Node pred = tail;
        // 如果当前链表末尾不为空
        if (pred != null) {
            // 则将当前独占所的节点上级设置为上一个
            node.prev = pred;
            // 通过CAS将tail节点设置为node
            // 通俗一点讲就是更新pred的节点,也就是尾节点
            if (compareAndSetTail(pred, node)) {
                pred.next = node;
                return node;
            }
        }
        // 2.2.1
        enq(node);
        return node;
    }
    // 2.2.1 
    
    /** 
    该方法就是循环调用CAS，即使有高并发的场景，无限循环将会最终成功把当前线程追加到队尾（或设置队头）。总而言之，addWaiter的目的就是通过CAS把当前线程追加到队尾，并返回包装后的Node实例。
    把线程要包装为Node对象的主要原因，除了用Node构造供虚拟队列外，还用Node包装了各种线程状态，这些状态被精心设计为一些数字值：
        SIGNAL(-1) ：线程的后继线程正/已被阻塞，当该线程release或cancel时要重新这个后继线程(unpark)
        CANCELLED(1)：因为超时或中断，该线程已经被取消
        CONDITION(-2)：表明该线程被处于条件队列，就是因为调用了Condition.await而被阻塞
        PROPAGATE(-3)：传播共享锁
        0：0代表无状态
    */
    private Node enq(final Node node) {
        //无限循环
        for (;;) {
            // 获取当前的尾部节点
            Node t = tail;
            // 如果为空的情况
            if (t == null) { // 初始化处理
                // 通过CAS初始化
                if (compareAndSetHead(new Node()))
                    tail = head;
            } else {
                //将引用的node的上一级改为当前尾节点
                node.prev = t;
                // CAS比较将内存地址中的偏移量改为node
                if (compareAndSetTail(t, node)) {
                    // 将当前的尾部节点也改为node
                    t.next = node;
                    return t;
                }
            }
        }
    }
    
    
    
    /////////////////////////////////2.3//////////////////////////////
    //acquireQueued
    //acquireQueued的主要作用是把已经追加到队列的线程节点（addWaiter方法
    //返回值）进行阻塞，但阻塞前又通过tryAccquire重试是否能获得锁，如果
    //重试成功能则无需阻塞，直接返回
	// 这里需要注意的点:
	// 1. 唤醒的时候,如果头节点已经被取消了,则会从tail中找出最前面的有效阻塞节点,然后唤醒
	// 2. 这里的自旋只有在某个线程被唤醒,并且这个节点的前继节点为头结点的同时,自旋才会终止
    final boolean acquireQueued(final Node node, int arg) {
        boolean failed = true;
        try {
            boolean interrupted = false;
            // 注意:无限循环
            for (;;) {
                // 获取前继节点(也就是链表中的上一节点状态)
                final Node p = node.predecessor();
                // 比较头部是否相同
                // tryAcquire尝试判断当前线程是否为抢占锁或者是否是重入锁
                if (p == head && tryAcquire(arg)) {
                    // 设置头部节点
                    setHead(node);
                    // 帮助GC清空对象
                    p.next = null; // help GC
                    failed = false;
                    return interrupted;
                }
                // 这一步很关键 2.3.1
                if (shouldParkAfterFailedAcquire(p, node) &&
                	// 2.3.2
                    parkAndCheckInterrupt())
                    interrupted = true;
            }
        } finally {
            if (failed)
                cancelAcquire(node);
        }
    }
    
    // 2.3.1
    // 查询当前线程的变化
    // 刚刚说过，会到这里就是没有抢到锁呗，这个方法说的是："当前线程没有抢到锁，是否需要挂起当前线程？"
    // 第一个参数是前驱节点，第二个参数才是代表当前线程的节点
    // 概述: 当waitStatus == -1时表示需要被唤醒
    // 当返回false时表示不需要被唤醒
    private static boolean shouldParkAfterFailedAcquire(Node pred, Node node) {
        // 判断前驱节点的状态
        int ws = pred.waitStatus;
        
        // 前驱节点的 waitStatus == -1 ，说明前驱节点状态正常，当前线程需要挂起，直接可以返回true
        // 也表示当前lock()锁确实起作用了.
        if (ws == Node.SIGNAL)
            /*
             * This node has already set status asking a release
             * to signal it, so it can safely park.
             */
            return true;
            
            
        // 前驱节点 waitStatus大于0 ，之前说过，大于0 说明前驱节点取消了排队。这里需要知道这点：
        // 进入阻塞队列排队的线程会被挂起，而唤醒的操作是由前驱节点完成的。
        // 所以下面这块代码说的是将当前节点的prev指向waitStatus<=0的节点，
        // 简单说，就是为了找个好爹，因为你还得依赖它来唤醒呢，如果前驱节点取消了排队，
        // 找前驱节点的前驱节点做爹，往前循环总能找到一个好爹的
      	// 能进入到这里的节点说明已经被取消了的,取消有几种场景,其中就是超时
      	// tryLock(超时时间),一旦超时会调用cancelAcquire方法,这个方法会将waitStatus设置成大于1的情况, 如果这个线程存在多个竞争的话,可能会超过1 
        if (ws > 0) {
            /*
             * Predecessor was cancelled. Skip over predecessors and
             * indicate retry.
             */
            do {
                // 一直向前驱节点的上级节点查找,直到找到状态为0,也就是正常的线程
                node.prev = pred = pred.prev;
            } while (pred.waitStatus > 0);
            pred.next = node;
        } else {
            /*
             * waitStatus must be 0 or PROPAGATE.  Indicate that we
             * need a signal, but don't park yet.  Caller will need to
             * retry to make sure it cannot acquire before parking.
             */
            // 仔细想想，如果进入到这个分支意味着什么
            // 前驱节点的waitStatus不等于-1和1，那也就是只可能是0，-2，-3
            // 在我们前面的源码中，都没有看到有设置waitStatus的，所以每个新的node入队时，waitStatu都是0
            // 用CAS将前驱节点的waitStatus设置为Node.SIGNAL(也就是-1)
            compareAndSetWaitStatus(pred, ws, Node.SIGNAL);
        }
        return false;
    }
    
    // 2.3.2 parkAndCheckInterrupt方法
    
    // 表示挂起当前线程
    // 这个方法很简单，因为前面返回true，所以需要挂起线程，这个方法就是负责挂起线程的
    // 这里用了LockSupport.park(this)来挂起线程，然后就停在这里了，等待被唤醒=======
    private final boolean parkAndCheckInterrupt() {
      	// 直到被其他线程调用LockSupport.unpark唤醒
        LockSupport.park(this);
      	// 判断线程是否中断,如果是被唤醒的线程,则会返回false
        return Thread.interrupted();
    }
    
    // 2. 接下来说说如果shouldParkAfterFailedAcquire(p, node)返回false的情况
  
   // 仔细看shouldParkAfterFailedAcquire(p, node)，我们可以发现，其实第一次进来的时候，一般都不会返回true的，原因很简单，前驱节点的waitStatus=-1是依赖于后继节点设置的。也就是说，我都还没给前驱设置-1呢，怎么可能是true呢，但是要看到，这个方法是套在循环里的，所以第二次进来的时候状态就是-1了。
  
    // 解释下为什么shouldParkAfterFailedAcquire(p, node)返回false的时候不直接挂起线程：
    // => 是为了应对在经过这个方法后，node已经是head的直接后继节点了。剩下的读者自己想想吧。
```

#### 总结 [lock方法做了哪些事情? 经过了哪些步骤?] 我们来还原步骤
1. 初始化
- 表示当前没有抢占现象,就是第一个线程第一次调用的时候是使用CAS将状态从0改为1  
```java
                // 判断当前成状态是否为0,并且通过CAS去改变值为1,如果成功,则绑定这个线程,标识为独占锁
                if (compareAndSetState(0, 1))
                setExclusiveOwnerThread(Thread.currentThread());
```

2. 抢占锁的过程 表示当前的锁状态不为0的情况下  
  代码块:  
```java
if (!tryAcquire(arg) &&
            acquireQueued(addWaiter(Node.EXCLUSIVE), arg))
            selfInterrupt();
```


- 判断当前线程和和锁的拥有者是否为同一个,如果是同一个的话则只是简单的+1,并且设置为state,所以通过setStatus修改，而非CAS，也就是说这段代码实现了偏向锁的功能，并且实现的非常漂亮。

- 如果上面的锁**已经被抢占**,并且锁的拥有者**非当前线程**,则开始将线程添加到一个无法获得锁的线程包装链表中这个链表专门用于承装没有抢占到锁的线程,没有抢到的则会在**链表**[**阻塞队列**]的处于末端..[**`addWaiter`**方法]

    - 阻塞队列:因为  争抢锁的线程可能很多,但是只能有一个线程拿到锁,其他线程必须等待,这个时候就需要一个queue来管理这些线程,AQS用的是一个FIFO的队列,就是一个链表。每个node都持有后继节点的引用，AQS采用了CLH锁的变体来实现


- **通过自旋**将已经加到阻塞队列里面的线程进行阻塞,阻塞前会判断该节点的前继节点是否为head节点,如果是的则会尝试进行一次抢占,如果没有成功,则会对该节点的前继节点做判断,是否为有效节点<0;直到找到一个有效的停靠节点之后,才开始阻塞

    - 阻塞线程和解除阻塞采用的是AQS的LockSupport.park(thread) 来挂起线程，用unpark来唤醒线程。

- 一旦有线程被唤醒,则会回到自旋当中去继续判断该节点的前继节点是否为head。。。。直到为head为止



非公平锁的场景:  
- 假设有ABCDEF6个线程,A抢到的锁,BCDEF只能在阻塞队列中等待A释放锁的之后被唤醒.
- 这时候A刚释放完锁之后,G这时候进来了,正常来说应该排队在F后面的由B顶上的,但是,非公平的现象就出现了 
- 这时候G和B会同时抢占锁,谁先抢到谁就先上,如果G抢到了,那么B就继续在阻塞队列中候着..


其实就是当前锁已经被占有的同时,其他线程进来,发现没有锁,准备去等待队列里面等待的时候,忽然锁释放掉了,这时候就会有多个线程进行竞争`nonfairTryAcquire`方法,这里会通过CAS进行设置,谁先抢到谁就是持锁人



#### 参考文章:
http://blog.csdn.net/chen77716/article/details/6641477
https://hongjiev.github.io/2017/06/16/AbstractQueuedSynchronizer/
