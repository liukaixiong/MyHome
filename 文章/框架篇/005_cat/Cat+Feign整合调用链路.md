## Feign

Feign 是一个声明web服务客户端，这便得编写web服务客户端更容易，使用Feign 创建一个接口并对它进行注解，它具有可插拔的注解支持包括Feign注解与JAX-RS注解，Feign还支持可插拔的编码器与解码器，Spring Cloud 增加了对 Spring MVC的注解，Spring Web 默认使用了HttpMessageConverters, Spring Cloud 集成 Ribbon 和 Eureka 提供的负载均衡的HTTP客户端 Feign. 

## CAT

CAT是一个实时和接近全量的监控系统，它侧重于对Java应用的监控，除了与点评RPC组件融合的很好之外，他将会能与Spring、MyBatis、Dubbo 等框架以及Log4j 等结合，不久将会支持PHP、C++、Go等多语言应用，基本接入了美团点评上海侧所有核心应用。目前在中间件（MVC、RPC、数据库、缓存等）框架中得到广泛应用，为美团点评各业务线提供系统的性能指标、健康状况、监控告警等。 



## CAT消息链路的构建思路

A  -> B -> C

CAT的链路树的话，其实应该是将消息的编号串联起来，然后可以在管理页面上将这些消息编号统一展现。

编号模型:

- ROOTID : 根的编号
- PARENTID : 上级编号
- CHILD : 子级编号

消息树就是上下级编号关联

因为Feign底层的话也是基于HTTP去调用的，所以参数之间传递的时候需要将消息编号进行传递，并且关联起来。

也就是说 A 客户端要生成编号模型，然后通过Feign调用B的时候带过去。

B客户端接收到这个编号模型的时候，在本地生成消息树的时候，将编号模型植入进去完成绑定关联



####  具体实现细节

`A -> B`

1. Feign发起一个HTTP调用前需要通过CAT构建一个消息树,这一部分通过AOP来做，AOP拿到消息模型之后，绑定到当前Request中

```java
@Aspect
@EnableAspectJAutoProxy
@Configuration
public class CatMsgIdAspectBean {

    private Logger logger = LoggerFactory.getLogger(CatMsgIdAspectBean.class);

    public Object around(ProceedingJoinPoint pjp) throws Throwable {
        createMessageTree();
        Object proceed = pjp.proceed();
        return proceed;
    }

    /**
     * 统一设置消息编号的messageId
     */
    private void createMessageTree() {
        CatMsgContext context = new CatMsgContext();
        Cat.logRemoteCallClient(context);
        RequestAttributes requestAttributes = RequestContextHolder.getRequestAttributes();
        requestAttributes.setAttribute(Cat.Context.PARENT, context.getProperty(Cat.Context.PARENT), 0);
        requestAttributes.setAttribute(Cat.Context.ROOT, context.getProperty(Cat.Context.ROOT), 0);
        requestAttributes.setAttribute(Cat.Context.CHILD, context.getProperty(Cat.Context.CHILD), 0);
        requestAttributes.setAttribute(CatMsgConstants.APPLICATION_KEY, Cat.getManager().getDomain(), 0);
    }
}
```

1. 生成好了消息树之后，Feign在拦截请求中将消息模型绑定到请求的Head中

```java
@Component
public class FeignInterceptor implements RequestInterceptor {

    private Logger logger = LoggerFactory.getLogger(FeignInterceptor.class);

    @Override
    public void apply(RequestTemplate requestTemplate) {
        RequestAttributes requestAttributes = RequestContextHolder.getRequestAttributes();
        String rootId = requestAttributes.getAttribute(Cat.Context.ROOT, 0).toString();
        String childId = requestAttributes.getAttribute(Cat.Context.CHILD, 0).toString();
        String parentId = requestAttributes.getAttribute(Cat.Context.PARENT, 0).toString();
        requestTemplate.header(Cat.Context.ROOT, rootId);
        requestTemplate.header(Cat.Context.CHILD, childId);
        requestTemplate.header(Cat.Context.PARENT, parentId);
        requestTemplate.header(CatMsgConstants.APPLICATION_KEY, Cat.getManager().getDomain());
        logger.info(" 开始Feign远程调用 : " + requestTemplate.method() + " 消息模型 : rootId = " + rootId + " parentId = " + parentId + " childId = " + childId);
    }
}
```

1. 请求发送之后，B客户端怎么去接受？

```java
public class HttpCatCrossFliter implements Filter {

    private static final Logger logger = LoggerFactory.getLogger(HttpCatCrossFliter.class);

    private static final String DEFAULT_APPLICATION_NAME = "default";

    @Override
    public void doFilter(ServletRequest req, ServletResponse resp, FilterChain filterChain) throws IOException, ServletException {

        HttpServletRequest request = (HttpServletRequest) req;
        String requestURI = request.getRequestURI();

        Transaction t = Cat.newTransaction(CatMsgConstants.CROSS_SERVER, requestURI);

        try {
            Cat.Context context = new CatMsgContext();
            context.addProperty(Cat.Context.ROOT, request.getHeader(Cat.Context.ROOT));
            context.addProperty(Cat.Context.PARENT, request.getHeader(Cat.Context.PARENT));
            context.addProperty(Cat.Context.CHILD, request.getHeader(Cat.Context.CHILD));
            Cat.logRemoteCallServer(context);
            this.createProviderCross(request, t);

            filterChain.doFilter(req, resp);
            t.setStatus(Transaction.SUCCESS);
        } catch (Exception e) {
            logger.error("------ Get cat msgtree error : ", e);

            Event event = Cat.newEvent("HTTP_REST_CAT_ERROR", requestURI);
            event.setStatus(e);
            completeEvent(event);
            t.addChild(event);
            t.setStatus(e.getClass().getSimpleName());
        } finally {
            t.complete();
        }

    }

    @Override
    public void init(FilterConfig arg0) throws ServletException {
    }

    @Override
    public void destroy() {
    }

    /**
     * 串联provider端消息树
     *
     * @param request
     * @param t
     */
    private void createProviderCross(HttpServletRequest request, Transaction t) {
        Event crossAppEvent = Cat.newEvent(CatMsgConstants.PROVIDER_CALL_APP, request.getHeader(CatMsgConstants.APPLICATION_KEY));    //clientName
        Event crossServerEvent = Cat.newEvent(CatMsgConstants.PROVIDER_CALL_SERVER, request.getRemoteAddr());    //clientIp
        crossAppEvent.setStatus(Event.SUCCESS);
        crossServerEvent.setStatus(Event.SUCCESS);
        completeEvent(crossAppEvent);
        completeEvent(crossServerEvent);
        t.addChild(crossAppEvent);
        t.addChild(crossServerEvent);
    }

    private void completeEvent(Event event) {
        if (event != NullMessage.EVENT) {
            AbstractMessage message = (AbstractMessage) event;
            message.setCompleted(true);
        }
    }

}
```
- 将拦截器注册到容器中
```java
@Configuration
public class CatFilterConfigure {

    @Bean
    public FilterRegistrationBean catFilter() {
        FilterRegistrationBean registration = new FilterRegistrationBean();
        HttpCatCrossFliter filter = new HttpCatCrossFliter();
        registration.setFilter(filter);
        registration.addUrlPatterns("/*");
        registration.setName("cat-filter");
        registration.setOrder(1);
        return registration;
    }
}
```

接收好了之后，基本流程已经完毕了。

![调用链路日志](https://upload-images.jianshu.io/upload_images/6370985-c0987a0bc17d0f8e.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


**Cross报表**

![消费者调用](https://upload-images.jianshu.io/upload_images/6370985-a84b04952688bd45.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

![方法调用](https://upload-images.jianshu.io/upload_images/6370985-3e16b57f2459974d.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


#### 其他代码：

```java
public class CatMsgConstants {

    public static final String CROSS_CONSUMER = "PigeonCall";

    /**
     * Cross报表中的数据标识
     */
    public static final String CROSS_SERVER = "PigeonService";

    public static final String PROVIDER_APPLICATION_NAME = "serverApplicationName";

    public static final String CONSUMER_CALL_SERVER = "PigeonCall.server";

    public static final String CONSUMER_CALL_APP = "PigeonCall.app";

    public static final String CONSUMER_CALL_PORT = "PigeonCall.port";

    public static final String PROVIDER_CALL_SERVER = "PigeonService.client";

    /**
     * 客户端调用标识
     */
    public static final String PROVIDER_CALL_APP = "PigeonService.app";

    public static final String FORK_MESSAGE_ID = "m_forkedMessageId";

    public static final String FORK_ROOT_MESSAGE_ID = "m_rootMessageId";

    public static final String FORK_PARENT_MESSAGE_ID = "m_parentMessageId";

    public static final String INTERFACE_NAME = "interfaceName";

    /**
     * 客户端调用的服务名称 -> 最好是Cat.getManager().getDomain()获取
     */
    public static final String APPLICATION_KEY = "application.name";
}
```

```java
public class CatMsgContext implements Cat.Context {

    private Map<String, String> properties = new HashMap<>();

    @Override
    public void addProperty(String key, String value) {
        properties.put(key, value);
    }

    @Override
    public String getProperty(String key) {
        return properties.get(key);
    }
}

```

### 注意事项

1. 如果Feign集成了Hystrix，会出现上下文参数找不到的情况

> 原因是Hystrix会开启一个子线程去执行Feign请求，但是子线程却获取不到主线程的上下文，这时候需要把主线程上下文带到子线程中去！

解决方法: 

```java
@Component
public class FeignHystrixConcurrencyStrategy extends HystrixConcurrencyStrategy {

    private static final Logger log = LoggerFactory.getLogger(FeignHystrixConcurrencyStrategy.class);
    private HystrixConcurrencyStrategy delegate;

    public FeignHystrixConcurrencyStrategy() {
        try {
            this.delegate = HystrixPlugins.getInstance().getConcurrencyStrategy();
            if (this.delegate instanceof FeignHystrixConcurrencyStrategy) {
                // Welcome to singleton hell...
                return;
            }
            HystrixCommandExecutionHook commandExecutionHook =
                    HystrixPlugins.getInstance().getCommandExecutionHook();
            HystrixEventNotifier eventNotifier = HystrixPlugins.getInstance().getEventNotifier();
            HystrixMetricsPublisher metricsPublisher = HystrixPlugins.getInstance().getMetricsPublisher();
            HystrixPropertiesStrategy propertiesStrategy =
                    HystrixPlugins.getInstance().getPropertiesStrategy();
            this.logCurrentStateOfHystrixPlugins(eventNotifier, metricsPublisher, propertiesStrategy);
            HystrixPlugins.reset();
            HystrixPlugins.getInstance().registerConcurrencyStrategy(this);
            HystrixPlugins.getInstance().registerCommandExecutionHook(commandExecutionHook);
            HystrixPlugins.getInstance().registerEventNotifier(eventNotifier);
            HystrixPlugins.getInstance().registerMetricsPublisher(metricsPublisher);
            HystrixPlugins.getInstance().registerPropertiesStrategy(propertiesStrategy);
        } catch (Exception e) {
            log.error("Failed to register Sleuth Hystrix Concurrency Strategy", e);
        }
    }

    private void logCurrentStateOfHystrixPlugins(HystrixEventNotifier eventNotifier,
                                                 HystrixMetricsPublisher metricsPublisher, HystrixPropertiesStrategy propertiesStrategy) {
        if (log.isDebugEnabled()) {
            log.debug("Current Hystrix plugins configuration is [" + "concurrencyStrategy ["
                    + this.delegate + "]," + "eventNotifier [" + eventNotifier + "]," + "metricPublisher ["
                    + metricsPublisher + "]," + "propertiesStrategy [" + propertiesStrategy + "]," + "]");
            log.debug("Registering Sleuth Hystrix Concurrency Strategy.");
        }
    }

    /**
     * 将当前线程参数传递到要调用的方法中去
     *
     * @param callable
     * @param <T>
     * @return
     */
    @Override
    public <T> Callable<T> wrapCallable(Callable<T> callable) {
        RequestAttributes requestAttributes = RequestContextHolder.getRequestAttributes();
        return new WrappedCallable<>(callable, requestAttributes);
    }

    @Override
    public ThreadPoolExecutor getThreadPool(HystrixThreadPoolKey threadPoolKey,
                                            HystrixProperty<Integer> corePoolSize, HystrixProperty<Integer> maximumPoolSize,
                                            HystrixProperty<Integer> keepAliveTime, TimeUnit unit, BlockingQueue<Runnable> workQueue) {
        return this.delegate.getThreadPool(threadPoolKey, corePoolSize, maximumPoolSize, keepAliveTime,
                unit, workQueue);
    }

//    @Override
//    public ThreadPoolExecutor getThreadPool(HystrixThreadPoolKey threadPoolKey,
//                                            HystrixThreadPoolProperties threadPoolProperties) {
//        return this.delegate.getThreadPool(threadPoolKey, threadPoolProperties);
//    }

    @Override
    public BlockingQueue<Runnable> getBlockingQueue(int maxQueueSize) {
        return this.delegate.getBlockingQueue(maxQueueSize);
    }

    @Override
    public <T> HystrixRequestVariable<T> getRequestVariable(HystrixRequestVariableLifecycle<T> rv) {
        return this.delegate.getRequestVariable(rv);
    }

    static class WrappedCallable<T> implements Callable<T> {
        private final Callable<T> target;
        private final RequestAttributes requestAttributes;

        public WrappedCallable(Callable<T> target, RequestAttributes requestAttributes) {
            this.target = target;
            this.requestAttributes = requestAttributes;
        }

        @Override
        public T call() throws Exception {
            try {
                RequestContextHolder.setRequestAttributes(requestAttributes);
                return target.call();
            } finally {
                RequestContextHolder.resetRequestAttributes();
            }
        }
    }
}
```


其实如果不用Hystrix的话，可以省去AOP那部分，只是因为要把消息对象往下传递。

本人也是刚刚研究这一块，也是给自己做个笔记，以上都是关键代码和思路，有不对的地方请指正，希望能帮助到更多的人。
