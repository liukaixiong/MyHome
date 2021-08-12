# Hystrix 熔断器

## 特性

- 断路器机制

失败数量超过一定比例(默认50%),断路器会切换到开路状态(Open).这时所有请求会直接失败而不会发送到后端服务.断路器保持在开路状态一段时间后(默认5秒),自动切换到半开路状态。这时会判断下一次请求的返回状况，如果请求成功，断路器切回闭路状态

- Fallback

Fallback相当于是降级操作. 对于查询操作, 我们可以实现一个fallback方法, 当请求后端服务出现异常的时候, 可以使用fallback方法返回的值. fallback方法的返回值一般是设置的默认值或者来自缓存. 

- 资源隔离

在Hystrix中, 主要通过线程池来实现资源隔离. 通常在使用的时候我们会根据调用的远程服务划分出多个线程池. 例如调用产品服务的Command放入A线程池, 调用账户服务的Command放入B线程池. 这样做的主要优点是运行环境被隔离开了. 这样就算调用服务的代码存在bug或者由于其他原因导致自己所在线程池被耗尽时, 不会对系统的其他服务造成影响. 但是带来的代价就是维护多个线程池会对系统带来额外的性能开销. 如果是对性能有严格要求而且确信自己调用服务的客户端代码不会出问题的话, 可以使用Hystrix的信号模式(Semaphores)来隔离资源. 

## Feign Hystrix

因为熔断只是作用在服务调用这一端，因此我们根据上一篇的示例代码只需要改动spring-cloud-consumer项目相关代码就可以。因为，Feign中已经依赖了Hystrix所以在maven配置上不用做任何改动。

### 1、配置文件

application.properties添加这一条：

```
feign.hystrix.enabled=true
```

### 2、创建回调类

创建HelloRemoteHystrix类继承与HelloRemote实现回调的方法

```
@Component
public class HelloRemoteHystrix implements HelloRemote{

    @Override
    public String hello(@RequestParam(value = "name") String name) {
        return "hello" +name+", this messge send failed ";
    }
}
```

### 3、添加fallback属性

在`HelloRemote`类添加指定fallback类，在服务熔断的时候返回fallback类中的内容。

```
@FeignClient(name= "spring-cloud-producer",fallback = HelloRemoteHystrix.class)
public interface HelloRemote {

    @RequestMapping(value = "/hello")
    public String hello(@RequestParam(value = "name") String name);

}
```

[参考链接](http://www.ityouknow.com/springcloud/2017/05/16/springcloud-hystrix.html)

## Hystrix Dashboard

Hystrix-dashboard是一款针对Hystrix进行实时监控的工具，通过Hystrix Dashboard我们可以在直观地看到各Hystrix Command的请求响应时间, 请求成功率等数据。但是只使用Hystrix Dashboard的话, 你只能看到单个应用内的服务信息, 这明显不够. 我们需要一个工具能让我们汇总系统内多个服务的数据并显示到Hystrix Dashboard上, 这个工具就是Turbine. 

- 针对hystrix实时监控的工具

  - 请求响应时间
  - 请求成功率

  

## Turbine 

在复杂的分布式系统中，相同服务的节点经常需要部署上百甚至上千个，很多时候，运维人员希望能够把相同服务的节点状态以一个整体集群的形式展现出来，这样可以更好的把握整个系统的状态。 为此，Netflix提供了一个开源项目（Turbine）来提供把多个hystrix.stream的内容聚合为一个数据源供Dashboard展示。 

### 1、添加依赖

```xml
<dependencies>
	<dependency>
		<groupId>org.springframework.cloud</groupId>
		<artifactId>spring-cloud-starter-turbine</artifactId>
	</dependency>
	<dependency>
		<groupId>org.springframework.cloud</groupId>
		<artifactId>spring-cloud-netflix-turbine</artifactId>
	</dependency>
	<dependency>
		<groupId>org.springframework.boot</groupId>
		<artifactId>spring-boot-starter-actuator</artifactId>
	</dependency>
	<dependency>
		<groupId>org.springframework.cloud</groupId>
		<artifactId>spring-cloud-starter-hystrix-dashboard</artifactId>
	</dependency>
</dependencies>
```

### 2、配置文件

```
spring.application.name=hystrix-dashboard-turbine
server.port=8001
turbine.appConfig=node01,node02
turbine.aggregator.clusterConfig= default
turbine.clusterNameExpression= new String("default")

eureka.client.serviceUrl.defaultZone=http://localhost:8000/eureka/
```

- `turbine.appConfig` ：配置Eureka中的serviceId列表，表明监控哪些服务
- `turbine.aggregator.clusterConfig` ：指定聚合哪些集群，多个使用”,”分割，默认为default。可使用`http://.../turbine.stream?cluster={clusterConfig之一}`访问
- `turbine.clusterNameExpression` ： 1. clusterNameExpression指定集群名称，默认表达式appName；此时：`turbine.aggregator.clusterConfig`需要配置想要监控的应用名称；2. 当clusterNameExpression: default时，`turbine.aggregator.clusterConfig`可以不写，因为默认就是default；3. 当clusterNameExpression: metadata[‘cluster’]时，假设想要监控的应用配置了`eureka.instance.metadata-map.cluster: ABC`，则需要配置，同时`turbine.aggregator.clusterConfig: ABC`

### 3、启动类

启动类添加`@EnableTurbine`，激活对Turbine的支持

```java
@SpringBootApplication
@EnableHystrixDashboard
@EnableTurbine
public class DashboardApplication {

	public static void main(String[] args) {
		SpringApplication.run(DashboardApplication.class, args);
	}

}
```

## Hystrix 集成 RestTemplate



构建一个拦截器

```java

import com.netflix.hystrix.HystrixCommand;
import com.netflix.hystrix.HystrixCommandGroupKey;
import com.netflix.hystrix.HystrixCommandProperties;
import com.netflix.hystrix.HystrixThreadPoolProperties;
import org.springframework.beans.BeansException;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.context.ApplicationContext;
import org.springframework.context.ApplicationContextAware;
import org.springframework.http.HttpRequest;
import org.springframework.http.client.ClientHttpRequestExecution;
import org.springframework.http.client.ClientHttpRequestInterceptor;
import org.springframework.http.client.ClientHttpResponse;

import java.io.IOException;
import java.net.URI;
import java.util.HashMap;
import java.util.Map;

public class HystrixRestInterceptor implements ClientHttpRequestInterceptor, ApplicationContextAware, InitializingBean {

    private Integer timeOut = 3000;

    private ApplicationContext applicationContext;

    private Map<String, RestTemplateFallback> restTemplateFallbackMap;

    @Override
    public ClientHttpResponse intercept(HttpRequest request, byte[] body, ClientHttpRequestExecution execution)
        throws IOException {
        final URI originalUri = request.getURI();
        // todo 参数配置化
        HystrixCommandGroupKey hystrixCommandGroupKey = HystrixCommandGroupKey.Factory.asKey(originalUri.toString());

        HystrixCommandProperties.Setter propertiesSetter = HystrixCommandProperties.Setter()
            .withExecutionIsolationStrategy(HystrixCommandProperties.ExecutionIsolationStrategy.THREAD)
            .withExecutionTimeoutInMilliseconds(this.timeOut).withCircuitBreakerEnabled(true) // 开启熔断功能
            .withCircuitBreakerErrorThresholdPercentage(50).withCircuitBreakerRequestVolumeThreshold(5) // 默认的请求样本参数
            .withCircuitBreakerSleepWindowInMilliseconds(5000) // 熔断后的间隔重试时间
            .withExecutionIsolationThreadInterruptOnTimeout(true);// 错误率达到多少开始熔断

        HystrixThreadPoolProperties.Setter threadPoolProperties = HystrixThreadPoolProperties.Setter();

        threadPoolProperties.withCoreSize(8).withMaxQueueSize(100).withMaximumSize(20)
            .withAllowMaximumSizeToDivergeFromCoreSize(true).withMetricsRollingStatisticalWindowBuckets(5)
            .withMetricsRollingStatisticalWindowInMilliseconds(30).withKeepAliveTimeMinutes(10);

        HystrixCommand.Setter setter = HystrixCommand.Setter.withGroupKey(hystrixCommandGroupKey);
        setter.andCommandPropertiesDefaults(propertiesSetter);
        setter.andThreadPoolPropertiesDefaults(threadPoolProperties);
        return new RestHystrixCommand(setter, restTemplateFallbackMap, request, body, execution).execute();
    }

    @Override
    public void setApplicationContext(ApplicationContext applicationContext) throws BeansException {
        this.applicationContext = applicationContext;
    }

    @Override
    public void afterPropertiesSet() throws Exception {
        restTemplateFallbackMap = new HashMap<>();
        Map<String, RestTemplateFallback> fallbackBeansOfTypeMap =
            this.applicationContext.getBeansOfType(RestTemplateFallback.class);
        if (fallbackBeansOfTypeMap != null || fallbackBeansOfTypeMap.size() > 0) {
            fallbackBeansOfTypeMap.forEach((K, V) -> {
                String url = V.url();
                restTemplateFallbackMap.put(url, V);
            });
        }
    }

    public void setTimeOut(Integer timeOut) {
        this.timeOut = timeOut;
    }
}
```

构建Hystrix的执行器

```java

import com.netflix.hystrix.HystrixCommand;
import com.netflix.hystrix.HystrixCommandGroupKey;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.ApplicationContext;
import org.springframework.http.HttpRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.client.ClientHttpRequestExecution;
import org.springframework.http.client.ClientHttpResponse;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.HttpServerErrorException;

import java.io.IOException;
import java.util.Map;

public class RestHystrixCommand extends HystrixCommand<ClientHttpResponse> {
    private Logger logger = LoggerFactory.getLogger(getClass());
    private ClientHttpRequestExecution execution;
    private HttpRequest request;
    private byte[] body;
    private volatile ClientHttpResponse response;
    private Map<String, RestTemplateFallback> restTemplateFallbackMap;

    protected RestHystrixCommand(Setter setter, Map<String, RestTemplateFallback> restTemplateFallbackMap,
        HttpRequest request, byte[] body, ClientHttpRequestExecution execution) {
        super(setter);
        this.execution = execution;
        this.request = request;
        this.body = body;
        this.restTemplateFallbackMap = restTemplateFallbackMap;
    }

    @Override
    protected ClientHttpResponse run() throws Exception {
        String url = this.request.getURI().toString();
        // 这里是基本不会报错的，但是可以通过状态码来标识请求的成功还是失败
        ClientHttpResponse execute = this.execution.execute(request, body);
        if (execute.getStatusCode() != HttpStatus.OK && restTemplateFallbackMap.get(url) != null) {
            response = execute;
            logger.warn("异常状态码: " + execute.getStatusCode());
            throw new HttpServerErrorException(execute.getStatusCode());
        }
        logger.warn("url : " + url + " 状态成功..");
        return execute;
    }

    @Override
    protected ClientHttpResponse getFallback() {

        // 这里可能触发的条件: 1. 异常 \ 超时
        String url = this.request.getURI().toString();

        try {
            logger.warn("触发失败回调...." + url);

            RestTemplateFallback restTemplateFallback = restTemplateFallbackMap.get(url);

            if (restTemplateFallback == null) {

                restTemplateFallback = new RestTemplateFallback<Object>() {
                    @Override
                    public String url() {
                        return null;
                    }

                    @Override
                    public Object invoke(HttpRequest httpRequest, String body) {
                        return "触发了默认的失败回调接口 : " + httpRequest.getURI().toString();
                    }
                };
                return new FallbackClientHttpResponse(restTemplateFallback.invoke(request, new String(body)));
            } else {
                Object result = restTemplateFallback.invoke(request, new String(body));
                return new FallbackClientHttpResponse(result);
            }
        } catch (Exception e) {
            logger.error("第三方调用失败回调失败", e);
        }

        return null;
    }
}
```

失败回调的接口类:

```java

import org.springframework.http.HttpRequest;

/**
 * 第三方调用，失败回调接口
 *
 * @param <RS>
 */
public interface RestTemplateFallback<RS> {

    /**
     * 请求第三方的URL标识
     *
     * @return
     */
    String url();

    /**
     * 回调的方法，会先根据url()方法判断是否匹配,再执行invoke方法
     *
     * @param httpRequest
     * @param body
     * @return
     */
    RS invoke(HttpRequest httpRequest, String body);

}

```

`RestTemplate`的返回结果包装

```java
import com.alibaba.fastjson.JSON;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.client.AbstractClientHttpResponse;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;

public class FallbackClientHttpResponse extends AbstractClientHttpResponse {

    private Object object;

    public FallbackClientHttpResponse(Object object) {
        this.object = object;
    }

    @Override
    public int getRawStatusCode() throws IOException {
        return HttpStatus.OK.value();
    }

    @Override
    public String getStatusText() throws IOException {
        return null;
    }

    @Override
    public void close() {

    }

    @Override
    public InputStream getBody() throws IOException {
        if (object instanceof InputStream) {
            return (InputStream)object;
        }
        byte[] bytes = JSON.toJSONBytes(object);
        return new ByteArrayInputStream(bytes);
    }

    @Override
    public HttpHeaders getHeaders() {
        HttpHeaders httpHeaders = new HttpHeaders();
        httpHeaders.add("fallback", "true");
        return httpHeaders;
    }
}
```

# hystrix 源码解析

目标类: `com.netflix.hystrix.AbstractCommand#AbstractCommand`

定义顶层逻辑，负责主流程的运转

|      | 描述          |      | 接口 |      |                             |      | 实现                              |      | 加载方式 |      |
| ---- | ------------- | ---- | ---- | ---- | :-------------------------- | ---- | --------------------------------- | ---- | -------- | ---- |
|      | 配置          |      |      |      |                             |      | HystrixCommandProperties          |      |          |      |
|      | 监控指标      |      |      |      |                             |      | HystrixCommandMetrics             |      |          |      |
|      | 熔断器        |      |      |      | HystrixCircuitBreaker       |      | HystrixCircuitBreakerImpl         |      |          |      |
|      | 线程池定义    |      |      |      | HystrixThreadPool           |      | HystrixThreadPoolDefault          |      |          |      |
|      | 并发策略      |      |      |      | HystrixConcurrencyStrategy  |      | HystrixConcurrencyStrategyDefault |      |          |      |
|      | 执行发布      |      |      |      | HystrixCommandExecutionHook |      | HystrixCommandExecutionHook       |      |          |      |
|      | 请求缓存\合并 |      |      |      |                             |      | HystrixRequestCache               |      |          |      |
|      | 请求日志      |      |      |      |                             |      | HystrixRequestLog                 |      |          |      |
|      |               |      |      |      |                             |      |                                   |      |          |      |

目标类: `com.netflix.hystrix.HystrixCommand`

负责执行具体的逻辑，继承了AbstractCommand拥有了大量组件模版的能力,实现了`HystrixExecutable`，负责调用调度执行AbstractCommand 所提供的功能，其中暴露了两个核心的方法：

- run() :  负责执行具体的业务执行器，负责拿到业务中的结果调用，过程中产生的超时、异常等等因素将交由hystrix接管。
- getFallback() :  当超时、异常产生时，会交给客户端调用实际的方法。



所有的初始化的工作都在`com.netflix.hystrix.AbstractCommand#AbstractCommand`中完成



**rxjava**的流程构建则在`com.netflix.hystrix.AbstractCommand#toObservable`中

