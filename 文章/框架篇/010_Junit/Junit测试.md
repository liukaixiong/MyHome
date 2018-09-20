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

## 并发测试

`pom.xml`

```
 <dependency>
     <groupId>org.databene</groupId>
     <artifactId>contiperf</artifactId>
     <version>2.3.4</version>
     <scope>test</scope>
 </dependency>
```

`java`

```java

@Rule 
public ContiPerfRule i = new ContiPerfRule(); 


	@Test
    @PerfTest(invocations = 10000,threads = 10)
    @Required(throughput = 1000,max = 1000)
    public void insert() throws Exception {
        rule.apply()
        TTest test = new TTest();
        test.setName("某某某");
        test.setSex("男");
        test.setStatus("1");
        test.setUsername("测试的啊");
        int insert = testService.insert(test);
    }

```

测试结果可从控制台上查看，也可以在target中的contiperf-report查看页面描述



### 参数介绍

#### PerfTest参数

@PerfTest(invocations = 300)：执行300次，和线程数量无关，默认值为1，表示执行1次；

@PerfTest(threads=30)：并发执行30个线程，默认值为1个线程；

@PerfTest(duration = 20000)：重复地执行测试至少执行20s。

#### Required参数

@Required(throughput = 20)：要求每秒至少执行20个测试；

@Required(average = 50)：要求平均执行时间不超过50ms；

@Required(median = 45)：要求所有执行的50%不超过45ms； 

@Required(max = 2000)：要求没有测试超过2s；

@Required(totalTime = 5000)：要求总的执行时间不超过5s；

@Required(percentile90 = 3000)：要求90%的测试不超过3s；

@Required(percentile95 = 5000)：要求95%的测试不超过5s； 

@Required(percentile99 = 10000)：要求99%的测试不超过10s; 

@Required(percentiles = "66:200,96:500")：要求66%的测试不超过200ms，96%的测试不超过500ms。

##  参数模拟

[jmockdata](https://github.com/jsonzou/jmockdata)

```
<dependency>
    <groupId>ma.glasnost.orika</groupId>
    <artifactId>orika-core</artifactId>
    <version>1.5.2</version>
</dependency>
```

```java
int intNum = JMockData.mock(int.class);
int[] intArray = JMockData.mock(int[].class);
Integer integer = JMockData.mock(Integer.class);
Integer[] integerArray = JMockData.mock(Integer[].class);
BigDecimal bigDecimal = JMockData.mock(BigDecimal.class);
BigInteger bigInteger = JMockData.mock(BigInteger.class);
Date date = JMockData.mock(Date.class);
String str = JMockData.mock(String.class);
```

