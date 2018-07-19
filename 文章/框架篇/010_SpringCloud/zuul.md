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

## 核心组件

#### 入口类

- ZuulFilter : 启动类，用于zuul容器初始化触发的入口类.这里面包含了 pre、route、post等三种生命周期的定义



- ZuulServlet : 过滤器,用于来接受请求，并且在该类中定义了preRoute、route、postRoute等三种请求流转
  - FilterProcessor : 过滤器的处理器