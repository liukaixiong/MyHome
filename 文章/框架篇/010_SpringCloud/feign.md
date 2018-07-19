#  Feign启动过程

## 主要方法

### client 

接口 : `Client`

客户端调用

### logLevel

日志级别定义

### logger

日志使用类

### contract

针对feign的一些注解进行解析，可以自定义注解

### decode404

是否需要解析404的情况。

### decoder

参数解码器 - 针对出参

### mapAndDecode

参数解码前的装饰器模式

### errorDecoder

针对异常出参做的处理器

### encoder

参数编码器 - 针对入参

### options

参数设置 : 

- connectTimeoutMillis : 连接超时时间(默认10秒)
- readTimeoutMillis : 读取超时时间(默认60秒)

### invocationHandlerFactory

方法执行工厂。

针对feign方法调用的时候会触发的invoke方法。

详情参考:DefaultMethodHandler、SynchronousMethodHandler

### requestInterceptor

请求拦截器、用于拦截feign请求

详情参考:`BasicAuthRequestInterceptor`

### retryer

失败尝试接口 - Retryer

- maxAttempts : 最大尝试次数（默认1次）
- maxPeriod : 尝试时间 (1秒) 
- period : 间隔递增时间(默认按照1.5倍递增)

## 配置方式

```java
@Bean
public Logger.Level feignLevel() {
    return Logger.Level.BASIC;
}
```



# Hystrix 集成

## 注册类

`HystrixFeign` : 

具体注册时机 : HystrixFeignConfiguration