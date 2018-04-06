# AQS 介绍

aqs是指java.util.concurrent.locks包下的类AbstractQueuedSynchronizer，这个类是java.util.concurrent包的基础，同步工具类Semaphore、CountDownLatch、ReentrantLock、ReentrantReadWriteLock都是基于aqs实现。在aqs类上的第一段注释如下 ，英语不溜就不作翻译了，大概意思是aqs是实现阻塞锁和一些基于FIFO(先进先出)同步器的基类，类中包含一个int类型状态state代表着锁被获取和释放：

> /** 
> \* Provides a framework for implementing blocking locks and related 
> \* synchronizers (semaphores, events, etc) that rely on 
> \* first-in-first-out (FIFO) wait queues. This class is designed to 
> \* be a useful basis for most kinds of synchronizers that rely on a 
> \* single atomic {@code int} value to represent state. Subclasses 
> \* must define the protected methods that change this state, and which 
> \* define what that state means in terms of this object being acquired 
> \* or released. Given these, the other methods in this class carry 
> \* out all queuing and blocking mechanics. Subclasses can maintain 
> \* other state fields, but only the atomically updated {@code int} 
> \* value manipulated using methods {@link #getState}, {@link 
> \* #setState} and {@link #compareAndSetState} is tracked with respect 
> \* to synchronization.

#### aqs结构

以下是aqs的state属性，代表锁的状态。 
FIFO队列的head、tail，代表竞争锁的线程队列的头尾节点

```java
    private transient volatile Node head;
    private transient volatile Node tail;
    private volatile int state;    
```

其中Node类有以下几个属性

```java
/** Marker to indicate a node is waiting in shared mode */
        /**标记表示node等待在共享模式*/
        static final Node SHARED = new Node();
        /** Marker to indicate a node is waiting in exclusive mode */
        /**标记用来表示节点是独占模式*/
        static final Node EXCLUSIVE = null;

        /** waitStatus value to indicate thread has cancelled */
        /**等待状态值用来表示线程已经取消了*/
        static final int CANCELLED =  1;
        /** waitStatus value to indicate successor's thread needs unparking */
        /**等待状态用来表示继任者线程需要唤醒*/
        static final int SIGNAL    = -1;
        /** waitStatus value to indicate thread is waiting on condition */
        /**等待状态表示线程等待在一个condition上*/
        static final int CONDITION = -2;
        /**
         * waitStatus value to indicate the next acquireShared should
         * unconditionally propagate
         */
        /**等待状态表示下一个acquireShared方法需要无条件的传播*/
        static final int PROPAGATE = -3;

       volatile Node prev;//node在队列中的前一节点
       volatile Node next;//node在队列中的后一节点  
       volatile Thread thread;//持有node的线程引用
```

#### aqs方法

aqs最主要的几个方法如下：

##### 独占锁

```java
public final void acquire(int arg)//获取独占锁方法
public final void acquireInterruptibly(int arg)//获取独占锁的可中断版本
public final boolean tryAcquireNanos(int arg, long nanosTimeout)//获取独占锁的带超时版本

//尝试获取独占锁的方法，交由子类实现，形成各种不同的获取锁策略
protected boolean tryAcquire(int arg) {
        throw new UnsupportedOperationException();
}
//独占锁释放方法
public final boolean release(int arg)
//尝试释放独占锁的方法，交由子类实现，形成各种不同的释放锁策略
protected boolean tryRelease(int arg) {
  throw new UnsupportedOperationException();
} 
```

##### 共享锁

```java
public final void acquireShared(int arg)//获取共享锁方法
public final void acquireSharedInterruptibly(int arg)//获取共享锁的可中断版本
private boolean doAcquireSharedNanos(int arg, long nanosTimeout)//获取共享锁的带超时版本
//尝试获取共享锁的方法，交由子类实现，形成各种不同的获取锁策略
protected int tryAcquireShared(int arg) {
        throw new UnsupportedOperationException();
}
//尝试释放独占锁的方法，交由子类实现，形成各种不同的释放锁策略
public final boolean releaseShared(int arg) 
protected boolean tryReleaseShared(int arg) {
    throw new UnsupportedOperationException();
} 
```

#### 原理讲解

##### acquire步骤

aqs定义了获取锁，释放锁的流程，但是对具体如何获取一个锁，释放一个锁则交由子类来实现。我们一起来看看aqs获取独占锁的流程：

```java
  public final void acquire(int arg) {
        /**
         * 1 tryAcquire尝试获取独占锁,成功则获取成功，方法完成，不成功则进入步骤2
         * 2 addWaiter 创建一个独占模式node，添加到锁竞争线程队列并进入到步骤3
         * 3 acquireQueued 竞争线程队列中节点尝试获取锁
         */
        if (!tryAcquire(arg) &&
            acquireQueued(addWaiter(Node.EXCLUSIVE), arg))
            selfInterrupt();
  } 
```

###### acquire步骤1

由子类实现

###### acquire步骤2

获取锁失败，添加一个等待节点加入到竞争队列

```java
    private Node addWaiter(Node mode) {
        //1.新建一个代表当前线程的node
        Node node = new Node(Thread.currentThread(), mode);
        // Try the fast path of enq; backup to full enq on failure
        Node pred = tail;
        //2.如果等待队列尾节点不为空，则将node加入到队列尾部
        if (pred != null) {
            node.prev = pred;
            if (compareAndSetTail(pred, node)) {
                pred.next = node;
                return node;
            }
        }
        //如果队列尾为空，则将node加入到队列头
        enq(node);
        return node;
    } 
```

###### acquire步骤3：

加入到竞争队列中节点尝试获取锁

```java
final boolean acquireQueued(final Node node, int arg) {
        boolean failed = true;
        try {
            boolean interrupted = false;
            for (;;) {
                //1.获取当前节点的前一节点
                final Node p = node.predecessor();
                //2.如果前一节点是头节点，则尝试获取锁（公平锁的获取方式，只有队列的第二                个节点才会尝试获取锁）
                if (p == head && tryAcquire(arg)) {
                    //获取锁则将当前节点设置为头结点
                    setHead(node);
                    p.next = null; // help GC
                    failed = false;
                    return interrupted;
                }
                //3. 获取锁失败后判断是否需要阻塞，如果是进入4
                //4 阻塞当前线程，如果阻塞后被唤醒状态是已中断，设置为已中断
                if (shouldParkAfterFailedAcquire(p, node) &&
                    parkAndCheckInterrupt())
                    interrupted = true;
            }
        } finally {
            if (failed)
                cancelAcquire(node);
        }
    } 
```

###### acquireQueued步骤3：

如果前一节点为SIGNAL状态，表示这个节点释放锁的时候会唤醒后续节点，则这个节点可以阻塞

###### acquireQueued步骤4

```java
 private final boolean parkAndCheckInterrupt() {
        LockSupport.park(this);//阻塞当前线程
        return Thread.interrupted();//被唤醒后返回是否被中断
}
```

##### release步骤

```java
public final boolean release(int arg) {
        if (tryRelease(arg)) {
            Node h = head;
            //如果头节点不为空，并且状态不为0，唤醒后续节点
            if (h != null && h.waitStatus != 0)
                unparkSuccessor(h);
            return true;
        }
        return false;
}
```

##### acquireShared 步骤

```java
 public final void acquireShared(int arg) {
        if (tryAcquireShared(arg) < 0)
            //尝试获取共享锁失败，则进入doAcquireShared方法
            doAcquireShared(arg);
} 
```

###### doAcquireShared步骤

doAcquireShared与acquireQueued类似，但是会在获取了共享锁之后，会尝试唤醒后续的节点，让其来获取共享锁

```java
 private void doAcquireShared(int arg) {
        final Node node = addWaiter(Node.SHARED);
        boolean failed = true;
        try {
            boolean interrupted = false;
            for (;;) {
                //如果新增的节点前任节点是头节点
                final Node p = node.predecessor();
                if (p == head) {
                    //尝试获取共享锁
                    int r = tryAcquireShared(arg);
                    if (r >= 0) {
                        //获取共享锁成功则设置自己为头节点并尝试唤醒后续节点
                        setHeadAndPropagate(node, r);
                        p.next = null; // help GC 回收之前的头节点
                        if (interrupted)
                            selfInterrupt();
                        failed = false;
                        return;
                    }
                }
                //如果获取锁失败，前任节点状态为SIGNAL，则当前节点阻塞
                if (shouldParkAfterFailedAcquire(p, node) &&
                    parkAndCheckInterrupt())
                    interrupted = true;
            }
        } finally {
            if (failed)
                cancelAcquire(node);
        }
    }
```