# SpringCloud与Dubbo的对比

## 优点

### SpringCloud

- 基于Http的协议JSON传输，宽带消耗大。
- 注册中心只能用Eureka
- 拥有分布式配置中心、消息总线、服务追踪、网关等等。

### dubbo

- 基于二进制[Netty]传输，占用宽带较少，适用于小数据量大并发。

- jar包依赖问题
- 注册中心多种选择

- 服务治理、灰度发布、流量分发做的比SpringCloud好。



![img](https://img-blog.csdn.net/20171127161941661)