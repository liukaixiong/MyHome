# RocketMq介绍

[github地址](https://github.com/apache/rocketmq)

[web监控](https://github.com/apache/rocketmq-externals/tree/master/rocketmq-console)

[rocketMq-spring](https://github.com/apache/rocketmq-spring/blob/master/README_zh_CN.md)

[RocketMQ设计原理与实践](https://blog.csdn.net/u011923482/article/details/90703868)



**应用场景实践类文章**

[微众银行的金融级消息服务平台建设实践和思考](https://mp.weixin.qq.com/s?__biz=MzU4NzU0MDIzOQ==&mid=2247485166&idx=2&sn=2b18fb22d69ecb50e5daf550ad076b3b&chksm=fdeb348eca9cbd9814f82b3cdd8d6b4dff682d1b7a29d0515f08a70997e1f9e6bfaf37413ca5&scene=21#wechat_redirect)

[消息规模超千亿，同程艺龙的消息系统建设实践](https://mp.weixin.qq.com/s?__biz=MzU4NzU0MDIzOQ==&mid=2247485392&idx=4&sn=e03c4c7b6d8bb9bbced7fc79615bb5a7&chksm=fdeb35b0ca9cbca6a4bd49ded82c2c4186fbc957a17fb86c80aa4a39180fcf4fc0bed69f84e7&scene=21#wechat_redirect)

[客户端最佳实践](https://yq.aliyun.com/articles/66128?spm=5176.100239.blogcont66110.24.zBiqLM&accounttraceid=6b8b1378-1468-4c77-bd1e-867de6392a59)

[**信用算力基于 RocketMQ 实现金融级数据服务的实践**](https://yq.aliyun.com/articles/695671?spm=a2c4e.11163080.searchblog.77.57912ec1x4h9w3)



## 选择理由

1. Java语言开发，降低学习维护成本。
2. 由阿里开源，并捐献给Apache维护。
3. 成熟的文档，搭建简单方便，入门快。
4. 性能好。
5. 支持延时消息、事务消息、顺序 消息。
6. 配套监控管理后台webConsole。
7. 支持消息查询，根据Key或者MessageID

## 消息发送方法

- 可靠同步发送 : 可靠同步发送在众多场景中被使用，例如重要的通知消息、短信通知、短信营销系统，等等。
- 可靠异步发送 : 对响应时间不敏感的推送。
- 单向发送:  例如日志收集。只发送不需要回调结果。

## 消息发送类型

- 顺序消息: 先进先出顺序消息实现。
- 广播消息 : 发送之后，订阅该主题的消费者将会被查收。
- 延时消息:延时消息提供了一种不同于普通消息的实现形式——它们只会在设定的时限到了之后才被递送出去。例如支付超时等等。
- 批量消息: 批量发送消息可以提升投递小内存消息时的性能。

## 消息过滤

通过Tags的指定来过滤消费者的消息。



## 对比

![img](http://www.uml.org.cn/zjjs/images/2019052931.png)

## 事务消息处理机制

![img](https://images2018.cnblogs.com/blog/270324/201808/270324-20180830192621800-1829166150.jpg)

**场景**

假设A、B两个不同的为微服务。

1. 将需要更新的数据以**Prepare**类型的消息发送出去，发送成功。注意这一步的消息是B看不到的，也就是说Prepare阶段的消息对消费者是不可见的。
2. 业务操作，更新DB。
3. 根据第二步的成功失败，来确认第一步的Prepare阶段消息是否对消费者可见，成功消息成功投递给消费者，失败回滚消息，就当这个消息没发出去过。
4. 如果第三步发送失败，MQ会定时回查该结果是否已经处理完成。默认1分钟 。



## 重试机制

如果是消费者消费消息失败，则需要返回一个`ConsumeConcurrentlyStatus.RECONSUME_LATER`状态，然后队列会自动尝试重发消息，如果在集群模式下，失败的消息还是会指定到上一次消费失败的机器上。

## 消息重复

本地构建一张日志表，用来存储当前应用消费失败或者超时(**默认15分钟**)的消息。

但还是会有这种情况:

假设业务执行特别耗时：

- 第一次已经超时了。消息队列开始执行重试机制，但是业务还在执行中。
- 查本地消息表发现已经开始消费完了或者没有消费，又执行了消费逻辑。

这个时候需要执行业务消费之前，将这条消息记录标识放入缓存，并且设置一个失效时间，例如2分钟(根据实际情况决定缓存多久)。

当消息超时被重试的时候，先检查缓存，如果发现还在执行中，则直接返回执行失败，等待下一次再检查，直到最终检查完成。

这时候缓存里面需要判断3个状态，执行中、执行完成、执行失败。

# 提问

## 顺序消息是如何实现的?

​	顺序消息是一对一发送的，也就是说这一类型的消息会被发往同一个队列，而这个队列会被单独的一个消费者消费掉，这就保证了顺序性质。

### 那么如何确保这组消息能被发往同一个队列呢?

举例:同一个topic默认会有固定的4个读写队列，那么如果保证topic下面的一组消息落到同一个队列呢?

可以通过消息队列的Key来做，比如同一个订单，用订单编号来发送这一组消息。

