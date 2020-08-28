# Zuul网关

Zuul 是在云平台上提供动态路由,监控,弹性,安全等边缘服务的框架。Zuul 相当于是设备和 Netflix 流应用的 Web 网站后端所有请求的前门。当其它门派来找大哥办事的时候一定要先经过zuul,看下有没有带刀子什么的给拦截回去，或者是需要找那个小弟的直接给带过去。

 

![zuul请求分配图](https://images2017.cnblogs.com/blog/27612/201708/27612-20170805105047319-1173615667.png)





### 具体的使用场景:

1. 权限认证
2. token合法性校验
3. 灰度验证时部分流量的引导
4. 过滤器

### 网关设计要素

1. 性能 : API高可用、负载均衡、容错机制
2. 安全 : 权限身份认证、脱敏、流量清洗、后端签名（保证全链路可信调用）、黑名单（非法调用的限制）
3. 日志 : 日志记录(spainid,traceid) 一旦涉及分布式，全链路追踪必不可少
4. 缓存 : 数据缓存。
5. 监控 : 记录请求响应数据，API耗时分析，性能监控
6. 限流 : 流量控制，错峰流控（目前有漏桶算法、令牌算法也可以定制限流规则）
7. 灰度 : 线上灰度部署、可以减小风险。
8. 路由 : 动态路由规则
9. 静态 : 代理



## 如何工作?

### 简单使用

1、添加依赖

```
<dependency>
	<groupId>org.springframework.cloud</groupId>
	<artifactId>spring-cloud-starter-zuul</artifactId>
</dependency>
```

引入`spring-cloud-starter-zuul`包

2、配置文件

```
spring.application.name=gateway-service-zuul
server.port=8888

#这里的配置表示，访问/it/** 直接重定向到http://www.ityouknow.com/**
zuul.routes.baidu.path=/it/**
zuul.routes.baidu.url=http://www.ityouknow.com/
```

3、启动类

```
@SpringBootApplication
@EnableZuulProxy
public class GatewayServiceZuulApplication {

	public static void main(String[] args) {
		SpringApplication.run(GatewayServiceZuulApplication.class, args);
	}
}
```

启动类添加`@EnableZuulProxy`，支持网关路由。

史上最简单的zuul案例就配置完了

## Zuul的核心

Filter是Zuul的核心，用来实现对外服务的控制。Filter的生命周期有4个，分别是“PRE”、“ROUTING”、“POST”、“ERROR”，整个生命周期可以用下图来表示。

![img](http://www.ityouknow.com/assets/images/2018/springcloud/zuul-core.png)

Zuul大部分功能都是通过过滤器来实现的，这些过滤器类型对应于请求的典型生命周期。

- **PRE：** 这种过滤器在请求被路由之前调用。我们可利用这种过滤器实现身份验证、在集群中选择请求的微服务、记录调试信息等。
- **ROUTING：**这种过滤器将请求路由到微服务。这种过滤器用于构建发送给微服务的请求，并使用Apache HttpClient或Netfilx Ribbon请求微服务。
- **POST：**这种过滤器在路由到微服务以后执行。这种过滤器可用来为响应添加标准的HTTP Header、收集统计信息和指标、将响应从微服务发送给客户端等。
- **ERROR：**在其他阶段发生错误时执行该过滤器。 除了默认的过滤器类型，Zuul还允许我们创建自定义的过滤器类型。例如，我们可以定制一种STATIC类型的过滤器，直接在Zuul中生成响应，而不将请求转发到后端的微服务。

### Zuul中默认实现的Filter

| 类型  | 顺序 | 过滤器                  | 功能                       |
| ----- | ---- | ----------------------- | -------------------------- |
| pre   | -3   | ServletDetectionFilter  | 标记处理Servlet的类型      |
| pre   | -2   | Servlet30WrapperFilter  | 包装HttpServletRequest请求 |
| pre   | -1   | FormBodyWrapperFilter   | 包装请求体                 |
| route | 1    | DebugFilter             | 标记调试标志               |
| route | 5    | PreDecorationFilter     | 处理请求上下文供后续使用   |
| route | 10   | RibbonRoutingFilter     | serviceId请求转发          |
| route | 100  | SimpleHostRoutingFilter | url请求转发                |
| route | 500  | SendForwardFilter       | forward请求转发            |
| post  | 0    | SendErrorFilter         | 处理有错误的请求响应       |
| post  | 1000 | SendResponseFilter      | 处理正常的请求响应         |

**禁用指定的Filter**

可以在application.yml中配置需要禁用的filter，格式：

```
zuul:
	FormBodyWrapperFilter:
		pre:
			disable: true
```

[参考链接](http://www.ityouknow.com/springcloud/2018/01/20/spring-cloud-zuul.html)

## 限流

pom.xml

```xml
<dependency>
    <groupId>com.marcosbarbero.cloud</groupId>
    <artifactId>spring-cloud-zuul-ratelimit</artifactId>
    <version>1.7.2.RELEASE</version>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-redis</artifactId>
</dependency>
```

配置文件

```tex
# 开启限流配置
zuul.ratelimit.enabled=true

# 限流存储配置
zuul.ratelimit.repository=REDIS
# 每秒服务的限流
#zuul.ratelimit.policies.producer.limit=10
zuul.ratelimit.key-prefix=ZUUL_URL
zuul.ratelimit.default-policy.type=URL
# 具体的 次数间隔刷新时间
#zuul.ratelimit.policies.producer.refresh-interval=60
#zuul.ratelimit.policies.producer.type=ORIGIN

# 统一的限制配置
zuul.ratelimit.default-policy.limit=10
zuul.ratelimit.default-policy.refresh-interval=10

# 定义redis配置
spring.redis.host=192.168.0.90
spring.redis.password=
spring.redis.port=6379
```



## 如何配置Hystrix线程池 

```yaml
zuul:
  threadPool:
    useSeparateThreadPools: true # 开启线程隔离
    threadPoolKeyPrefix: zuulgw # 线程池的前缀
    
```







## 核心组件

spring-cloud-netflix-core - spring.factories

### 默认需要加载的配置类

```yaml
org.springframework.boot.autoconfigure.EnableAutoConfiguration=\
org.springframework.cloud.netflix.archaius.ArchaiusAutoConfiguration,\
org.springframework.cloud.netflix.feign.ribbon.FeignRibbonClientAutoConfiguration,\
org.springframework.cloud.netflix.feign.FeignAutoConfiguration,\
org.springframework.cloud.netflix.feign.encoding.FeignAcceptGzipEncodingAutoConfiguration,\
org.springframework.cloud.netflix.feign.encoding.FeignContentGzipEncodingAutoConfiguration,\
org.springframework.cloud.netflix.hystrix.HystrixAutoConfiguration,\
org.springframework.cloud.netflix.hystrix.security.HystrixSecurityAutoConfiguration,\
org.springframework.cloud.netflix.ribbon.RibbonAutoConfiguration,\
org.springframework.cloud.netflix.rx.RxJavaAutoConfiguration,\
org.springframework.cloud.netflix.metrics.servo.ServoMetricsAutoConfiguration,\
org.springframework.cloud.netflix.zuul.ZuulServerAutoConfiguration,\
org.springframework.cloud.netflix.zuul.ZuulProxyAutoConfiguration

org.springframework.cloud.client.circuitbreaker.EnableCircuitBreaker=\
org.springframework.cloud.netflix.hystrix.HystrixCircuitBreakerConfiguration

org.springframework.boot.env.EnvironmentPostProcessor=\
org.springframework.cloud.netflix.metrics.ServoEnvironmentPostProcessor
```



#### 入口类

- ZuulFilter : 启动类，用于zuul容器初始化触发的入口类.这里面包含了 pre、route、post等三种生命周期的定义

- ZuulServlet : 过滤器,用于来接受请求，并且在该类中定义了preRoute、route、postRoute等三种请求流转
  - FilterProcessor : 过滤器的处理器



介绍三个Route路由转发类型的filter:

- SimpleHostRoutingFilter，直接转换host地址。
- SendForwardFilter，本地url跳转，网关里面定义的controller访问触发。
- RibbonRoutingFilter，基于服务注册与发现，动态的路由转发。

```yaml
# 如果不走eureka，直接走本地的配置。
zuul:
	routes:
		service_name:
			url: http://localhost:8888
```







### 过滤器拦截请求

 在过滤器中对请求进行拦截是一个很常见的需求，本节的“使用过滤器”部分中讲解的 IP 黑名单限制就是这样的一个需求。如果请求在黑名单中，就不能让该请求继续往下执行，需要对其进行拦截并返回结果给客户端。 

拦截和返回结果只需要 5 行代码即可实现，代码如下所示。

```java
RequestContext ctx = RequestContext.getCurrentContext();
// 告诉 Zuul 不需要将当前请求转发到后端的服务 			RibbonRoutingFilter 的过滤条件
ctx.setSendZuulResponse(false);
// 告诉zuul不需要将当前的请求转发到网关的controller，		SendForwardFilter过滤条件
ctx.set("sendForwardFilter.ran", true);
ctx.setResponseBody("返回信息");
return null;
```

上面的条件只是在特定的Filter中会被过滤掉，假设我们自定义的拦截器有很多个，根据优先级排序，发现第一个就已经需要拦截掉了，这个时候按照上面的设置可能是行不通的，但可以参考上面的形式自己做一个：

```java
// 告诉下面的拦截器，不要再执行了
ctx.set("isSuccess", false);
```

利用这种方法，在后面的过滤器就需要用到这个值来决定自己此时是否需要执行，此时只需要在 shouldFilter 方法中加上如下所示的代码即可。

```java
public boolean shouldFilter() {
    RequestContext ctx = RequestContext.getCurrentContext();
    Object success = ctx.get("isSuccess");
    return success == null ? true : Boolean.parseBoolean(success.toString());
}
```

实际上都是通过打标记的形式，来传递值判断。



## 带着问题看源码

### 1. Zuul的启动流程是怎么样的?

1. 首先搭建一个zuul相关的项目。
2. 启动完成之后，在route层面打一个断点，即可发现请求的入口在哪里。
3. 这是先决条件，能够得到`ZuulController`

既然我们知道了请求路径会到ZuulController那么说明，初始化的时候一定和这个有关，查看ZuulController相关的调用链，去定位是在哪个部分被初始化的？

然后得到`ZuulServerAutoConfiguration`，熟悉SpringBoot的同学应该知道，Configuration`结尾的通常都是Spring的配置类，也就是说这个类就是Zuul相关的关键配置类都在这个里面..

然后看到这个配置类

```java
@Configuration
@EnableConfigurationProperties({ ZuulProperties.class }) // 开启zuul相关的属性配置
@ConditionalOnClass(ZuulServlet.class)					// 启动该类的条件类
@ConditionalOnBean(ZuulServerMarkerConfiguration.Marker.class)	// 启动该类的条件必须要IOC容器中存在
// Make sure to get the ServerProperties from the same place as a normal web app would
// 确保从普通的Web应用程序中获取ServerProperties
@Import(ServerPropertiesAutoConfiguration.class)
public class ZuulServerAutoConfiguration {

	@Autowired
	protected ZuulProperties zuulProperties;

	@Autowired
	protected ServerProperties server;

    // 异常的配置处理控制器
	@Autowired(required = false)
	private ErrorController errorController;

	@Bean
	public HasFeatures zuulFeature() {
		return HasFeatures.namedFeature("Zuul (Simple)", ZuulServerAutoConfiguration.class);
	}

    // 路由管理器
	@Bean
	@Primary
	public CompositeRouteLocator primaryRouteLocator(
			Collection<RouteLocator> routeLocators) {
		return new CompositeRouteLocator(routeLocators);
	}

    // 路由前缀装饰
	@Bean
	@ConditionalOnMissingBean(SimpleRouteLocator.class)
	public SimpleRouteLocator simpleRouteLocator() {
		return new SimpleRouteLocator(this.server.getServletPrefix(),
				this.zuulProperties);
	}
	// servlet的包装类
	@Bean
	public ZuulController zuulController() {
		return new ZuulController();
	}

    // springMVC中的拦截器
	@Bean
	public ZuulHandlerMapping zuulHandlerMapping(RouteLocator routes) {
		ZuulHandlerMapping mapping = new ZuulHandlerMapping(routes, zuulController());
		mapping.setErrorController(this.errorController);
		return mapping;
	}
	
    // 刷新监听的对象
	@Bean
	public ApplicationListener<ApplicationEvent> zuulRefreshRoutesListener() {
		return new ZuulRefreshListener();
	}
	// 如果没有Servlet则重新注册一个
	@Bean
	@ConditionalOnMissingBean(name = "zuulServlet")
	public ServletRegistrationBean zuulServlet() {
		ServletRegistrationBean servlet = new ServletRegistrationBean(new ZuulServlet(),
				this.zuulProperties.getServletPattern());
		// The whole point of exposing this servlet is to provide a route that doesn't
		// buffer requests.
		servlet.addInitParameter("buffer-requests", "false");
		return servlet;
	}

	// pre filters

    // Zuul的PRE过滤器,只是用来传递一个是否是DispatchServlet转发过来的
	@Bean
	public ServletDetectionFilter servletDetectionFilter() {
		return new ServletDetectionFilter();
	}

    // zuul的前置过滤器，用来判断该请求是否是处理表单和文件上传请求类型的
	@Bean
	public FormBodyWrapperFilter formBodyWrapperFilter() {
		return new FormBodyWrapperFilter();
	}
	
    // 是否开启debug的filter , 请求中如果带有?zuul.debug.parameter=true会被触发
	@Bean
	public DebugFilter debugFilter() {
		return new DebugFilter();
	}

    // 兼容servlet 3.0的请求
	@Bean
	public Servlet30WrapperFilter servlet30WrapperFilter() {
		return new Servlet30WrapperFilter();
	}

	// post filters
	// 返回结果处理,包括@ResponseBody处理
	@Bean
	public SendResponseFilter sendResponseFilter() {
		return new SendResponseFilter();
	}

    // 如果出现异常情况,则会由该filter将错误信息封装起来统一转发到errorController里
	@Bean
	public SendErrorFilter sendErrorFilter() {
		return new SendErrorFilter();
	}

    // 判断是否是转发请求
	@Bean
	public SendForwardFilter sendForwardFilter() {
		return new SendForwardFilter();
	}

    // 如果没有设置zuul.ribbon.eager-load.enabled时,则会开启ZuulRouteApplicationContextInitializer类
    // 而这个类主要就是获取routes集合
	@Bean
	@ConditionalOnProperty(value = "zuul.ribbon.eager-load.enabled", matchIfMissing = false)
	public ZuulRouteApplicationContextInitializer zuulRoutesApplicationContextInitiazer(
			SpringClientFactory springClientFactory) {
		return new ZuulRouteApplicationContextInitializer(springClientFactory,
				zuulProperties);
	}

    // zuul的过滤器配置
	@Configuration
	protected static class ZuulFilterConfiguration {

		@Autowired
		private Map<String, ZuulFilter> filters;

		@Bean
		public ZuulFilterInitializer zuulFilterInitializer(
				CounterFactory counterFactory, TracerFactory tracerFactory) {
			FilterLoader filterLoader = FilterLoader.getInstance();
			FilterRegistry filterRegistry = FilterRegistry.instance();
			return new ZuulFilterInitializer(this.filters, counterFactory, tracerFactory, filterLoader, filterRegistry);
		}

	}

    // 计数器
	@Configuration
	@ConditionalOnClass(CounterService.class)
	protected static class ZuulCounterFactoryConfiguration {

		@Bean
		@ConditionalOnBean(CounterService.class)
		public CounterFactory counterFactory(CounterService counterService) {
			return new DefaultCounterFactory(counterService);
		}
	}

    // 统计指标工厂
	@Configuration
	protected static class ZuulMetricsConfiguration {

		@Bean
		@ConditionalOnMissingBean(CounterFactory.class)
		public CounterFactory counterFactory() {
			return new EmptyCounterFactory();
		}

		@ConditionalOnMissingBean(TracerFactory.class)
		@Bean
		public TracerFactory tracerFactory() {
			return new EmptyTracerFactory();
		}

	}

    // 监听刷新
	private static class ZuulRefreshListener
			implements ApplicationListener<ApplicationEvent> {

		@Autowired
		private ZuulHandlerMapping zuulHandlerMapping;

		private HeartbeatMonitor heartbeatMonitor = new HeartbeatMonitor();

		@Override
		public void onApplicationEvent(ApplicationEvent event) {
			if (event instanceof ContextRefreshedEvent
					|| event instanceof RefreshScopeRefreshedEvent
					|| event instanceof RoutesRefreshedEvent) {
				this.zuulHandlerMapping.setDirty(true);
			}
			else if (event instanceof HeartbeatEvent) {
				if (this.heartbeatMonitor.update(((HeartbeatEvent) event).getValue())) {
					this.zuulHandlerMapping.setDirty(true);
				}
			}
		}

	}

} 

```

从上面出来一个疑问

1. `ZuulServerAutoConfiguration`该类是何时加载的?

查看调用链发现出自`spring-cloud-netflix-core`的jar的`spring.factories`

> SpringBoot在启动加载的时候会通过`SpringFactoriesLoader`的工具类从每个jar包中获取spring.factories文件并且查找该文件中存在的类。因为核心中已经标注了ZuulServerAutoConfiguration该类,表明你引入spring-cloud-netflix-core这个jar包时，即便什么都不做，它也会加载**ZuulServerAutoConfiguration**这个配置类

2. 类上面有一个@ConditionalOnBean(ZuulServerMarkerConfiguration.Marker.class)注解表明当前Spring容器中必须要存在ZuulServerMarkerConfiguration.Marker.class这个类型的bean，那么这个类是何时被加载的？

因为如果不加载ZuulServerMarkerConfiguration.Marker.class这个bean，ZuulServerAutoConfiguration是不符合初始化条件的..

通过查看上层引用发现了`EnableZuulServer`这个注解，这个时候会发现，明白了为什么Zuul项目必须在启动类上标注@**EnableZuulServer**来启动网关了

所以这里可以初始化流程为:

1. springboot启动的时候会去读取spring.factories文件，并加载文件中指定的类
2. 加载配置类的时候如果类上面存在一些条件，这个条件是需要在启动类上标注@**EnableZuulServer**才能触发配置类的初始化
3. 配置类的一些bean的注册
   1. zuul的自动属性配置类
   2. zuul的植入springmvc拦截器
   3. zuul的自带拦截器
      1. 拦截器中将请求流转到zuulController处理,controller又流转给了ZuulServlet进行处理
      2. zuulServlet专门处理PRE、POST、error等流程拦截器。
         1. 上面各阶段的处理内容指定的处理器是**ZuulRunner**
         2. **ZuulRunner**将整个处理过程抽象给了FilterProcess，相当于说整个过滤器的执行流程都是由FilterProcess统一处理
         3. 处理完成之后，会将结果通过上面Configruration的SendResponseFilter做返回。



**ZuulController**: 继承了`ServletWrappingController`,也就是Servlet的一个包装类，用来包装ZuulServlet。

**ZuulServlet**: 用来处理preRoute、route、postRoute三个阶段的控制

**FilterProcess**: 用来处理上面每个阶段的统一定义。



### 2. zuul的请求转发是如何做到的?

首先思考一个问题：既然Zuul已经提供了3个阶段的处理方式。那么请求转发应该是处于哪个阶段处理会比较合适？

**route。**

那么我们只需要在这个阶段去找对应的处理器，就知道他是怎么实现的了

**RibbonRoutingFilter** : 这个是最符合转发请求的目标..我们来看一下这个类到底做了什么事情?

> 因为ribbon本身就是做负载均衡功能的。

```java
public class RibbonRoutingFilter extends ZuulFilter {

	private static final Log log = LogFactory.getLog(RibbonRoutingFilter.class);

	protected ProxyRequestHelper helper;
	protected RibbonCommandFactory<?> ribbonCommandFactory;
	protected List<RibbonRequestCustomizer> requestCustomizers;
	private boolean useServlet31 = true;

	public RibbonRoutingFilter(ProxyRequestHelper helper,
							   RibbonCommandFactory<?> ribbonCommandFactory,
							   List<RibbonRequestCustomizer> requestCustomizers) {
		this.helper = helper;
		this.ribbonCommandFactory = ribbonCommandFactory;
		this.requestCustomizers = requestCustomizers;
		// To support Servlet API 3.1 we need to check if getContentLengthLong exists
		try {
			//TODO: remove in 2.0
			HttpServletRequest.class.getMethod("getContentLengthLong");
		} catch(NoSuchMethodException e) {
			useServlet31 = false;
		}
	}

	public RibbonRoutingFilter(RibbonCommandFactory<?> ribbonCommandFactory) {
		this(new ProxyRequestHelper(), ribbonCommandFactory, null);
	}

	/* for testing */ boolean isUseServlet31() {
		return useServlet31;
	}

	@Override
	public String filterType() {
		return ROUTE_TYPE;
	}

	@Override
	public int filterOrder() {
		return RIBBON_ROUTING_FILTER_ORDER;
	}

	@Override
	public boolean shouldFilter() {
		RequestContext ctx = RequestContext.getCurrentContext();
		return (ctx.getRouteHost() == null && ctx.get(SERVICE_ID_KEY) != null
				&& ctx.sendZuulResponse());
	}

	@Override
	public Object run() {
		RequestContext context = RequestContext.getCurrentContext();
		this.helper.addIgnoredHeaders();
		try {
			RibbonCommandContext commandContext = buildCommandContext(context);
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

	protected RibbonCommandContext buildCommandContext(RequestContext context) {
		HttpServletRequest request = context.getRequest();

		MultiValueMap<String, String> headers = this.helper
				.buildZuulRequestHeaders(request);
		MultiValueMap<String, String> params = this.helper
				.buildZuulRequestQueryParams(request);
		String verb = getVerb(request);
		InputStream requestEntity = getRequestBody(request);
		if (request.getContentLength() < 0 && !verb.equalsIgnoreCase("GET")) {
			context.setChunkedRequestBody();
		}

		String serviceId = (String) context.get(SERVICE_ID_KEY);
		Boolean retryable = (Boolean) context.get(RETRYABLE_KEY);
		Object loadBalancerKey = context.get(LOAD_BALANCER_KEY);

		String uri = this.helper.buildZuulRequestURI(request);

		// remove double slashes
		uri = uri.replace("//", "/");

		long contentLength = useServlet31 ? request.getContentLengthLong(): request.getContentLength();

		return new RibbonCommandContext(serviceId, verb, uri, retryable, headers, params,
				requestEntity, this.requestCustomizers, contentLength, loadBalancerKey);
	}

	protected ClientHttpResponse forward(RibbonCommandContext context) throws Exception {
		Map<String, Object> info = this.helper.debug(context.getMethod(),
				context.getUri(), context.getHeaders(), context.getParams(),
				context.getRequestEntity());

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

	protected ClientHttpResponse handleException(Map<String, Object> info,
			HystrixRuntimeException ex) throws ZuulException {
		int statusCode = HttpStatus.INTERNAL_SERVER_ERROR.value();
		Throwable cause = ex;
		String message = ex.getFailureType().toString();

		ClientException clientException = findClientException(ex);
		if (clientException == null) {
			clientException = findClientException(ex.getFallbackException());
		}

		if (clientException != null) {
			if (clientException
					.getErrorType() == ClientException.ErrorType.SERVER_THROTTLED) {
				statusCode = HttpStatus.SERVICE_UNAVAILABLE.value();
			}
			cause = clientException;
			message = clientException.getErrorType().toString();
		}
		info.put("status", String.valueOf(statusCode));
		throw new ZuulException(cause, "Forwarding error", statusCode, message);
	}

	protected ClientException findClientException(Throwable t) {
		if (t == null) {
			return null;
		}
		if (t instanceof ClientException) {
			return (ClientException) t;
		}
		return findClientException(t.getCause());
	}

	protected InputStream getRequestBody(HttpServletRequest request) {
		InputStream requestEntity = null;
		try {
			requestEntity = (InputStream) RequestContext.getCurrentContext()
					.get(REQUEST_ENTITY_KEY);
			if (requestEntity == null) {
				requestEntity = request.getInputStream();
			}
		}
		catch (IOException ex) {
			log.error("Error during getRequestBody", ex);
		}
		return requestEntity;
	}

	protected String getVerb(HttpServletRequest request) {
		String method = request.getMethod();
		if (method == null) {
			return "GET";
		}
		return method;
	}

	protected void setResponse(ClientHttpResponse resp)
			throws ClientException, IOException {
		RequestContext.getCurrentContext().set("zuulResponse", resp);
		this.helper.setResponse(resp.getRawStatusCode(),
				resp.getBody() == null ? null : resp.getBody(), resp.getHeaders());
	}

}

```

既然是Zuul的Filter那么肯定只需要看`run`的方法就行了

```java
@Override
public Object run() {
    RequestContext context = RequestContext.getCurrentContext();
    // 忽略某些请求
    this.helper.addIgnoredHeaders();
    try {
        // 构建一个Ribbon的命令上下文，这个上下文会确定你到底是用HttpClient还是OKHttp
        RibbonCommandContext commandContext = buildCommandContext(context);
        // 请求转发
        ClientHttpResponse response = forward(commandContext);
        // 结果集处理
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
```

**构建一个Ribbon命令上下文执行器**

```java
protected RibbonCommandContext buildCommandContext(RequestContext context) {
		HttpServletRequest request = context.getRequest();
		// 获取zuul上下文中的head信息
		MultiValueMap<String, String> headers = this.helper
				.buildZuulRequestHeaders(request);
    	// 如果是get请求获取请求URL中的参数
		MultiValueMap<String, String> params = this.helper
				.buildZuulRequestQueryParams(request);
    	// 获取请求
		String verb = getVerb(request);
    	// 获取body参数
		InputStream requestEntity = getRequestBody(request);
		if (request.getContentLength() < 0 && !verb.equalsIgnoreCase("GET")) {
			context.setChunkedRequestBody();
		}
		// 获取服务编号 这个里面的参数是在PreDecorationFilter拦截器中通过拦截URL中截取到的服务编号
		String serviceId = (String) context.get(SERVICE_ID_KEY);
		Boolean retryable = (Boolean) context.get(RETRYABLE_KEY);
		Object loadBalancerKey = context.get(LOAD_BALANCER_KEY);
		// 保留除项目之外的项目地址
		String uri = this.helper.buildZuulRequestURI(request);

		// remove double slashes
		uri = uri.replace("//", "/");

		long contentLength = useServlet31 ? request.getContentLengthLong(): request.getContentLength();
		// 根据上面的得到的参数,构建一个ribbon的上下文
		return new RibbonCommandContext(serviceId, verb, uri, retryable, headers, params,
				requestEntity, this.requestCustomizers, contentLength, loadBalancerKey);
	}
```



`RibbonCommandContext` :  构建这个类的时候有几个点需要注意一下，这个类是继承了`AbstractRibbonCommand`，然后再创建类的时候会触发super方法。而这其中构建getSetter方法比较重点

```java
public AbstractRibbonCommand(String commandKey, LBC client,
								 RibbonCommandContext context, ZuulProperties zuulProperties,
								 ZuulFallbackProvider fallbackProvider, IClientConfig config) {
		this(getSetter(commandKey, zuulProperties, config), client, context, fallbackProvider, config);
	}
```

构建一个Setter类

```java
protected static Setter getSetter(final String commandKey,
			ZuulProperties zuulProperties, IClientConfig config) {

		// @formatter:off
    // 获取Ribbon相关的配置，也就是YML中的ribbon开头的配置
		Setter commandSetter = Setter.withGroupKey(HystrixCommandGroupKey.Factory.asKey("RibbonCommand"))
								.andCommandKey(HystrixCommandKey.Factory.asKey(commandKey));
    	// 根据ribbon的配置构建一个Hystrix配置类
		final HystrixCommandProperties.Setter setter = createSetter(config, commandKey, zuulProperties);
    	// 根据配置来确定是采用信号量隔离还是线程隔离
    	// 如果是信号量
		if (zuulProperties.getRibbonIsolationStrategy() == ExecutionIsolationStrategy.SEMAPHORE){
			final String name = ZuulConstants.ZUUL_EUREKA + commandKey + ".semaphore.maxSemaphores";
			// we want to default to semaphore-isolation since this wraps
			// 2 others commands that are already thread isolated
			final DynamicIntProperty value = DynamicPropertyFactory.getInstance()
					.getIntProperty(name, zuulProperties.getSemaphore().getMaxSemaphores());
			setter.withExecutionIsolationSemaphoreMaxConcurrentRequests(value.get());
		} 
    	// 如果是线程池
    	else if (zuulProperties.getThreadPool().isUseSeparateThreadPools()) {
            // 则根据每个线程池的key来构建一个线程池,让每个key都拥有自己独立的线程池
			final String threadPoolKey = zuulProperties.getThreadPool().getThreadPoolKeyPrefix() + commandKey;
			commandSetter.andThreadPoolKey(HystrixThreadPoolKey.Factory.asKey(threadPoolKey));
		}
		// 将当前修改的配置列为默认的配置
		return commandSetter.andCommandPropertiesDefaults(setter);
		// @formatter:on
	}
```

`createSetter` : 构建配置类的时候，主要是获取超时时间

这里构建超时时间的时候又存在一个优先级的概念

```java
protected static int getHystrixTimeout(IClientConfig config, String commandKey) {
    	// 获取ribbon配置的超时时间  ribbon.ReadTimeout + ribbon.ConnectTimeout 
    	//(ribbonReadTimeout + ribbonConnectTimeout) * (maxAutoRetries + 1) * (maxAutoRetriesNextServer + 1)
		int ribbonTimeout = getRibbonTimeout(config, commandKey);
		DynamicPropertyFactory dynamicPropertyFactory = DynamicPropertyFactory.getInstance();
    	// 然后获取hystrix配置的超时时间 hystrix.command.default.execution.isolation.thread.timeoutInMilliseconds
		int defaultHystrixTimeout = dynamicPropertyFactory.getIntProperty("hystrix.command.default.execution.isolation.thread.timeoutInMilliseconds",
			0).get();
    	// 最后获取非默认的hystrix配置的时间
		int commandHystrixTimeout = dynamicPropertyFactory.getIntProperty("hystrix.command." + commandKey + ".execution.isolation.thread.timeoutInMilliseconds",
			0).get();
		int hystrixTimeout;
    	// 优先级最高
		if(commandHystrixTimeout > 0) {
			hystrixTimeout = commandHystrixTimeout;
		}
    	// 其次
		else if(defaultHystrixTimeout > 0) {
			hystrixTimeout = defaultHystrixTimeout;
		} else {
            // 最后
			hystrixTimeout = ribbonTimeout;
		}
		if(hystrixTimeout < ribbonTimeout) {
			LOGGER.warn("The Hystrix timeout of " + hystrixTimeout + "ms for the command " + commandKey +
				" is set lower than the combination of the Ribbon read and connect timeout, " + ribbonTimeout + "ms.");
		}
		return hystrixTimeout;
	}
```

关键的`forward`方法

```java
protected ClientHttpResponse forward(RibbonCommandContext context) throws Exception {
    	// 链路debug类数据存储，这里收集了请求的信息
		Map<String, Object> info = this.helper.debug(context.getMethod(),
				context.getUri(), context.getHeaders(), context.getParams(),
				context.getRequestEntity());
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

**create** : 创建一个ribbon的命令执行器

这里的RibbonCommandFactory工厂在Ribbon中存在三种类型:

- HttpClientRibbonCommandFactory : HttpClient 默认的
- OkHttpRibbonCommandFactory : OKhttp默认的实现
- RestClientRibbonCommandFactory : RestClient 兼容Spring的RestTemplate

> 工厂初始化的类在RibbonCommandFactoryConfiguration中。

而create的方法就是创建三个里面的其中一个AbstractRibbonCommand类型

- HttpClientRibbonCommand : HttpClient执行器，默认的。
- OkHttpRibbonCommand : OKhttp执行器
- RestClientRibbonCommand : restTemplate类型的执行器,目前好像被弃用了

```java
public HttpClientRibbonCommand create(final RibbonCommandContext context) {
    	// 获取失败执行器
		ZuulFallbackProvider zuulFallbackProvider = getFallbackProvider(context.getServiceId());
    	// 获取服务编号
		final String serviceId = context.getServiceId();
    	//  根据serviceId去获取RibbonLoadBalancingHttpClient的对象
		final RibbonLoadBalancingHttpClient client = this.clientFactory.getClient(
				serviceId, RibbonLoadBalancingHttpClient.class);
    	// 如果说上面只是为了得到一个符合满足指定应用的对象，那么下面就是为了这个负载做处理
    	
		client.setLoadBalancer(this.clientFactory.getLoadBalancer(serviceId));

		return new HttpClientRibbonCommand(serviceId, client, context, zuulProperties, zuulFallbackProvider,
				clientFactory.getClientConfig(serviceId));
	}
```

clientFactory : 默认实现类`SpringClientFactory` 这个类是`org.springframework.cloud.netflix.ribbon`中的继承了`NamedContextFactory`类，大概意思就是根据名称获取对象。而这里的名称指的是serviceId，也就是application名称。其实就是一个专属ribbon的工厂类，主要作用就是能够通过serviceId就能够从工厂中拿到RibbonLoadBalancingHttpClient对象

这里只需要看下里面的内容是如何被创建的。

**FeignClientFactoryBean**

`RibbonApplicationContextInitializer` : 监听类，这个类的主要作用就是刷新应用。不必在第一次访问的时候再加载，入口类`RibbonAutoConfiguration`的**ribbonApplicationContextInitializer**方法。

> 如果配置文件中指定了ribbon.eager-load.enabled=true，并且ribbon.eager-load.clients=serviceId1,serviceId2。
>
> 这里就表示从RibbonAutoConfiguration中触发直接初始化client的方法。如果没有指定的话，就只能在第一次访问的时候触发NamedContextFactory的createContext方法去刷新这个工厂中的对象

如何捕捉到Eureka上面的服务地址的?

`ILoadBalancer` :  统一的负载均衡接口

`ZoneAwareLoadBalancer`： 默认的接口实现

`RibbonClientConfiguration` : 负载均衡客户端配置。

`RibbonEurekaAutoConfiguration`.`ribbonServerList`

`CloudEurekaClient` : DiscoveryClient.getInstancesByVipAddress 获取服务列表

`EurekaClientAutoConfiguration`： 初始化Eureka配置



### 3. zuul如何处理异常情况下返回的?



### 4. zuul是如何进行请求负载均衡的?