# CountDownLatch

## 作用

让一些阻塞等待的线程，被一定数量的线程完成后完成唤醒.

但需要注意的是CountDownLatch只能使用一次,相当于说一旦用完了,就不会再阻塞了



原理步骤:

1. 计数器由构造函数初始化,并用它来初始化AQS的states的值
2. 当线程调用await方法时会检查state的值是否为0
  - 如果是的话
    - 表示资源池的资源已经被用光了,则不会被阻塞
  - 如果不是的话
    - 将该线程节点加入等待队列
    - 将自身进行阻塞
3. 当其他线程调用countDown方法时
   1. 将计数器减一
   2. 判断计数器是否为0
      1. 为0时唤醒队列中的第一个节点
         1. 由于CountDownLatch使用了共享模式所以第一个节点被唤醒之后,又会触发下一个节点的释放(自旋)，并且依此类推,使得所有节点都能被唤醒




## 方法原理介绍

### **await**

```java
// 尝试共享中断
private void doAcquireSharedInterruptibly(int arg)
    throws InterruptedException {
  	// 1.  将该节点加入到等待队列
    final Node node = addWaiter(Node.SHARED);
    boolean failed = true;
    try {
      // 自旋
        for (;;) {
          	// 获取当前等待队列中的前继节点
            final Node p = node.predecessor();
          	// 如果当前节点等于前继节点
          	// 假设
          	// 1. 可能是第一个进入等待的,所以队列中只有一个
          	// 2. 可能是等待队列中的节点已经放弃光了,
            if (p == head) {
              	// 尝试获取锁,看是否已经资源没有了
                int r = tryAcquireShared(arg);
              	// 如果资源已经没有了,说明可以释放锁了
                if (r >= 0) {
                  	// 重新设置头部,并且释放锁
                    setHeadAndPropagate(node, r);
                    p.next = null; // help GC
                    failed = false;
                    return;
                }
            }
          	// 找到一个可靠的前继节点
            if (shouldParkAfterFailedAcquire(p, node) &&
                // 阻塞该节点,等待被唤醒
                parkAndCheckInterrupt())
                throw new InterruptedException();
        }
    } finally {
        if (failed)
            cancelAcquire(node);
    }
}
```
### **countDown**

```java
// 释放共享锁
public final boolean releaseShared(int arg) {
  	//1. 尝试释放共享锁
    if (tryReleaseShared(arg)) {
		// 释放锁的操作
        doReleaseShared();
        return true;
    }
    return false;
}

// 1. 尝试释放共享锁
protected boolean tryReleaseShared(int arg) {
  // Decrement count; signal when transition to zero
  // 自旋
  for (; ; ) {
    // 获取当前资源数
    int c = getState();
    // 如果为0的话,这里的话表示不需要阻塞了
    if (c == 0) {
      return false;
    }
    // --------------------------如果资源数还有的话-------------------------------------
    // 递减1
    int nextc = c - 1;
    // 之后通过CAS自旋去获取 , 这里的c就是getState()的state是volatile修饰,其他线程改了这里一定能看到	// 这里通过CAS去判断当前资源是否有竞争,没有竞争的话会赋值成功
    // 条件中会判断是否为0 , 这里为true的话,会触发上面的释放锁的操作
    if (compareAndSetState(c, nextc)) {
      return nextc == 0;
    }
  }
}

// 这里就是真正的释放锁的操作
private void doReleaseShared() {
  /*
           * Ensure that a release propagates, even if there are other
           * in-progress acquires/releases.  This proceeds in the usual
           * way of trying to unparkSuccessor of head if it needs
           * signal. But if it does not, status is set to PROPAGATE to
           * ensure that upon release, propagation continues.
           * Additionally, we must loop in case a new node is added
           * while we are doing this. Also, unlike other uses of
           * unparkSuccessor, we need to know if CAS to reset status
           * fails, if so rechecking.
           */
  // 自旋,通过头结点进行释放
  /**
  这里需要先声明一个细节点,不然很容易被绕进去,这里的正常逻辑应该是
  1. head的节点是Node.SIGNAL状态
  2. 单个线程释放头结点的时候肯定会经过unparkSuccessor方法,这个方法会将头结点唤醒之后,会经过自旋回到doAcquireSharedInterruptibly中的setHeadAndPropagate方法重新更换头结点,一般是让下一级节点顶上
  3. h == head 一定是为true的 (前提是单个线程的情况下)
  
  而下面的代码,除了正常情况,其他的都是抢占并发资源的情况,如何去调整?都是通过自旋的方式,一遍一遍的去释放,直道最终释放完毕h == head 自旋结束
  */
  for (;;) {
    Node h = head;
    
    if (h != null && h != tail) {
      // 获取头结点的状态
      int ws = h.waitStatus;
      // 如果是阻塞的状态则开始设置为自由状态
      if (ws == Node.SIGNAL) {
        // 如果存在多个线程的竞争,则跳过这个循环,下一次继续
        if (!compareAndSetWaitStatus(h, Node.SIGNAL, 0))
          continue;            // loop to recheck cases
        // 如果上面设置成功了,则这里开始针对这个节点做唤醒操作
        unparkSuccessor(h);
      }
      // 如果本身就是自由状态,则将这个状态设置为传播状态,等待
      else if (ws == 0 &&
               !compareAndSetWaitStatus(h, 0, Node.PROPAGATE))
        continue;                // loop on failed CAS
    }
    if (h == head)                   // loop if head changed // __ 这里需要注意的是,如果h!=head说明已经被其他线程操作过一遍了,重新再来,又从头结点开始释放
      break;
  }
}

```
# CyclicBarrier

## **作用**

构造方法传递一个初始值，当线程执行到该对象的await方法时会先阻塞。

如果阻塞的线程的数量达到初始值，则会开始唤醒阻塞的线程。然后再继续下一轮的线程统计。



## 方法原理介绍

**CyclicBarrier 构造方法**

```java
public CyclicBarrier(int parties) {
    this(parties, null);
}

public CyclicBarrier(int parties, Runnable barrierAction) {
if (parties <= 0) throw new IllegalArgumentException();
  	// 构建一个初始变量,用于重复使用
    this.parties = parties;
  	// 当前总数的变量,用来做计算
    this.count = parties;
  	// 当count变量变成0的时候,会触发这个线程中的方法
    this.barrierCommand = barrierAction;
}
```



**dowait**

```java
/**
 * 主要的屏障代码,涵盖了各种策略
 */
private int dowait(boolean timed, long nanos)
    throws InterruptedException, BrokenBarrierException,
           TimeoutException {
             
    // 使用独占所,确保只能有一个线程获取锁,执行下面操作
    final ReentrantLock lock = this.lock;
    lock.lock();
    try {
      	// 当前屏障中的范围的对象是否有效的标识
        final Generation g = generation;
		// 一旦屏障出现故障,便报错
        if (g.broken)
            throw new BrokenBarrierException();

      	// 如果线程已经中断了
        if (Thread.interrupted()) {
          	// 一旦当前处于屏障中的线程发生了中断
          	// 则直接影响到当前屏障范围内的所有线程
          	// 直接唤醒屏障内的线程,并且将该屏障内的周期重置
            breakBarrier();
            throw new InterruptedException();
        }
		// 当前屏障总数减一
        int index = --count;
      	// 如果为0的话,表示屏障已经使用完毕
        if (index == 0) {  // tripped
          	// 该范围内执行结果标识
            boolean ranAction = false;
            try {
              	// 获取执行线程,
                final Runnable command = barrierCommand;
                if (command != null)
                    command.run();
              	//表示执行成功
                ranAction = true;
              	// 开始下一次生成
                nextGeneration();
                return 0;
            } finally {
                if (!ranAction)
                    breakBarrier();
            }
        }

        // loop until tripped, broken, interrupted, or timed out
      	// 这里用来处理超时的机制
        for (;;) {
            try {
              	// 如果非超时,则直接阻塞
                if (!timed)
                    trip.await();
                else if (nanos > 0L)
                  	// 如果还没有到达超时时间,则直接通过conditions的方法进行处理
                    nanos = trip.awaitNanos(nanos);
            } catch (InterruptedException ie) {
                if (g == generation && ! g.broken) {
                    breakBarrier();
                    throw ie;
                } else {
                    // We're about to finish waiting even if we had not
                    // been interrupted, so this interrupt is deemed to
                    // "belong" to subsequent execution.
                    Thread.currentThread().interrupt();
                }
            }

            if (g.broken)
                throw new BrokenBarrierException();
			// 如果是同一个屏障内生成的对象相等
            if (g != generation)
                return index;// 也按照index处理

          	// 如果超时了,则按照线程中断的处理方式去处理
            if (timed && nanos <= 0L) {
                breakBarrier();
                throw new TimeoutException();
            }
        }
    } finally {
      	//释放锁
        lock.unlock();
    }
}



/**
* Sets current barrier generation as broken and wakes up everyone.
* Called only while holding lock.
* 其实就是说当前屏障已经被打破了,直接唤醒所有屏障内的线程
*/
private void breakBarrier() {
  // 当前标识对象设置为true会被异常触发
  generation.broken = true;
  // 重新回到初始值
  count = parties;
  // 唤醒所有线程
  trip.signalAll();
}

/**
* Updates state on barrier trip and wakes up everyone.
* Called only while holding lock.
* 重置成一个新的屏障
*/
private void nextGeneration() {
  // signal completion of last generation
  // 唤醒所有线程
  trip.signalAll();
  // set up next generation
  // 将统计总数重置为初始值
  count = parties;
  // 重新构建一个生成对象
  generation = new Generation();
}
```



## 执行流程

1. 构建一个线程屏障个数范围值
2. 当一个线程开始阻塞的时候,会用ReentrantLock进行加锁
3. 判断当前屏障范围内的线程是否有效
   1. 如果其中一个线程无效了(中断或者超时)
      1. 则唤醒该屏障内的所有线程
      2. 重新初始化屏障环境
4. 屏障范围数递减
5. 判断范围数是否已经为0
   1. 如果为0 则表示范围内的线程数量已经达到唤醒的条件了
      1. 重新初始化屏障环境
      2. 执行触发线程(由使用者传递)
6. 如果没有范围数不为0
   1. 通过**ReentrantLock**的`Condition`的条件组进行阻塞
      1. 如果是超时情况的话通过`awaitNanos`方法进行阻塞
      2. 一旦超时,则该范围内的线程都会被唤醒
      3. 屏障环境重置



# Semaphore

Semaphore是信号量，用于管理一组资源。其内部是基于AQS的共享模式，AQS的状态表示许可证的数量，在许可证数量不够时，线程将会被挂起；而一旦有一个线程释放一个资源，那么就有可能重新唤醒等待队列中的线程继续执行。

## 作用

可以用于资源保护机制,例如同一时间允许的最大并发量。



## 方法原理介绍

**acquire**:

```java

public final void acquireSharedInterruptibly(int arg)
        throws InterruptedException {
    if (Thread.interrupted())
        throw new InterruptedException();
  	// 如果资源的数量小于0了
    if (tryAcquireShared(arg) < 0)
      	// 阻塞当前还在抢占的线程
        doAcquireSharedInterruptibly(arg);
}

// 尝试获取共享锁
protected int tryAcquireShared(int acquires) {
  for (;;) {
    // 如果等待队列中还有线程等待,则说明资源已经被抢光了,直接排到后面等待吧
    if (hasQueuedPredecessors())
      return -1;
 	// 获取状态之后进行递减得到的资源数是否为0
    int available = getState();
    int remaining = available - acquires;
    // 如果小于0,或者CAS成功之后,返回值
    if (remaining < 0 ||
        compareAndSetState(available, remaining))
      return remaining;
  }
}

/**
 * 能进入到这个方法的话说明资源数已经被用光了
 * 这个方法只需要负责,将这些没有抢占到的资源给放到阻塞队列中并阻塞即可
 */
private void doAcquireSharedInterruptibly(int arg)
        throws InterruptedException {
  	// 将当前线程构建成一个新的节点,并且加入到阻塞队列尾部
    final Node node = addWaiter(Node.SHARED);
    boolean failed = true;
    try {
      // 自旋
      for (;;) {
        // 获取等待队列中的最后一个节点
        final Node p = node.predecessor();
        // 如果这个节点是head节点的话
        if (p == head) {
          // 尝试抢占一下锁
          int r = tryAcquireShared(arg);
          // 如果资源锁还有的情况下
          if (r >= 0) {
            // 释放当前正在阻塞的对象,如果有的对象正在阻塞中,则设置成PROPAGATE状态
            setHeadAndPropagate(node, r);
            p.next = null; // help GC
            failed = false;
            return;
          }
        }
        // 加入到阻塞队列中,并且获取一个有效的前继节点
        if (shouldParkAfterFailedAcquire(p, node) &&
            // 阻塞该节点
            parkAndCheckInterrupt())
          throw new InterruptedException();
      }
    } finally {
      if (failed)
        cancelAcquire(node);
    }
}

```

**执行流程**:

 1.  判断state的资源数是否小于0

     1.1 不小于 -->  通过CAS将数值-1之后返回

     1.2 进入2

     2. 将当前线程构建成一个新的Node节点

     3. 获取新的节点的前继节点,如果是head节点?

       1. 再次尝试获取资源数,如果大于0
       2. 则释放该节点

     4. 将当前节点挂靠到一个可靠的前节点下,并加入到等待队列中

     5. 开始进行自我阻塞,等待被唤醒

**release**:

```java
public final boolean releaseShared(int arg) {
  	// 尝试释放锁,资源数提升
    if (tryReleaseShared(arg)) {
      	// 释放锁
        doReleaseShared();
        return true;
    }
    return false;
}
// 这里就是简单的通过CAS将资源锁进行累加
protected final boolean tryReleaseShared(int releases) {
  for (;;) {
    int current = getState();
    int next = current + releases;
    if (next < current) // overflow
      throw new Error("Maximum permit count exceeded");
    if (compareAndSetState(current, next))
      return true;
  }
}

private void doReleaseShared() {
  for (;;) {
    // 拿到头节点
    Node h = head;
    if (h != null && h != tail) {
      int ws = h.waitStatus;
      // 头结点的状态判断
      if (ws == Node.SIGNAL) {
        // 将头结点设置成自由状态
        if (!compareAndSetWaitStatus(h, Node.SIGNAL, 0))
          continue;            // loop to recheck cases
        // 释放锁,从尾节点一直到头结点
        unparkSuccessor(h);
      }
      // 如果当前头结点还没有处于阻塞状态,则直接设置成传播状态
      else if (ws == 0 &&
               !compareAndSetWaitStatus(h, 0, Node.PROPAGATE))
        continue;                // loop on failed CAS
    }
    // 如果上面的锁已经释放完毕了,这里的头结点也肯定就为空了
    if (h == head)                   // loop if head changed
      break;
  }
}
// 具体释放锁的方法
private void unparkSuccessor(Node node) {
  // 获取要释放锁的节点的等待状态,一般是-1 阻塞状态
  int ws = node.waitStatus;
  
  if (ws < 0)
    compareAndSetWaitStatus(node, ws, 0);
  // 如果该节点的下级节点为空
  Node s = node.next;
  if (s == null || s.waitStatus > 0) {
    s = null;
    // 从下往上找,一直找到第一个状态<=的进行释放
    for (Node t = tail; t != null && t != node; t = t.prev)
      if (t.waitStatus <= 0)
        s = t;
  }
  // 如果该node的下级节点不为空,则直接唤醒
  if (s != null)
    LockSupport.unpark(s.thread);
}
```

**运行流程**

1. 获取当前资源锁并且通过CAS累加
2. 尝试释放锁,从头结点开始 - doReleaseShared
3. 拿到头结点之后,判断头节点的状态
   1. 如果阻塞,则开始唤醒
   2. 如果状态为自由状态,则设置成共享状态标志
      1. 为什么会这么做,因为多个线程同时操作的时候,头节点可能会被操作不及时
      2. 头节点一旦被多个线程操作,势必会引起线程安全问题,所以这里也是为什么要使用自旋去从头结点释放
      3. 如果h不等于头结点?说明已经被其他线程操作过一遍了,这里又要重新开始释放一次

# 二者比较

## CountDownLatch

1. 不可重用
2. countDown后可以继续执行自己的任务
3. 一般是阻塞主线程(**await**),子线程不会阻塞(**countDown**)
4. ​




## CyclicBarrier

1. 可重用
2. **await**后直接阻塞,但是如果出现线程中断或者超时,则直接唤醒该范围内的所有线程
3. CyclicBarrier底层是用ReentrantLock的Condition去做的组唤醒



