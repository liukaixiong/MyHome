# WebSocket 源码记录

订阅消息拦截器:

- WebSocketAnnotationMethodMessageHandler[prefixes=[/app/]]
  - 只处理带有广播路径的消息
- SimpleBrokerMessageHandler [DefaultSubscriptionRegistry[cache[0 destination(s)], registry[1 sessions]]]
  - 处理请求类型，连接、消息、断开 ，最终消息的发送
- UserDestinationMessageHandler[DefaultUserDestinationResolver[prefix=/user/]]
  - 类似第一种，不过会获取该用户的消息

- SubProtocolWebSocketHandler[StompSubProtocolHandler[v10.stomp, v11.stomp, v12.stomp]]

SimpUserRegistry : 所有用户的sessionId存储地方

- DefaultSimpUserRegistry:默认的用户容器
  - 监听了用户的连接、下线、以及订阅
- 

AbstractBrokerMessageHandler  : 多线程流程转发控制器



## 架构描述

### Broker

所有消息的中转器

#### AbstractBrokerMessageHandler

定义了抽象的消息处理器

![1544435729730](D:\github\MyHome\文章\框架篇\010_SpringCloud\assets\1544435729730.png)



##### MessageHandler 

真正的消息处理器，非常关键，所有消息都会经过这个处理器到达客户端。

![1544688741060](D:\github\MyHome\文章\框架篇\010_SpringCloud\assets\1544688741060.png)

##### UserDestinationMessageHandler

点对点消息发送的处理程序，将路径为`/user`的对象解析成点对点参数

例如 : /user/userid-5/topic/xxx 

解析成 `/user/topic/xxx` 只是为了找到订阅了该路由的所有用户

解析成 /topic/xxx-userid-5 最终这条消息的发送地址，为了能够让SimpleBrokerMessageHandler接收到。

##### SimpleBrokerMessageHandler

最终的消息发送执行类。拿上个类的流程举例

1. 当/topic/xxx-userid-5 接收到之后会判断该消息类型，如果是订阅则进行注册。如果是Message则进行消息发送。通常第一次连接都是订阅，所以会把/topic/xxx-userid-5先注册。然后下次发消息的时候，就能够找到了 

##### ApplicationEventPublisherAware 

用来定义监听该经纪人是否可用

### 实现类介绍

![1544435982821](D:\github\MyHome\文章\框架篇\010_SpringCloud\assets\1544435982821.png)

#### SimpleBrokerMessageHandler

默认的经纪人消息拦截器，主要是是实现父类了`handleMessageInternal`方法，而这个方法主要是用来处理MESSAGE、CONNECT、DISCONNECT、SUBSCRIBE、UNSUBSCRIBE等各个事件触发的拦截器，同样也是消息发送的必经之路。

#### StompBrokerRelayMessageHandler

基于Stomp协议打造的经纪人实现类，他的被调用的时机是AbstractWebSocketMessageBrokerConfigurer中的configureMessageBroker方法，需要手动通过`config.enableStompBrokerRelay()`触发开启。

该类就是将经纪人的功能全部走stomp协议通过消息队列去转发。这个时候实现集群就比较方便了。

这个类在初始化的时候有一个属性`setUserRegistryBroadcast`，这里就是用户同步的路由名称。

这个属性一旦被设定就会触发`UserRegistryMessageHandler`的初始化，这个类就专门针对UserRegistryBroadcast的路由来订阅该消息。

**订阅完了消息之后如何被触发呢?**

UserRegistryMessageHandler的onApplicationEvent监听方法。里面会开启一个定时调度线程去做这件事.

它会在间隔时间段(默认10秒)把该节点上面的用户通过getBroadcastDestination方法，也就是把用户当前情况通过路由发送出去。其他节点接收到这个路由再去覆盖当前节点上的本地用户表来达到同步的效果。



### 订阅管道(Channel)

MessageChannel

![1544690345005](D:\github\MyHome\文章\框架篇\010_SpringCloud\assets\1544690345005.png)



单单从方法看我们来猜猜每个接口的作用

MessageChannel : 消息发送的规范

SubscibableChannel : 订阅的管道规范

PollablerChannel : 消息读取的规范。消息回复会触发的方法

具体的实现类作用:

AbstractMessageChannel : 管理拦截器的规范，拥有消息发送的功能。目的就是为了在消息发送时候的能够做一些操作

ChannelIntercepetorChain : 整整的管道拦截器链路，从方法中可以看到主要就是针对消息的发送之前和之后做的一些处理。通常实现这个类就能够对消息前后做处理。

AbstractSubscribableChannel: 

 	1. 消息的订阅和取消订阅
 	2. 获取订阅的消息拦截器

ExecutorSubscribableChannel : 

 	1. 具体的执行消息拦截器的实现
 	2. 发送的方法

SendTask: 

 	1. 异步处理消息拦截器

从上面可以看到每个拦截器其实都拥有消息发送的功能，针对每条消息都能够做完处理之后执行特定的逻辑。

#### AbstractMessageChannel

![1544436914552](D:\github\MyHome\文章\框架篇\010_SpringCloud\assets\1544436914552.png)

MessageChannel : 消息的发送定义

InterceptableChannel : 拦截链`ChannelInterceptor`的对象封装

BeanNameAware : bean的名称设置

**总的来说这个类就是负责实现消息的发送以及消息发送过程中的前后拦截链处理**

具体体现在send方法里面

```java
ChannelInterceptorChain chain = new ChannelInterceptorChain();
boolean sent = false;
try {
    message = chain.applyPreSend(message, this);
    if (message == null) {
        return false;
    }
    sent = sendInternal(message, timeout);
    chain.applyPostSend(message, this, sent);
    chain.triggerAfterSendCompletion(message, this, sent, null);
    return sent;
}
```

1. 发送消息的前后都会拓展的方法

```java
public boolean sendInternal(Message<?> message, long timeout) {
    for (MessageHandler handler : getSubscribers()) {
        SendTask sendTask = new SendTask(message, handler);
        if (this.executor == null) {
            sendTask.run();
        }
        else {
            this.executor.execute(sendTask);
        }
    }
    return true;
}
```

这里执行消息发送的拦截器是通过异步去做的。

#### AbstractSubscribableChannel

拥有了父类的发送接口功能之外，还封装了消息的订阅以及取消订阅。通过一个Set容器来封装MessageHandler对象

而这个对象则是每个消息都要处理的对象，非常关键

### 处理流程

- ExecutorSubscribableChannel[clientInboundChannel]
  - WebSocketAnnotationMethodMessageHandler[prefixes=[/ws/]] - 扫描注解方法来处理
  - SimpleBrokerMessageHandler [DefaultSubscriptionRegistry[cache[1 destination(s)], registry[1 sessions]]] - 消息处理
  - UserDestinationMessageHandler[DefaultUserDestinationResolver[prefix=/user/]] - 点对点消息处理

