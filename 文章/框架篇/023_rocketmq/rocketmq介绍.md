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

[作者简书](https://www.jianshu.com/u/c9668ae2b661)

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

- 普通消息：性能最高。

- 顺序消息: 先进先出顺序消息实现。
- 全局顺序消息: 性能差，一个主题只能一个读写队列，不能负载。但是能保证全局的顺序一致。
- 广播消息 : 发送之后，订阅该主题的消费者将会被查收。
- 延时消息:延时消息提供了一种不同于普通消息的实现形式——它们只会在设定的时限到了之后才被递送出去。例如支付超时等等。
- 批量消息: 批量发送消息可以提升投递小内存消息时的性能。

## 动态增减NameServer

通过HTTP服务来设置，默认URL : http://jmenv.tbsite.net: 8080/rocketmq/nsaddr.

通过rocketmq.namesrv.domain参数来覆盖jmenv.tbsite.net

通过rocketmq.namesrv.domain.subgroup参数来覆盖nsaddr

这种方式无需重启，组件每隔2分钟请求一次该URL，获取最新的NameServer地址。

## 动态增减broker

如果是新增的话，会首先查看注册中心的列表，均衡利用资源，另一种方式是通过updateTopic命令更改现有的topic配置，在新加的Broker上创建新的队列。

```shell
sh ./bin/mqadmin updateTopic -b 192.168.0.1:10911 -t TestTopic -n 192.168.0.100:9876
```

结果是在新增的Broker机器上为TestTopic新创建了8个读写队列。

如果是减少Broker，如果producer使用的同步发送,在DefaultMQProducer内部有个重试逻辑，其中一个Broker停了，会自动向另一个Broker发消息，不会发生丢消息的现象，如果是异步方式发送或者单向消息发送会丢失切换过程中的消息。

## 消息过滤

通过Tags的指定来过滤消费者的消息。

## 消息的优先级

### **拆分不同的topic来处理不同级别的消息**

如果有三类消息，A类消息特别多和大，处理速度比较慢的时候B、C类消息会在等候处理，这个时候如果有少量A类消息加入就会排在B、C类消息后面，需要等待很长的时间才能被等候处理。如果A类消息要被及时处理，可以把这三种类型的消息拆分成两个topic。A类消息独立的topic，BC类消息一个topic。

创建两个消费者，分别订阅不同的topic，这样A\B、C类消息互不影响。

### **通过增加MessageQueue的数量来达到消费消息公平的效果**

一个订单系统接收100家快递门店过来的请求，把这些请求通过producer写入RocketMQ；订单处理程序通过consumer从队列里读取消息并处理，**每天最多处理1万单。**

如果这100个快递门店中某个门店做活动，单子特别多。一上午就发出了2万单消息，这样99家门店可能得需要等这家门店的单子处理完，这个时候每天1W单的话就是后台才能被处理到，不太公平。

可以创建一个topic，**设置topic的MessageQueue数量超过100个，producer根据订单的门店号把每个店的单子发送到各自的MessageQueue中。消费者默认采用循环的方式逐个读取一个topic的所有MessageQueue。**这样如果某家门店订单量大增，这家门店对应的MessageQueue消息数增多，等待时间增长也不会造成其他门店都在等待这一个门店的单子处理情况。

另外DefaultMQPushConsumer默认的pullBatchSize是32，也就是每次从某个MessageQueue读取消息的时候最多可以读32个。**如果在上面的场景中为了更加公平可以设置成1个。**

### 消费者自主控制消息的遍历

应用程序有A\B\C三类优先级的消息，如果在同一个Topic中，消费者在遍历的时候可以使用PullConsumer，自主控制MQ的遍历以及消息的读取；

如果是在三个topic下，需要启动三个Consumer,实现逻辑控制三个consumer消费.

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

## 故障消息的影响

1. Broker正常关闭，启动

数据不会丢失，master挂了，会有slave顶上。生产消费不受影响

2. broker异常Crash，然后启动

3. OS Crash 重启

4. 机器断电，但能马上恢复

5. 磁盘损坏

6. CPU、主板、内存等关键设备损坏。

第2、3、4属于软件故障，内存的数据可能会丢失，这个也根据刷盘策略的不同，造成的影响不同，如果是同步刷盘策略可以达到和第一种情况相同。如果是异步刷盘存在数据丢失的情况。

第5、6点属于硬件故障，挂的那台磁盘丢失，如果是M-S配置，消息会复制到Slave不会丢失，但如果是异步复制的话，两次Sync的消息会丢失

总的来说最可靠稳定的设置方式:

1. 多Master，每个Master带有Slave
2. 主从之间设置为SYNC_MASTER
3. Producer用同步方式写;
4. 刷盘策略设置冲SYNC_FLUSH.

可以消除单点依赖，即使某台机器出现极端故障也不会丢失消息。





## 消费者

### 提高消费者的处理能力

#### 一 . 提高消费者并行度。

##### 增加消费者

其实就是增加同一个组的内的消费者，把消息均衡处理掉。

**需要注意的是: 消费者数量不要超过topic下Read Queue数量，超过的Consumer实例接收不到消息。**

##### 提高处理线程数

其次就是提高单个Consumer实例中的并行处理线程数，可以在同一个Consumer内增加并行度来提高吞吐量。【设置方式是修改consumer.setConsumeThreadMin和consumer.setConsumeThreadMax】

#### 二. 以批量的方式进行消费

某些业务的场景下，多条消息同时处理的时间会大大小于逐个处理都是时间总和，比如批量修改10条数据比一次次修改10条数据会快。

实现方式是通过设置consumer.setConsumeMessageBatchMaxSize这个参数，默认是1

#### 三. 检测延时情况，跳过非重要消息

由于某种原因，消息发生严重的堆积，短时间内无法消除堆积，这个时候可以选择丢弃不重要的消息，使consumer尽快追上producer的进度。

![1563173283865](C:\Users\liukx\AppData\Local\Temp\1563173283865.png)

当某个队列的消息堆积达到9W以上，就直接丢弃，以便追上发送消息的进度。



# 提问

## 消息类型

### 1. 顺序消息是如何实现的?

顺序消息是一对一发送的，也就是说这一类型的消息会被发往同一个队列(重写加入队列的选择部分`MessageQueueSelector接口`)，而这个队列会被单独的一个消费者消费掉，这就保证了顺序性质。

#### 那么如何确保这组消息能被发往同一个队列呢?

举例:同一个topic默认会有固定的4个读写队列，那么如果保证topic下面的一组消息落到同一个队列呢?

可以通过消息队列的Key来做，比如同一个订单，用订单编号来发送这一组消息。

### 2. 如何知道该消息是否被消费过?消费不成功如何查询?重试的消息如何查看?

这个可以根据客户端的业务，定义一个消息日志表，这个表里面分别处理消息被消费过几次。哪个消费者消费的。

当然Rocketmq控制台只需要提供该消息是否被消费过。

### 3. 如果发送的消息没有对应的订阅消费者，那么这类型的消息会怎么样？

消息会保存到队列中，直到有消费者上线。注意：每个不同的消费组第一次上线都会获取该类型的所有消息。

### 4. 如果有两个不同组的消费者，都是消费消息类型A的消息的，如果这时候消费者2挂掉了，那么类型A消息过来，消费1消费过了，消费2重启之后还会收到这条消息吗？

会收到，这涉及到消费消息的顺序点。非新的消费组会接着上次没有消费的消息开始消费。

这个需要通过`setConsumeFromWhere`配置。

**注意: 这个参数只对一个新的consumeGroup第一次启动时有效**

ConsumeFromWhere

- CONSUME_FROM_LAST_OFFSET: 第一次启动则会从最后开始消费，后续再启动接着上次消费的进度开始消费
- CONSUME_FROM_FIRST_OFFSET: 从头开始消费，后续再启动接着上次消费的进度开始消费
- CONSUME_FROM_TIMESTAMP: 从指定的时间点开始消费，后续再启动接着上次消费的进度开始消费.

## 运维类型

### 1. 多主多备在挂了的情况会有什么影响？

当一个主Master挂了，另外两个子Slave会选举其中一个顶替Master。消费者还是会正常收到消息。

如果Slave全挂了，那么这台机器上面的消息将消费不到，注册中心会摘除这个应用，将所有消息负载到另一台Master上面。

1. Master-broker 宕机，Slave-broker 无法写入消息

2. Slave-broker从节点可继续提供给consumer消费未消费完的消息

3. Master重新上线，同步已经被slave消费的offset数据





