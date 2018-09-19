# SpringBoot测试

1. 导入jar包

```xml
 <dependency>
     <groupId>org.springframework.boot</groupId>
     <artifactId>spring-boot-starter-test</artifactId>
</dependency>
```

```java

// 导入spring的启动类
@RunWith(SpringRunner.class)
@SpringBootTest(classes = GatewayServerApplication.class)


// springboot的环境就搭建好了

// 注入其他的类
@Autowire



```

