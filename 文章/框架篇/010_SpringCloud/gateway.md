# SpringCloud Gateway

## 简介



## 如何使用?

Maven:

```XML
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-gateway</artifactId>
</dependency>
```



## 名词介绍

Route : 路由网关的基本构建块。它由ID，目标URI，谓词集合和过滤器集合定义。如果聚合谓词为真，则匹配路由

**Predicate** : 

Filter



## 流程图

![Spring Cloud Gateway Diagram](https://raw.githubusercontent.com/spring-cloud/spring-cloud-gateway/master/docs/src/main/asciidoc/images/spring_cloud_gateway_diagram.png)



## Route Predicate Factories

Spring Cloud Gateway将路由作为Spring WebFlux `HandlerMapping`基础结构的一部分进行匹配。Spring Cloud Gateway包含许多内置的Route Predicate工厂。所有这些谓词都匹配HTTP请求的不同属性。多路线谓词工厂可以组合并通过逻辑组合。



## 源码阅读

`SpringCloudGateway`是基于`WebFlux`实现。所有的请求均是以WebFlux为核心。

这时候我们来看看它的启动流程。



### 启动

当我们引入spring-cloud-starter-gateway这个包的时候，配置文件中`spring.cloud.gateway.enabled`来开启gateway功能

它是如何运作的?

按照`SpringBoot`的约定通常开启某个功能是@EnableXXX来开启，而这个注解往往都会引入某些配置类来加载到运行容器中达到运行效果。这个是需要手动指定好注解才能被触发。还有一种就是通过spring.factories配置中进行定义配置类，让容器启动的时候默认加载这个配置读取你指定好的配置类，而这种方式一般需要你在配置文件中通过**xxx.xxx.xxx.enable**来做为条件开启某个功能，gateway则是如此。

**spring.factories** 会在运行时候被加载触发。





