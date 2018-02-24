> 文章阅读地址:<http://www.jianshu.com/p/87bff5cc8d8c>

# 1.线程池的好处

```tex
1.  降低资源消耗
2.  提高响应速度
3.  提高线程的可管理性
```

# 2.线程池如何使用?

- 1.ThreadPoolExecutor 线程池的工厂类,通过它可以快速初始化一个符合业务需求的线程池
  - corePoolSize : 线程池的核心线程数,接收到的任务创建的线程数大小
  - maximumPoolSize : 如果核心线程数满了,则会将后续任务放到阻塞队列中,这个就相当于阻塞队列的大小数
  - keepAliveTime :线程空闲时的存活时间，即当线程没有任务执行时，继续存活的时间；默认情况下，该参数只在线程数大于corePoolSize时才有用；
  - unit : keepAliveTime的单位；
  - workQueue : 用来保存等待执行任务的阻塞队列:
    - 1、ArrayBlockingQueue：基于数组结构的有界阻塞队列，按FIFO排序任务；
    - 2、LinkedBlockingQuene：基于链表结构的阻塞队列，按FIFO排序任务，吞吐量通常要高于ArrayBlockingQuene；
    - 3、SynchronousQuene：一个不存储元素的阻塞队列，每个插入操作必须等到另一个线程调用移除操作，否则插入操作一直处于阻塞状态，吞吐量通常要高于LinkedBlockingQuene；
    - 4、priorityBlockingQuene：具有优先级的无界阻塞队列；
  - handler 线程池的饱和策略，当阻塞队列满了，且没有空闲的工作线程，如果继续提交任务，必须采取一种策略处理该任务，线程池提供了4种策略：
    - 1、AbortPolicy：直接抛出异常，默认策略；
    - 2、CallerRunsPolicy：用调用者所在的线程来执行任务；
    - 3、DiscardOldestPolicy：丢弃阻塞队列中靠最前的任务，并执行当前任务；
    - 4、DiscardPolicy：直接丢弃任务； 当然也可以根据应用场景实现RejectedExecutionHandler接口，自定义饱和策略，如记录日志或持久化存储不能处理的任务。

# 3.线程池实现的原理?