# 1. 快速入门

## 1.1 消息队列功能介绍

分布式消息队列可以提供**应用解耦**、**流量削峰**、**消息分发**等功能。

### 1.1.1 应用解耦

电商应用中的订单系统、库存系统、物流系统、支付系统。

如果各个子系统之间的耦合性太高、整体系统的可用性会大幅度降低。

多个低错误率的子系统强耦合在一起得到的是一个高错误率的整体系统。

**举例:**

比如当用户下单之后需要通知库存，这时候物流系统故障，那么传统的就会直接返回失败，如果是消息队列的话，将消息推送到队列中，物流系统恢复之后，再从消息队列中获取。整个流程不会受到影响。

![1562568093250](D:\github\MyHome\文章\框架篇\023_rocketmq\assets\1562568093250.png)

### 1.1.2 流量削峰

短期的瞬时流量访问，通过利用消息队列，把大量的请求暂存起来分散到相对长的一段时间内处理，能大大提高系统的稳定性。

举例:

订单系统最多能处理一万次下单，这个能力正常情况处理没有问题， 秒回。但是活动日的话流量过大。

传统做法是每秒超过一万次就不允许下单了。

如果有消息队列做缓冲，可以取消这个限制，把一秒内下的订单分散成一段时间来处理，这时有些用户可能在下单后十几秒收到下单成功的状态，但也比下单失败提示好。

优势是应对瞬时流量，平常又没有这么大流量，经济实惠方案简单。

### 1.1.3 消息分发

数据对于公司来说是未来发展的金矿，可以做用户画像、精准推送、流程优化等各种操作，实时性高，数据是不断产生的，各个分析团队、算法团队都依赖这些数据来进行工作，这个时候有个可持久化的消息队列就非常的重要。

数据的生产方只需要将数据生产到消息队列即可，数据的使用方根据各自的需求订阅自己感兴趣的数据，不同的数据团队锁订阅的数据可以重复也可以不重复，互不干扰，也不必和数据产生关联。

#### 最终一致性

消费者如果消息确认失败，会触发重试机制。

默认的时间间隔:10s/30s/1m/ 

#### 动态扩容

# 2. 生产环境下的配置和使用

## 2.1 rocketMQ各部分角色介绍

**角色描述**

1. producer : 生产者。
2. consumer : 消费者
3. broker : 消息存储的管道。
4. nameServer : 相当于注册中心。

## 2.2.2 配置参数介绍

`namesrvAddr` : 注册中心地址，多个用；号拆分。

`brokerClusterName`: cluster的地址，如果集群机器数比较多，可以分成多个Cluster，每个Cluster供一个业务群使用。

`brokerName` : broker的名称，Master和Slave通过使用相同的broker名称来表明相互关系，以说明某个Slave是哪个Master的Salve。

`brokerId`:一个Master Broker可以有多个Slave，0表示master，大于0表示不同的slave的ID

`fileReservedTime`: 磁盘上保存消息的时长，单位是小时，自动删除超时的消息。

`deleteWhen` : 与`fileReservedTime`对应，表明在几点做消息删除的动作，04表示凌晨4点。

`brokerRole`: 有3中:SYNC_MASTER、ASYNC_MASTER、SLAVE。关键词SYNC和ASYNC表示Master和Slave之间同步消息的机制，SYNC的意思是当Slave和Master消息同步完成之后，再返回发送成功的状态。

`flushDiskType` : 表示刷盘策略，分为SYNC_FLUSH和ASYNC_FLASH两种，分别代表同步刷盘和异步刷盘。

同步刷盘情况下,消息真正写入磁盘后再返回成功的状态，消息不会丢，但是效率会慢。

异步刷盘情况下，消息写入page_cache后就返回成功状态，有可能出现消息丢失的情况。

`listenPort`: broker监听的端口号，如果一台机器启动了多个broker，则要设置不同的端口号，避免冲突。

`storePathRootDir`: 存储消息以及一些配置信息的跟目录。

> 以上参数需要重启broker生效。

# 3. 用适合的方式发送和接收消息

## 3.1 不同类型的消费者

`DefaultMQPushConsumer` : 由系统控制读取操作，收到消息后自动调用传入的处理方法来处理；

`DefaultMQPullConsumer` : 读取操作中的大部分功能使用者自主控制。

### DefaultMQPushConsumer

**RocketMQ**支持两种消息模型: **Clustering**和**Broadcasting**。

`Clustering 集群模式` : 每个consumer只消费订阅消息的一部分内容。同一个ConsumerGroup里的所有Consumer消费的内容合起来才是所订阅的Topic内容的整体，从而达到负载均衡的目的。

`Broadcasting 广播模式` : 同一个ConsumerGroup里的每个consumer都能消费到所订阅topic的全部消息，也就是一个消息会被多次分发，被多个Consumer消费。

NameServer的地址和端口号可以填写多个，分号隔开。

topic名称用来标识消息类型，通过Tag进行消息过滤。



#### 流量控制

pushConsumer的核心还是pull方式，所以采用这种方式的客户端能够根据自身的处理速度调整获取消息的操作速度。因为采用多线程处理方式，流量控制的方面比单线程复杂的多。

DefaultMQPushConsumer有个线程池，消息处理逻辑在各个线程里同时执行，这个线程池的代码定义如下：

```java
this.consumeExecutor = new ThreadPoolExecutor(     this.defaultMQPushConsumer.getConsumeThreadMin(), this.defaultMQPushConsumer.getConsumeThreadMax(),
            1000 * 60,
            TimeUnit.MILLISECONDS,
            this.consumeRequestQueue,
            new ThreadFactoryImpl("ConsumeMessageThread_"));
```

pull得到的消息如果直接交给线程池去执行很难监控，比如如何的值当前消息堆积的数量？如何重复处理某些消息？如何延迟处理某些消息？

RocketMQ定义了一个快照类**ProcessQueue**来解决这些问题。

1. 在DefaultMQPushConsumer运行的时候，每个Message Queue都会有个对应的ProcessQueue对象，保存了这个Message Queue消息处理状态的快照
2. ProcessQueue对象里面主要内容是一个TreeMap和一个读写锁，TreeMap里以Message Queue的offset作为key，以消息内容的引用为Value，保存了所有从MessageQueue获取到但是还未被处理的消息；
3. 读写锁控制着多个线程对TreeMap的对象访问.
4. 有了ProcessQueue对象，流量控制就方便多了 客户端每次pull请求前会做下面三个判断来控制流量。

DefaultMQPushConsumerImpl.pullMessage

```java
long cachedMessageCount = processQueue.getMsgCount().get();
long cachedMessageSizeInMiB = processQueue.getMsgSize().get() / (1024 * 1024);
// 判断消息个数
if (cachedMessageCount > this.defaultMQPushConsumer.getPullThresholdForQueue()) {
    this.executePullRequestLater(pullRequest, PULL_TIME_DELAY_MILLS_WHEN_FLOW_CONTROL);
    if ((queueFlowControlTimes++ % 1000) == 0) {
        log.warn(
            "the cached message count exceeds the threshold {}, so do flow control, minOffset={}, maxOffset={}, count={}, size={} MiB, pullRequest={}, flowControlTimes={}",
            this.defaultMQPushConsumer.getPullThresholdForQueue(), processQueue.getMsgTreeMap().firstKey(), processQueue.getMsgTreeMap().lastKey(), cachedMessageCount, cachedMessageSizeInMiB, pullRequest, queueFlowControlTimes);
    }
    return;
}
// 判断消息的总大小
if (cachedMessageSizeInMiB > this.defaultMQPushConsumer.getPullThresholdSizeForQueue()) {
    this.executePullRequestLater(pullRequest, PULL_TIME_DELAY_MILLS_WHEN_FLOW_CONTROL);
    if ((queueFlowControlTimes++ % 1000) == 0) {
        log.warn(
            "the cached message size exceeds the threshold {} MiB, so do flow control, minOffset={}, maxOffset={}, count={}, size={} MiB, pullRequest={}, flowControlTimes={}",
            this.defaultMQPushConsumer.getPullThresholdSizeForQueue(), processQueue.getMsgTreeMap().firstKey(), processQueue.getMsgTreeMap().lastKey(), cachedMessageCount, cachedMessageSizeInMiB, pullRequest, queueFlowControlTimes);
    }
    return;
}

if (!this.consumeOrderly) {
    if (processQueue.getMaxSpan() > this.defaultMQPushConsumer.getConsumeConcurrentlyMaxSpan()) {
        this.executePullRequestLater(pullRequest, PULL_TIME_DELAY_MILLS_WHEN_FLOW_CONTROL);
        if ((queueMaxSpanFlowControlTimes++ % 1000) == 0) {
            log.warn(
                "the queue's messages, span too long, so do flow control, minOffset={}, maxOffset={}, maxSpan={}, pullRequest={}, flowControlTimes={}",
                processQueue.getMsgTreeMap().firstKey(), processQueue.getMsgTreeMap().lastKey(), processQueue.getMaxSpan(),
                pullRequest, queueMaxSpanFlowControlTimes);
        }
        return;
    }
} else {
    if (processQueue.isLocked()) {
        if (!pullRequest.isLockedFirst()) {
            // 判断offset的跨度.
            final long offset = this.rebalanceImpl.computePullFromWhere(pullRequest.getMessageQueue());
            boolean brokerBusy = offset < pullRequest.getNextOffset();
            log.info("the first time to pull message, so fix offset from broker. pullRequest: {} NewOffset: {} brokerBusy: {}",
                     pullRequest, offset, brokerBusy);
            if (brokerBusy) {
                log.info("[NOTIFYME]the first time to pull message, but pull request offset larger than broker consume offset. pullRequest: {} NewOffset: {}",
                         pullRequest, offset);
            }

            pullRequest.setLockedFirst(true);
            pullRequest.setNextOffset(offset);
        }
    } else {
        // 稍后拉取
        this.executePullRequestLater(pullRequest, PULL_TIME_DELAY_MILLS_WHEN_EXCEPTION);
        log.info("pull message later because not locked in broker, {}", pullRequest);
        return;
    }
}
```

上面会判断获取但还未处理的消息个数、消息总大小、offset的跨度，任何一个值超过设定的大小就隔一段时间再拉取消息，从而达到流量控制的目的。此外**ProcessQueue**还可以辅助实现顺序消费的逻辑。

### DefaultMQPullConsumer

Pull方式是Client端循环的从Server端拉取消息，主动权在Client手里，自己拉取到一定量消息后，处理妥当了再接收。Pull方式的问题是循环拉取消息的时间间隔不好设定，间隔太短就处在一个“忙等”状态，浪费资源；每个Pull的时间间隔太长，Server端有消息到来时，有可能没有被及时处理。

案例:**org.apache.rocketmq.example.simple**

### Consumer的启动、关闭流程

Consumer分为Pull和Push两种方式，对于PullConsumer来说，使用者主动权很高，可以根据实际需要暂停、停止、启动消费过程。但需要注意的是offset的保存，要在程序的异常处理部分增加把offset写入磁盘方向的处理，记准了每个MessageQueue的offset，才能保证消息的准确性。

DefaultMQPushConsumer的退出，要调用shutdown（）函数，以便释放资源、保存offset等。

pushConsumer在启动的时候会做各种配置检查，然后连接NameServer获取topic信息，启动时如果遇到异常，比如无法连接nameServer，程序仍然可以正常启动。即便你填错了地址，但是不会收到消息。

如果需要在DefaultMQPushConsumer启动的时候及时暴露问题，该如何操作？

可以在Consumer.start()语句后调用:`Consumer.fetchSubscribeMessageQueue("TopicName")`，如果配置不准确会有异常抛出。

## 3.2 不同类型的生产者

不同场景可以针对不同的策略发送消息:

- 同步发送
- 异步发送
- 延迟发送
- 事务消息

### DefaultMQProducer

消息的发送有同步和异步的功能。

使用了`SendCallback`代表异步发送，这个实现代表了接收的方法。没有返回值。

没有使用该类的表示同步发送，该方法具有**SendResult**返回值

消息发送的状态:

- FLUSH_DISK_TIMEOUT : 表示没有在规定时间内完成刷盘(需要Broker的刷盘策略被设置成SYNC_FLUSH才会报这个错)

- FLUSH_SLAVE_TIMEOUT : 表示在主备方式下，并且Broker被设置成SYNC_MASTER方式，没有在设定时间内完成主从同步。

- SLAVE_NOT_AVAILABLE:这个状态产生的场景和FLUSH_SLAVE_TIMEOUT类似，表示在主备方式下，并且Broker被设置成SYNC_MASTER，但是没有找到被配置成SLAVE的Broker。

- SEND_OK:表示发送成功，发送成功的具体含义：

  - 比如消息是否已经被存储到磁盘？
  - 消息是否被同步到SLAVE上？
  - 消息是否被写入磁盘？需要结合所配置的刷盘策略来定。

  也可以简单理解为没有发生上面列出的三个问题的状态就是SEND_OK.

### 发送延时消息

RocketMQ支持发送延时消息，Broker收到这类消息后，延时一段时间再处理，使消息在规定的一段时间后生效。

使用方式是通过调用`setDelayTimeLevel(int level)`方法设置 延时时间。

目前支持的时间长度:[1s/5s/10s/30s/Im/2m/3m/4m/5m/6m/7m/8m/9m/1Om/20m/30m/1h/2h]

例如`setDelayTimeLevel(3)`表示延时10秒。

### 自定义消息发送规则[顺序消息]

一个Topic会有多个Message Queue，如果使用Producer的默认配置，这个producer会轮流向各个Message Queue发送消息。Consumer在消费消息的时候，会根据负载均衡的策略，消费被分配到的Message Queue，如果不经过特定的设置，某条消息发送到哪个Message Queue是未知的。

如果需要消息发送到指定的Message Queue里,如同把同一类型的消息发往相同的Message Queue中，如何指定？

通过实现`MessageQueueSelector`接口，确定需要发往哪个MessageQueue,返回被选中的MessageQueue.

顺序消息（FIFO 消息）是消息队列 RocketMQ 提供的一种严格按照顺序进行发布和消费的消息类型。 顺序消息指消息发布和消息消费都按顺序进行。

- **顺序发布**：对于指定的一个 Topic，客户端将按照一定的先后顺序发送消息。
- **顺序消费**：对于指定的一个 Topic，按照一定的先后顺序接收消息，即先发送的消息一定会先被客户端接收到。

#### 适用场景

性能要求不高，所有的消息严格按照 FIFO 原则进行消息发布和消费的场景。

### 事务消息

- 事务消息：消息队列 RocketMQ 提供类似 X/Open XA 的分布事务功能，通过消息队列 RocketMQ 事务消息能达到分布式事务的最终一致。
- 半消息：暂不能投递的消息，发送方已经将消息成功发送到了消息队列 RocketMQ 服务端，但是服务端未收到生产者对该消息的二次确认，此时该消息被标记成“暂不能投递”状态，处于该种状态下的消息即半消息。
- 消息回查：由于网络闪断、生产者应用重启等原因，导致某条事务消息的二次确认丢失，消息队列 RocketMQ 服务端通过扫描发现某条消息长期处于“半消息”时，需要主动向消息生产者询问该消息的最终状态（Commit 或是 Rollback），该过程即消息回查。

#### 适用场景

通过购物车进行下单的流程中，用户入口在购物车系统，交易下单入口在交易系统，两个系统之间的数据需要保持最终一致，这时可以通过事务消息进行处理。交易系统下单之后，发送一条交易下单的消息到消息队列 RocketMQ，购物车系统订阅消息队列 RocketMQ 的交易下单消息，做相应的业务处理，更新购物车数据。

![事物处理流程](http://docs-aliyun.cn-hangzhou.oss.aliyun-inc.com/assets/pic/43348/cn_zh/1557378341241/%E4%BA%8B%E5%8A%A1%E6%B6%88%E6%81%AF.PNG)

1. 发送方向消息队列 RocketMQ 服务端发送消息。
2. 服务端将消息持久化成功之后，向发送方 ACK 确认消息已经发送成功，此时消息为半消息。
3. 发送方开始执行本地事务逻辑。
4. 发送方根据本地事务执行结果向服务端提交二次确认（Commit 或是 Rollback），服务端收到 Commit 状态则将半消息标记为可投递，订阅方最终将收到该消息；服务端收到 Rollback 状态则删除半消息，订阅方将不会接受该消息。
5. 在断网或者是应用重启的特殊情况下，上述步骤 4 提交的二次确认最终未到达服务端，经过固定时间后服务端将对该消息发起消息回查。
6. 发送方收到消息回查后，需要检查对应消息的本地事务执行的最终结果。
7. 发送方根据检查得到的本地事务的最终状态再次提交二次确认，服务端仍按照步骤 4 对半消息进行操作。

**说明：**事务消息发送对应步骤 1、2、3、4，事务消息回查对应步骤 5、6、7。

## 3.3 如何存储队列位置信息

offset : 指某个Topic下的一条消息在某个Message Queue里的位置。

对于`DefaultMQPushConsumer`来说，默认是`CLOUSTERING`（集群模式），也就是同一个消费组里面多个消费者消费一部分消息，各自收到的内容不一样。这种情况下Broker端存储和控制Offset的值使用的是**`RemoteBrokerOffsetStore`**结构.

![1562651855634](D:\github\MyHome\文章\框架篇\023_rocketmq\assets\1562651855634.png)

在DefaultMQPushConsumer里的BROADCASTING(广播模式)，每个订阅了该topic消息的消费者都会收到该消息。互相没有干扰，RocketMQ使用的是`LocalFileOffsetStore`，把Offset存到本地。

**如何设置Consumer读取消息的初始位置？**

`DefaultMQPushConsumer`

 **setConsumeFromWhere(ConsumeFromWhere.CONSUME_FROM_FIRST_OFFSET);**

这个语句设置从最小的offset开始读取。

**某个时间点消费?**

 `setConsumeFromWhere(ConsumeFromWhere.CONSUME_FROM_TIMESTAMP);`

`consumer.setConsumeTimestamp("20181109221800");`

> 如果是在广播模式下，默认是从Broker里读取某个Topic对应的ConsumerGroup的offset。当读取不到Offset的时候，ConsumerFromWhere的设置才生效。大部分情况下这个设置在ConsumerGroup初次启动时有效，如果Consumer正常运行后被停止，然后再启动，会接着上次的Offset开始消费，ConsumerFromWhere的设置无效。

## 3.4 自定义日志输出

RocketMQ日志相关的代码在`org.apache.rocketmq.client.log.ClientLogger`中。从源码中可以看到所有配置选项。

如果想更改所选的配置选项可以通过:`-Drocketmq.Client.LogLevel`来设置，或者在程序启动时使用`System.setProperty("rocketmq.Client.LogLevel","WARN")`来设置

# 4. 分布式消息队列的协调者

## 4.1 NameServer的功能

NameServer是整个消息队列中的状态服务器，集群的各个组件通过它来了解全局的信息。同时，各个角色的机器都要定期向NameServer上报自己的状态，超时不上报的话，NameServer会认为某个机器不可用，其他组件会把这个机器从可用列表中移除。

> 其实就是相当于微服务中的注册中心。

### RouteInfoManager

集群的状态就保存在这五个变量中。

```java
// 这个结果的key是Topic的名称，存储了所有Topic的属性信息，value是个QueueData的队列，队列的长度等于这个Topic数据存储的Master Breker的个数，QueueData里存储着Broker的名称、读写Queue的数量、同步标识等。
private final HashMap<String/* topic */, List<QueueData>> topicQueueTable;
// 以BrokerName为索引，相同名称的Broker可能存在多台机器，一个Master和多个Slave，这个结构存储着一个BrokerName对应的属性信息，包括所属的Cluister名称，一个Master broker和多个Slave Broker 的地址信息
private final HashMap<String/* brokerName */, BrokerData> brokerAddrTable;
// 存储的是集群中的Cluster的信息，结果很简单，就是一个Cluster名称对应一个由BrokerName组成的集合。
private final HashMap<String/* clusterName */, Set<String/* brokerName */>> clusterAddrTable;
// key是BrokerAddr，对应着一台机器。BrokerLiveInfo存储的是broker的实时状态，包括上次更新的时间戳。NameServer会定期检查，过期的直接更新掉。
private final HashMap<String/* brokerAddr */, BrokerLiveInfo> brokerLiveTable;
// 过滤服务器，服务端过滤方式。一个Broker可以由一个或多个Filter Server。
private final HashMap<String/* brokerAddr */, List<String>/* Filter Server */> filterServerTable;
```

#### 状态维护逻辑

NameServer的主要逻辑在DefaultRequestProcessor类中的processRequest方法中。

- 根据上报消息里的请求码做相应的处理，更新存储的对应信息。

连接断开的时间也会触发状态更新，具体逻辑在`org.apache.rocketmq.namesrv.routeinfo.BrokerHousekeepingService`类中

```java
@Override
public void onChannelConnect(String remoteAddr, Channel channel) {
}

@Override
public void onChannelClose(String remoteAddr, Channel channel) {
    this.namesrvController.getRouteInfoManager().onChannelDestroy(remoteAddr, channel);
}

@Override
public void onChannelException(String remoteAddr, Channel channel) {
    this.namesrvController.getRouteInfoManager().onChannelDestroy(remoteAddr, channel);
}

@Override
public void onChannelIdle(String remoteAddr, Channel channel) {
    this.namesrvController.getRouteInfoManager().onChannelDestroy(remoteAddr, channel);
}
```

当NameServer和broker长连接断掉以后，onChannelDestroy会被触发。

NameServer还有定时检查时间戳的逻辑。

在NamesrvController启动的时候initialize方法会执行一个

```java
this.scheduledExecutorService.scheduleAtFixedRate(new Runnable() {
    @Override
    public void run() {
        NamesrvController.this.routeInfoManager.scanNotActiveBroker();
    }
}, 5, 10, TimeUnit.SECONDS);
```

**每10秒检查一次,时间戳超过两分钟则认为broker失效。**

## 4.2各个角色间的交互流程

**org.apache.rocketmq.tools.command.topic.UpdateTopicSubCommand**

创建topic的命令

```java
OptionGroup optionGroup = new OptionGroup(); 
Option opt = new Option("b", "brokerAddr", true, "create topic to which broker");
opt = new Option("c", "clusterName", true, "create topic to which cluster");
opt = new Option("t", "topic", true, "topic name");
opt = new Option("r", "readQueueNums", true, "set read queue nums");
opt = new Option("w", "writeQueueNums", true, "set write queue nums");
opt = new Option("p", "perm", true, "set topic's permission(2|4|6), intro[2:W 4:R; 6:RW]");
opt = new Option("o", "order", true, "set topic's order(true|false)");
opt = new Option("u", "unit", true, "is unit topic (true|false)");
opt = new Option("s", "hasUnitSub", true, "has unit sub (true|false)"); 
```

b和c只会有一个起作用，分别代表从哪个Broker中创建topic的MessageQueue。

创建和修改Topic

```
CreateTopicRequestHeader requestHeader = new CreateTopicRequestHeader();
requestHeader.setTopic(topicConfig.getTopicName());
requestHeader.setDefaultTopic(defaultTopic);
requestHeader.setReadQueueNums(topicConfig.getReadQueueNums());
requestHeader.setWriteQueueNums(topicConfig.getWriteQueueNums());
requestHeader.setPerm(topicConfig.getPerm());
requestHeader.setTopicFilterType(topicConfig.getTopicFilterType().name());
requestHeader.setTopicSysFlag(topicConfig.getTopicSysFlag());
requestHeader.setOrder(topicConfig.isOrder()); 
RemotingCommand request = RemotingCommand.createRequestCommand(RequestCode.UPDATE_AND_CREATE_TOPIC, requestHeader);
```

### 为什么不用Zookeeper?

RocketMQ架构设计决定了它不需要进行Master选举，用不到这些复杂的功能，只需要轻量级的元数据服务器就足够了。

另外稳定性要求高，轻量，减少维护成本。

## 4.3 底层通信机制

### Remoting模块

![1562656065378](D:\github\MyHome\文章\框架篇\023_rocketmq\assets\1562656065378.png)

RemotingService为最上层接口:

- start()
- shutdown()
- registerRPCHook()

RemotingServer和RemotingClient在上面的基础上做了增强

![RemotingServer](D:\github\MyHome\文章\框架篇\023_rocketmq\assets\1562656196420.png)

![RemoteClient](D:\github\MyHome\文章\框架篇\023_rocketmq\assets\1562656223704.png)

RemotingServer是在NamesrvController中被引用。

而NamesrvController则是被DefaultRequestProcessor引用。

NettyRemotingAbstract 则是命令的执行器

# 5 消息队列的核心机制

## 消息的存储和发送

高性能的磁盘顺序写的速度时600M/s，超过了一般网卡的传输速度。

但是磁盘的随机写的速度只有大概100KB/s。

通过mmap的方式，省去用户态的内存复制，提高速度。【零拷贝】

## 消息的存储结构

RocketMQ消息的存储是由ConsumeQueue和CommitLog配合完成的，消息真正的屋里存储文件是CommitLog，ConsumeQueue是消息的逻辑队列，类似数据库的索引文件，存储的是指向物理存储的地址。

每个topic下的每个message Queue都有一个对应的Consume Queue文件。

文件地址在${storeRoot}\consumequeue\${topicName}\${queueId}\${fileName}

![1562658669110](D:\github\MyHome\文章\框架篇\023_rocketmq\assets\1562658669110.png)

## 高可用机制

在Broker中参数BrokerId为0代表master，大于0的代表slave。

## 同步刷盘和异步刷盘

rocketmq存储在磁盘上，这样既能保证断电后恢复，又可以让存储的消息超出内存的限制。

rokcetMQ为了提高性能,会尽可能的保证磁盘的顺序写。

所以消息通过producer写入RocketMQ的时候，有两种写磁盘的方式：

- 异步刷盘模式

在返回写成功状态时，消息可能只是被写入内存的PAGECACHE，写操作的返回快，吞吐量大；

当内存里的消息量积累到一定程度时，统一触发写磁盘的操作，快速写入。

- 同步刷盘模式

在返回写成功状态时，消息已经被写入磁盘。具体流程是，消息写入内存的PAGECACHE后，立刻通知刷盘线程刷盘，然后等待刷盘完成，刷盘线程执行完后唤醒等待的线程，返回消息写入成功的状态。

> 同步刷盘还是异步刷盘是通过Broker配置文件里的flushDiskType参数设置的，这个参数被配置成SYNC_FLUSH、ASYNC_FLUSH中的一个。

## 同步复制和异步复制

**异步复制:**

系统拥有较低的延迟和较高的吞吐量，但是如果master出了故障，有些数据没有被写入Slave，有可能会造成丢失；

同步复制:

如果Master出故障，Slave上有全部的备份数据，容易恢复，但是同步复制会增大数据写入延迟，降低吞吐量。

> 同步复制和异步复制是通过Broker配置文件里的BrokerRule参数进行设置的，这个参数可以设置成ASYNC_MASTER、SYNC_MASTER、SLAVE三个值其中的一个。

通常会设置成异步复制。性能好，数据不丢。

# 6. 可靠性优先的使用场景



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

## 故障消息的影响

1. Broker正常关闭，启动

数据不会丢失，master挂了，会有slave顶上。生产消费不受影响

1. broker异常Crash，然后启动
2. OS Crash 重启
3. 机器断电，但能马上恢复
4. 磁盘损坏
5. CPU、主板、内存等关键设备损坏。

第2、3、4属于软件故障，内存的数据可能会丢失，这个也根据刷盘策略的不同，造成的影响不同，如果是同步刷盘策略可以达到和第一种情况相同。如果是异步刷盘存在数据丢失的情况。

第5、6点属于硬件故障，挂的那台磁盘丢失，如果是M-S配置，消息会复制到Slave不会丢失，但如果是异步复制的话，两次Sync的消息会丢失

总的来说最可靠稳定的设置方式:

1. 多Master，每个Master带有Slave
2. 主从之间设置为SYNC_MASTER
3. Producer用同步方式写;
4. 刷盘策略设置冲SYNC_FLUSH.

可以消除单点依赖，即使某台机器出现极端故障也不会丢失消息。

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



# 7. 吞吐量优先的场景

## 提高消费者的处理能力

### 一 . 提高消费者并行度。

##### 增加消费者

其实就是增加同一个组的内的消费者，把消息均衡处理掉。

**需要注意的是: 消费者数量不要超过topic下Read Queue数量，超过的Consumer实例接收不到消息。**

##### 提高处理线程数

其次就是提高单个Consumer实例中的并行处理线程数，可以在同一个Consumer内增加并行度来提高吞吐量。【设置方式是修改consumer.setConsumeThreadMin和consumer.setConsumeThreadMax】

### 二. 以批量的方式进行消费

某些业务的场景下，多条消息同时处理的时间会大大小于逐个处理都是时间总和，比如批量修改10条数据比一次次修改10条数据会快。

实现方式是通过设置consumer.setConsumeMessageBatchMaxSize这个参数，默认是1

### 三. 检测延时情况，跳过非重要消息

由于某种原因，消息发生严重的堆积，短时间内无法消除堆积，这个时候可以选择丢弃不重要的消息，使consumer尽快追上producer的进度。

![1563939815559](D:\github\MyHome\文章\框架篇\023_rocketmq\RocketMq实战与原理解析.assets\1563939815559.png)

当某个队列的消息堆积达到9W以上，就直接丢弃，以便追上发送消息的进度。



## Consumer的负载均衡

### DefaultMQPushConsumer的负载均衡

默认的结果是Topic的MessageQueue数量以及ConsumerGroup的Consumer的数量有关，负载均衡的粒度直到MessageQueue,把topic下的所有Message Queue分配到不同的Consuer中，所以Message Queue和Consumer的数量关系，或者整除关系影响负载均衡的结果。

例如MQ的数设置为3，ConsumerGroup的Consumer为2，那么其中一个消费者需要消费3/2的消息，另一个处理3/1的消息；当consumer数量为4的时候，有一个Consumer无法收到消息，其他3个各处理三分之一的消息。

> 所以Message Queue的数量设置不宜过小。通常设置为16

### DefaultMQPullConsumer的负载均衡

/// 暂无







## 提高producer的发送速度

### 1. 利用oneway单向消息发送

发送一条消息要经过三部:

1. 客户端发送请求到服务器。
2. 服务器处理该请求
3. 服务器向客户端返回应答。

某些场景可以通过Oneway方式发送，也就是不需要第三步。即将数据写入客户端的Socket缓冲区就返回，不等待对方返回结果，用这种方式发消息的耗时可以缩短到微妙级。

### 2. 增加producer的并发量



## 系统性能调优的一般流程

### top查看CPU和内存使用率



### 使用sar命令查看网卡使用情况



### 使用iostat查看磁盘使用情况



### 上面三者还没达到极限

可能是锁的机制有bug，造成线程阻塞。

通过java 的profiling工具来找出程序的具体问题，比如jvisualvm、jstack、perfJ等。





