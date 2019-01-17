zuul 版本 : 1.3.0.RELEASE

# 请求原理图

在高级视图中，Zuul 2.0是运行预过滤器（入站过滤器）的Netty服务器，然后使用Netty客户端代理请求，然后在运行后过滤器（出站过滤器）后返回响应。

![img](https://camo.githubusercontent.com/263a4e85f8b9a9e76eb0b61c4cff2b142f9344ec/68747470733a2f2f692e696d6775722e636f6d2f6b5453543948562e706e67)

# 1. 初始化流程

![1540349810492](D:\github\MyHome\文章\框架篇\010_SpringCloud\zuul\assets\1540349810492.png)

## 相关类介绍

**ZuulServlet** : 请求的入口，所有请求都会经过该类。

**ZuulRunner** : zuul运行的执行类，该类在ZuulServlet的init方法中初始化，该类负责将请求接收并且转发到对应filter中去

**FilterProcessor** : zuul的Filter的具体执行类，它是每个filter的执行入口

**FilterRegistry** : 所有Filter存储的容器类，这个类中存放着所有Filter。

**FilterLoader** : 持有FilterRegistry类，并且负责加载，并且将所有Filter进行划分..

## 执行顺序

![img](http://www.ityouknow.com/assets/images/2018/springcloud/zuul-core.png)

# 2. 过滤器

![1540349611562](D:\github\MyHome\文章\框架篇\010_SpringCloud\zuul\assets\1540349611562.png)

### PreDecorationFilter

为zuulFilter确定路由的位置，转发的时候需要确定这个url是否能够路由到其他服务中去，而这里会从注册中心去匹配ServiceId是否包含在里面，为转发的时候做前置匹配。

### RibbonRoutingFilter

负载均衡路由器，Route级别。它主要根据ServiceId去eureka去确定一个能够访问的ip，并且构建一个HTTP请求，转发到对应的服务。

### SimpleHostRoutingFilter

和上面的路由器的功能差不多，只不过没有负载均衡的功能。也是请求转发的。

### DebugFilter

是否开启Debug模式，默认开启了的话，会将链路的日志全部输出。

### FormBodyWrapperFilter

请求入参的编码过滤器

### SendResponseFilter

返回结果拦截器

### ZuulFilter

属于zuul过滤器的标识类。

### ZuulProxyAutoConfiguration 

 SpringCloud中的关于Zuul加载的配置类，负责加载SpringCloud中各个组件的配置

### ZuulServerAutoConfiguration

SpringCloud中负责加载Zuul服务相关的配置类，包含了请求开始、解析、包装返回等等一系列的filter。



# 请求转发

## 流程

1. 所有请求会被ZuulServlet全部拦截
2. ZuulServlet会把所有请求交给ZuulRunner去处理
3. 最终会到FilterProcessor中去处理各个流程的过滤器
   1. PreDecorationFilter 会将URL进行解析，确定ServiceId以及一系列的转发参数
   2. 当进入到RibbonRoutingFilter中时，会构建一个HttpClientRibbonCommandFactory对象，这个对象会持有路由地址对象，并构建成一个最终能够访问的HTTP地址，完成转发



## 关键代码

RibbonRoutingFilter : 

```java
public Object run() {
    RequestContext context = RequestContext.getCurrentContext();
    this.helper.addIgnoredHeaders();
    try {
        // 构建一个参数请求对象
        RibbonCommandContext commandContext = buildCommandContext(context);
        // 路由转发
        ClientHttpResponse response = forward(commandContext);
        setResponse(response);
        return response;
    }
    catch (ZuulException ex) {
        throw new ZuulRuntimeException(ex);
    }
    catch (Exception ex) {
        throw new ZuulRuntimeException(ex);
    }
}

protected ClientHttpResponse forward(RibbonCommandContext context) throws Exception {
		Map<String, Object> info = this.helper.debug(context.getMethod(),
				context.getUri(), context.getHeaders(), context.getParams(),
				context.getRequestEntity());
		// 创建一个HttpClientRibbonCommandFactory对象
		RibbonCommand command = this.ribbonCommandFactory.create(context);
		try {
			ClientHttpResponse response = command.execute();
			this.helper.appendDebug(info, response.getRawStatusCode(), response.getHeaders());
			return response;
		}
		catch (HystrixRuntimeException ex) {
			return handleException(info, ex);
		}

	}
```

HttpClientRibbonCommandFactory

```java
@Override
public HttpClientRibbonCommand create(final RibbonCommandContext context) {
    // 获取一个快速失败返回的方法
    ZuulFallbackProvider zuulFallbackProvider = getFallbackProvider(context.getServiceId());
    final String serviceId = context.getServiceId();
    // 构建一个负载均衡存储对象
    final RibbonLoadBalancingHttpClient client = this.clientFactory.getClient(
        serviceId, RibbonLoadBalancingHttpClient.class);
    // 根据ServiceId获取Eureka注册服务地址
    client.setLoadBalancer(this.clientFactory.getLoadBalancer(serviceId));

    return new HttpClientRibbonCommand(serviceId, client, context, zuulProperties, zuulFallbackProvider,
                                       clientFactory.getClientConfig(serviceId));
}

```



**上面的关键执行步骤涉及的类已经列出，下面列出关键的功能。**



# cloud中的核心功能

## 1. 负载均衡

**命令上下文处理器** : RibbonCommandContext

这个类负责将请求的数据进行解析，并构建成一个RibbonCommandContext对象，这个对象就能描述出本次请求。

```java
RibbonCommandContext commandContext = buildCommandContext(context);
```

**具体的命令执行器** : RibbonCommand

负责从`RibbonCommandFactory`工厂中获取一个指定的处理对象，默认实现是`HttpClientRibbonCommandFactory`，这个是在初始化时通过`RibbonCommandFactoryConfiguration`配置类来创建的。

这个工厂负责创建出拥有发送请求，并且能够拿到服务中心的有效注册地址，并且进行拼装组成最终的请求URL。

**远程客户端工厂** : SpringClientFactory

Spring的客户端工厂，主要是负责从容器中获取对应的执行对象，比如负载均衡、客户端配置等待

**负载均衡接口定义** : ILoadBalancer 

该接口主要是负责定时抓去Eureka注册中心上注册的地址。

**具体的远程地址获取对象**: `ZoneAwareLoadBalancer`

构建了一个单独线程用来获取Eureka上面的服务地址信息。

由**RibbonClientConfiguration**进行初始化创建.

接下来看一下它是如何从注册中心上面获取服务地址的。

1. 通过RibbonClientConfiguration实例化ZoneAwareLoadBalancer类
2. 调用父类DynamicServerListLoadBalancer的restOfInit方法
3. enableAndInitLearnNewServersFeature方法开启一个线程每隔一段时间去获取服务器地址

```java
// 开启一个线程定时去刷新eureka中注册的配置
protected final ServerListUpdater.UpdateAction updateAction = new ServerListUpdater.UpdateAction() {
    @Override
    public void doUpdate() {
        updateListOfServers();
    }
};
// 具体开启线程的方法
public void enableAndInitLearnNewServersFeature() {
    LOGGER.info("Using serverListUpdater {}", serverListUpdater.getClass().getSimpleName());
    serverListUpdater.start(updateAction);
}
// 具体刷新容器的方法
@VisibleForTesting
public void updateListOfServers() {
    List<T> servers = new ArrayList<T>();
    if (serverListImpl != null) {
        // 获取服务器地址信息
        servers = serverListImpl.getUpdatedListOfServers();
        LOGGER.debug("List of Servers for {} obtained from Discovery client: {}",
                     getIdentifier(), servers);

        if (filter != null) {
            servers = filter.getFilteredListOfServers(servers);
            LOGGER.debug("Filtered List of Servers for {} obtained from Discovery client: {}",
                         getIdentifier(), servers);
        }
    }
    updateAllServerList(servers);
}
```

这里的链路栈

![1540456825708](D:\github\MyHome\文章\框架篇\010_SpringCloud\zuul\assets\1540456825708.png)

最终会拿到一个CloudEurekaClient代理对象，这个对象里面包含了远程服务的信息，然后通过ServiceId去拿到这个服务的注册地址列表

```java
 List<InstanceInfo> listOfInstanceInfo = eurekaClient.getInstancesByVipAddress(vipAddress, isSecure, targetRegion);
```

结果展示: 

![1540457274842](D:\github\MyHome\文章\框架篇\010_SpringCloud\zuul\assets\1540457274842.png)

我这里有个集群，所以集合大小是2个。然后默认从中选取一个作为最终的访问服务对象

**如果有多个服务如何选举最终的一个?**

![1540458354311](D:\github\MyHome\文章\框架篇\010_SpringCloud\zuul\assets\1540458354311.png)

