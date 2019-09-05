# 运维

[搜狐开源的RocketMQ运维工具](https://github.com/sohutv/mqcloud)

[DDMQ 开源的封装](https://github.com/didi/DDMQ)

## 服务器端口 

NameServer: 9876

broker 服务端监听端口 : 10911

Master监听端口,从服务器连接该端口,默认为 : 10912

VIP通道端口 : 10909







# 集群搭建

**2m-2s 异步复制**

每个master配置一个slave，有多对Master-slave,HA采用异步复制方式,主备有短暂消息延时，毫秒级

优点 : 即使磁盘损坏或者主宕机，丢失的消息非常少（因为是异步复制），且实时的消息不会受影响，应为master宕机后，消费者仍然可以从Slave消费，此过程透明。不需要人工干预。性能同多Master模式几乎一模一样。











[下载源码](https://github.com/apache/rocketmq)

编译源码

```shell
  > unzip rocketmq-all-4.4.0-source-release.zip
  > cd rocketmq-all-4.4.0/
  > mvn -Prelease-all -DskipTests clean install -U
  > cd distribution/target/apache-rocketmq
```

## 主从搭建

>  配置文件最好是创建在`rocketmq-rocketmq-all-4.5.1/distribution/target/rocketmq-4.5.1/rocketmq-4.5.1/conf/default`下

[利用Dledger搭建主备方式](https://github.com/apache/rocketmq/blob/master/docs/cn/dledger/deploy_guide.md)

非常简单

**主配置文件**

```properties
brokerClusterName=DefaultCluster
namesrvAddr=192.168.0.24:9876;192.168.0.25:9876
brokerName=broker-a
brokerId=0
#deleteWhen=04
# fileReservedTime=48
brokerRole=SYNC_MASTER
flushDiskType=ASYNC_FLUSH
listenPort=10911
#在发送消息时，自动创建服务器不存在的topic，默认创建的队列数
defaultTopicQueueNums=4
#是否允许 Broker 自动创建Topic，建议线下开启，线上关闭
autoCreateTopicEnable=true
#是否允许 Broker 自动创建订阅组，建议线下开启，线上关闭
autoCreateSubscriptionGroup=true
#删除文件时间点，默认凌晨 4点
deleteWhen=04
#文件保留时间，默认 48 小时
fileReservedTime=120
#commitLog每个文件的大小默认1G
mapedFileSizeCommitLog=1073741824
#ConsumeQueue每个文件默认存30W条，根据业务情况调整
mapedFileSizeConsumeQueue=300000
#destroyMapedFileIntervalForcibly=120000
#redeleteHangedFileInterval=120000
#检测物理文件磁盘空间
diskMaxUsedSpaceRatio=88
#存储路径
storePathRootDir=/sky/rocketmq/store/broker-a
#commitLog 存储路径
storePathCommitLog=/sky/rocketmq/store/broker-a/commitlog
#消费队列存储路径存储路径
storePathConsumeQueue=/sky/rocketmq/store/broker-a/consumequeue
#消息索引存储路径
storePathIndex=/sky/rocketmq/store/broker-a/index
#checkpoint 文件存储路径
storeCheckpoint=/sky/rocketmq/store/checkpoint
#abort 文件存储路径
abortFile=/sky/rocketmq/store/abort
#限制的消息大小
maxMessageSize=65536
#flushCommitLogLeastPages=4
#flushConsumeQueueLeastPages=2
#flushCommitLogThoroughInterval=10000
#flushConsumeQueueThoroughInterval=60000
#Broker 的角色
#- ASYNC_MASTER 异步复制Master
#- SYNC_MASTER 同步双写Master
#- SLAVE
#brokerRole=ASYNC_MASTER
#刷盘方式
#- ASYNC_FLUSH 异步刷盘
#- SYNC_FLUSH 同步刷盘
#flushDiskType=ASYNC_FLUSH
#checkTransactionMessageEnable=false
#发消息线程池数量
#sendMessageThreadPoolNums=128
#拉消息线程池数量
#pullMessageThreadPoolNums=128

```

**从配置文件**

```properties
#所属集群名字
brokerClusterName=rocketmq-cluster
#broker名字，名字可重复,为了管理,每个master起一个名字,他的slave同他,eg:Amaster叫broker-a,他的slave也叫broker-a
brokerName=broker-b
#0 表示 Master，>0 表示 Slave
brokerId=1
#nameServer地址，分号分割
namesrvAddr=192.168.0.24:9876;192.168.0.25:9876
#在发送消息时，自动创建服务器不存在的topic，默认创建的队列数
defaultTopicQueueNums=4
#是否允许 Broker 自动创建Topic，建议线下开启，线上关闭
autoCreateTopicEnable=true
#是否允许 Broker 自动创建订阅组，建议线下开启，线上关闭
autoCreateSubscriptionGroup=true
#Broker 对外服务的监听端口,
listenPort=10920
#删除文件时间点，默认凌晨 4点
deleteWhen=04
#文件保留时间，默认 48 小时
fileReservedTime=120
#commitLog每个文件的大小默认1G
mapedFileSizeCommitLog=1073741824
#ConsumeQueue每个文件默认存30W条，根据业务情况调整
mapedFileSizeConsumeQueue=300000
#destroyMapedFileIntervalForcibly=120000
#redeleteHangedFileInterval=120000
#检测物理文件磁盘空间
diskMaxUsedSpaceRatio=88
#存储路径
storePathRootDir=/sky/rocketmq/store/broker-b-s
#commitLog 存储路径
storePathCommitLog=/sky/rocketmq/store/broker-b-s/commitlog
#消费队列存储路径存储路径
storePathConsumeQueue=/sky/rocketmq/store/broker-b-s/consumequeue
#消息索引存储路径
storePathIndex=/sky/rocketmq/store/broker-b-s/index
#checkpoint 文件存储路径
storeCheckpoint=/sky/rocketmq/store/checkpoint
#abort 文件存储路径
abortFile=/sky/rocketmq/store/abort
#限制的消息大小
maxMessageSize=65536
#flushCommitLogLeastPages=4
#flushConsumeQueueLeastPages=2
#flushCommitLogThoroughInterval=10000
#flushConsumeQueueThoroughInterval=60000
#Broker 的角色
#- ASYNC_MASTER 异步复制Master
#- SYNC_MASTER 同步双写Master
#- SLAVE
brokerRole=SLAVE
#刷盘方式
#- ASYNC_FLUSH 异步刷盘
#- SYNC_FLUSH 同步刷盘
flushDiskType=ASYNC_FLUSH
#checkTransactionMessageEnable=false
#发消息线程池数量
#sendMessageThreadPoolNums=128
#拉消息线程池数量
#pullMessageThreadPoolNums=128
 
```

创建指定的文件夹

```shell
#节点1执行:
 mkdir -p /sky/rocketmq/store/broker-a /sky/rocketmq/store/broker-a/nsumequeue /sky/rocketmq/store/broker-a/commitlog /sky/rocketmq/store/broker-a/index /sky/rocketmq/logs /sky/rocketmq/store/broker-b-s /sky/rocketmq/store/broker-b-s/nsumequeue /sky/rocketmq/store/broker-b-s/commitlog /sky/rocketmq/store/broker-b-s/index
 #节点2执行:
 mkdir -p /sky/rocketmq/store/broker-a-s /sky/rocketmq/store/broker-a-s/nsumequeue /sky/rocketmq/store/broker-a-s/commitlog /sky/rocketmq/store/broker-a-s/index /sky/rocketmq/logs /sky/rocketmq/store/broker-b /sky/rocketmq/store/broker-b/nsumequeue /sky/rocketmq/store/broker-b/commitlog /sky/rocketmq/store/broker-b/index
```



**注意点:**

Broker默认的内存是8G，如果服务器资源不够的情况下可以通过`bin/runbroker.sh` 进行调整

# 启动名称服务器

```shell
  > cd rocketmq-rocketmq-all-4.5.1/distribution/target/rocketmq-4.5.1/rocketmq-4.5.1
  > nohup sh bin/mqnamesrv >/sky/rocketmq/logs/mqnamesrv.log 2>&1 &
  > tail -f /sky/rocketmq/logs/mqnamesrv.log
  The Name Server boot success...
```

# 启动经纪人

```shell
  > nohup sh bin/mqbroker -c  conf/default/broker-a.properties &
  > tail -f ~/logs/rocketmqlogs/broker.log 
  The broker[%s, 172.30.30.233:10911] boot success...
```

> nohup sh bin/mqbroker -c  conf/default/broker-a.properties > /sky/rocketmq/logs/broker-a.log 2>&1 &

# 关机服务器

```
> sh bin/mqshutdown broker
The mqbroker(36695) is running...
Send shutdown request to mqbroker(36695) OK

> sh bin/mqshutdown namesrv
The mqnamesrv(36664) is running...
Send shutdown request to mqnamesrv(36664) OK
```