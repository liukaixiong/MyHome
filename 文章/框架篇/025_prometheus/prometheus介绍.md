---
typora-copy-images-to: ..\..\..\image\wz_img
---



## 下载

Prometheus安装包 : https://prometheus.io/download/

exporter 安装包 : <https://github.com/prometheus> 这里可以找到很多exporter 

[Prometheus - dashboards](https://github.com/percona/grafana-dashboards/tree/master/dashboards)

- [总网站](https://prometheus.io/download/)

# 启动

配置文件 : `prometheus.yml`

```yaml
global:
  scrape_interval:     15s # 默认情况下，每15秒刮一次目标。

  # 在与之通信时，将这些标签附加到任何时间序列或警报
  # 外部系统,需要集成
  external_labels:
    monitor: 'codelab-monitor'

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # 监控的任务名称
  - job_name: 'prometheus'

    # 每5秒覆盖一次
    scrape_interval: 5s

    static_configs:
      - targets: ['localhost:9090']
```



# 框架集成

## mysql集成

[源码地址](https://github.com/prometheus/mysqld_exporter)

[编译好的下载最新地址](https://prometheus.io/download/)

> 之前一直理解错了，一直在mysql那台服务器上一直做测试，结果一直没测通。后面发现不一定要在装有mysql的机器上跑脚本，其他服务器上也是可以的。

1. 创建一个.my.cnf文件，**在这之前可能需要你创建一个可用的账户**

```tex
cat << EOF > .my.cnf
[client]
user=帐号
password=密码
host=mysql的ip地址
EOF
```

关于my.cnf的参数可以参考 [**mysqld_exporter_test.go** ](https://github.com/prometheus/mysqld_exporter/blob/33b5df207347168fb336ffab509b8750e8699bba/mysqld_exporter_test.go)

2. 修改`prometheus.yml`文件

```yaml
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  - job_name: 'prometheus'

    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.

    static_configs:
    - targets: ['localhost:9090']
  - job_name: mysql
    static_configs:
    - targets: ['192.168.0.17:9104'] # 这里就是启动的监听mysql地址
      labels:
        instance: db1

```

3. 启动脚本

```tex
./mysqld_exporter --config.my-cnf=".my.cnf"  
```

## 安装node_exporter 

[下载地址 - 找到node_exporter](https://prometheus.io/download/#node_exporter)

解压之后直接重启就OK了

`prometheus.yml` 

```yaml
scrape_configs:
  - job_name: node
    static_configs:
    - targets: ['localhost:9104'] # node_exporter监听的访问地址
```

**这时候Prometheus应该正确启动了，如果报错，请检查配置文件。（注意：yml格式是对缩进有要求的。）** 

> **Prometheus默认是有多少个CPU内核就使用多少OS线程，主要是由GOMAXPROCS 这个环境变量控制的，开发GO的应该都清楚。一般默认就好了，太高的话可能会带来意想不到的后果。Prometheus默认大概会占用3G左右的内存，如果想调小一点，得修改配置文件，或者添加启动参数。** 

## grafana部署

[linux下载地址](https://grafana.com/grafana/download?platform=linux)

1. 下载之后,解压
2. 启动

```tex
./grafana-server
```

3. 访问页面http://localhost:3000 ，默认账号、密码admin/admin

- ![创建数据源](D:\github\MyHome\image\wz_img\1531291972314.png) 



- 这里需要注意的是Name最好和Type保持一致

![1531292042229](D:\github\MyHome\image\wz_img\1531292042229.png)

- 然后到 [grafana-dashboards](https://github.com/percona/grafana-dashboards)项目中去找对应的json文件,文件目录在`dashboards`下,找到了之后,然后上传上去即可

![1531292185897](D:\github\MyHome\image\wz_img\1531292185897.png)

![1531292195355](D:\github\MyHome\image\wz_img\1531292195355.png)

最后在右上角即可显示出来对应的监控

![1531292233941](D:\github\MyHome\image\wz_img\1531292233941.png)

[具体参考](https://blog.csdn.net/wangshuminjava/article/details/80787209)



### 模版查找

![1531466711579](D:\github\MyHome\image\wz_img\1531466711579.png)



![1531466899032](D:\github\MyHome\image\wz_img\1531466899032.png)

![1531466979072](D:\github\MyHome\image\wz_img\1531466979072.png)

这里可以复制`dashboard`消息编号，然后重新导入

![1531467026234](D:\github\MyHome\image\wz_img\1531467026234.png)

![1531467075735](D:\github\MyHome\image\wz_img\1531467075735.png)

然后就会直接跳转到

![1531467115469](D:\github\MyHome\image\wz_img\1531467115469.png)

- 填好你自己要命名的名字
- 选择数据源
- 导入

![1531467159169](D:\github\MyHome\image\wz_img\1531467159169.png)

这里需要注意的是，这个模版所对应的参数存在不一致的情况，可能需要自己根据实际情况调整。

这里的调整涉及到Prometheus的数据传输。

我这边了解到的两种:

[网关传输](https://prometheus.io/download/#pushgateway) : 这里的话，就是通过网关传输，不过需要服务端搭建环境，环境搭建非常简单，下载下来之后，直接运行就OK了，然后访问http://localhost:9091/#

**[UDP - Stats D传输](https://prometheus.io/download/#statsd_exporter)**: 这里的传输方式是通过管道传输，这里的话和上面差不多，下载下来之后，直接运行。然后访问：http://localhost:9102/metrics



**上面两种的话都需要客户端支持。**

```xml
<dependency>
    <groupId>io.prometheus</groupId>
    <artifactId>simpleclient_spring_boot</artifactId>
    <version>0.4.1-SNAPSHOT</version>
</dependency>
```

**simpleclient_spring_boot** : spring-boot相关的配置类配置

simpleclient_hotspot : JVM相关的参数统计

- ThreadExports : jvm线程相关
  - jvm_threads_current
  - jvm_threads_daemon
  - jvm_threads_peak
  - jvm_threads_started_total
  - jvm_threads_deadlocked
  - jvm_threads_deadlocked_monitor
  - jvm_threads_state
- VersionInfoExports : jvm 版本相关，默认没开启
  - jvm_info
  - java.runtime.version

```xml
<dependency>
    <groupId>io.github.mweirauch</groupId>
    <artifactId>micrometer-jvm-extras</artifactId>
    <version>0.1.3-SNAPSHOT</version>
</dependency>
```

`ProcessMemoryMetrics` : 收集以`process.memory.`开头的参数

`ProcessThreadMetrics` : 收集以`process.threads`开头的参数

```xml
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-core</artifactId>
    <version>1.0.5</version>
</dependency>
 <dependency>
     <groupId>io.micrometer</groupId>
     <artifactId>micrometer-spring-legacy</artifactId>
     <version>1.0.5</version>
</dependency>
<!-- 这里面是将所有参数与监控图表的参数做了匹配 -->
 <dependency>
     <groupId>io.micrometer</groupId>
     <artifactId>micrometer-registry-prometheus</artifactId>
     <version>1.0.5</version>
</dependency>
```

开启配置:

```yaml
management:
  metrics:
    export:
      prometheus:
        enabled: true
        pushgateway:
          enabled: true
          base-url: 192.168.0.17:9091
          job: test
        descriptions: true
```



启动类:

- MeterBindersConfiguration:
  - management.metrics.binders.jvm.enabled
    - JvmGcMetrics
      - jvm.gc.max.data.size
        - 旧一代内存池的最大大小
      - jvm.gc.live.data.size
        - 完整GC后的旧代内存池的大小
      - jvm.gc.memory.promoted
        - GC之前到GC之后的旧代内存池大小的正增加计数
      - jvm.gc.memory.allocated
        - 增加一个GC到下一个GC之后年轻代内存池的大小增加
      - jvm.gc.concurrent.phase.time
        - 在并发阶段花费的时间
      - jvm.gc.pause
        - 在GC暂停中花费的时间
  - management.metrics.binders.jvm.enabled
    - JvmMemoryMetrics:
      - jvm.buffer.count
      - jvm.buffer.memory.used
      - jvm.buffer.total.capacity
      - jvm.memory.used
      - jvm.memory.committed
      - jvm.memory.max
  - management.metrics.binders.jvm.enabled
    - JvmThreadMetrics
      - jvm.threads.peak
        - 自Java虚拟机启动或峰值重置以来的最高活动线程数
      - jvm.threads.daemon
        - 当前活动守护程序线程的数量
      - jvm.threads.live
        - 当前线程数，包括守护程序和非守护程序线程
  - management.metrics.binders.jvm.enabled
    - ClassLoaderMetrics
      - jvm.classes.loaded
        - 当前在Java虚拟机中加载的类的数量
      - jvm.classes.unloaded
        - 自Java虚拟机开始执行以来卸载的类总数
  - management.metrics.binders.logback.enabled
    - LogbackMetrics
      - logback.events
        - level
          - error
          - debug
          - info
          - warn
          - trace
  - management.metrics.binders.uptime.enabled
    - UptimeMetrics
      - process.uptime
        - Java虚拟机的正常运行时间
      - process.start.time
        - Java虚拟机的开始时间
  - management.metrics.binders.processor.enabled
    - ProcessorMetrics
      - system.cpu.count
        - Java虚拟机可用的处理器数
      - system.load.average.1m
        - 系统每分钟运行在处理器上的负载值
      - system.cpu.usage
        - 整个系统的“最近cpu使用率”
      - process.cpu.usage
        - Java虚拟机进程的“最近的cpu使用情况”
- TomcatMetricsConfiguration
  - TomcatMetrics
    - tomcat.global.sent
    - tomcat.global.received
    - tomcat.global.error
    - tomcat.global.request
    - tomcat.global.request.max
    - tomcat.servlet.error
    - tomcat.servlet.request
    - tomcat.servlet.request.max
    - tomcat.cache.access
    - tomcat.cache.hit
    - tomcat.threads.config.max
    - tomcat.threads.busy
    - tomcat.threads.current
    - tomcat.sessions.active.max
    - tomcat.sessions.active.current
    - tomcat.sessions.created
    - tomcat.sessions.expired
    - tomcat.sessions.rejected
    - tomcat.sessions.alive.max
- StatsdMetricsExportAutoConfiguration
  - StatsdMetrics
    - statsd.queue.size
      - 排队等待通过UDP传输的StatsD事件总数
    - statsd.queue.capacity
      - 可以排队等待传输的最大StatsD事件数
- RegistrationApplicationListener
  - spring.boot.admin
    - http.client.requests

```xml
<!-- 将数据通过UDP上传到statsd中去 -->
<dependency>
     <groupId>io.micrometer</groupId>
     <artifactId>micrometer-registry-statsd</artifactId>
     <version>1.0.5</version>
</dependency>
```

statsd方法是将数据上传到statsd中去

```yaml
management:
  metrics:
    statsd:
      enabled: true
        host: 192.168.0.17 # 具体statsd地址
        port: 9125
        flavor: datadog
```

另外可能需要一些依赖的jar:

```xml
 <!-- https://mvnrepository.com/artifact/org.pcollections/pcollections -->
<dependency>
    <groupId>org.pcollections</groupId>
    <artifactId>pcollections</artifactId>
    <version>3.0.2</version>
</dependency>
<!-- https://mvnrepository.com/artifact/org.reactivestreams/reactive-streams -->
<dependency>
    <groupId>org.reactivestreams</groupId>
    <artifactId>reactive-streams</artifactId>
    <version>1.0.2</version>
</dependency>
<!-- https://mvnrepository.com/artifact/io.projectreactor/reactor-core -->
<dependency>
    <groupId>io.projectreactor</groupId>
    <artifactId>reactor-core</artifactId>
    <version>3.1.8.RELEASE</version>
</dependency>
<dependency>
    <groupId>io.projectreactor.ipc</groupId>
    <artifactId>reactor-netty</artifactId>
    <version>0.7.8.RELEASE</version>
</dependency>
```



### 监控java线程池

使用`ExecutorServiceMetrics`将创建的线程池放进去







##### 使用记录

- status=~\"5..\" 数字模糊匹配







## Spring-boot集成

pom.xml

```xml
<dependency>
    <groupId>io.prometheus</groupId>
    <artifactId>simpleclient_spring_boot</artifactId>
    <version>0.4.1-SNAPSHOT</version>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

启动类

```java
@SpringBootApplication
@EnablePrometheusEndpoint
@EnableSpringBootMetricsCollector
public class ActuatorApplication {

	public static void main(String[] args) {
		SpringApplication.run(ActuatorApplication.class, args);
	}
}
```

application.yml

```yaml
scrape_configs:
	# 当前机器的监控情况配置
  - job_name: prometheus
    scrape_interval: 5s
    scrape_timeout: 5s
    metrics_path: /metrics
    scheme: http
    static_configs:
      - targets:
        - 192.168.0.17:9090
	# 当前应用的监控情况配置
  - job_name: spring-boot-actuator-test
    scrape_interval: 5s
    scrape_timeout: 5s
    metrics_path: /prometheus
    scheme: http
    basic_auth:
      username: lzmh
      password: lzmh
    static_configs:
      - targets:
        - localhost:8080  #此处填写 Spring Boot 应用的 IP + 端口号
```

测试spring-boot启动访问路径

- http://localhost:8088/monitor/prometheus
- http://localhost:8088/monitor/metrics

prometheus配置`prometheus.yml` 把该服务的地址配置进去

```yaml
# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  - job_name: 'prometheus'

    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.

    static_configs:
    - targets: ['localhost:9090']

  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  - job_name: 'spring-boot-service'

    # metrics_path defaults to '/metrics'
    # metrics_path: /actuator/metrics
    metrics_path: /monitor/prometheus
    # scheme defaults to 'http'.

    static_configs:
        - targets: ['localhost:8762']
```

[参考案例](https://blog.csdn.net/zl1zl2zl3/article/details/75045005)

### 网关集成

[网关下载地址](https://prometheus.io/download/#pushgateway)

`MeterBinder`



监控网址记录

[micrometer 官网](https://micrometer.io/docs)

[micrometer github](https://github.com/micrometer-metrics/micrometer)

(process_memory_pss{application="boot-server", instance="statsd-data"} + process_memory_swap{application="boot-server", instance="statsd-data"}  - on(application,instance) sum(jvm_memory_committed{application="boot-server", instance="statsd-data"})  by(application,instance)) >= 0

## Alter 报警

[Alter-manage-下载](https://prometheus.io/download/#alertmanager)

下载完成之后，启动。 默认访问端口：localhost:9093

1. webhook_configs 配置第三方的发送请求

```yaml
# 全局配置
global:
  # 解析超时时间设置
  resolve_timeout: 5m

# 路由设置
route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'web.hook'
# 接收器设置
receivers:
- name: 'web.hook'
  webhook_configs:
  # 这里设置你的邮件服务，需要注意的是这里需要根据Alter定义的数据做处理
  - url: 'http://192.168.0.16:8080/msg'
inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'dev', 'instance']
```

2. prometheus.yml配置，这里需要将报警模块和Prometheus集成

```yaml
alerting:
  alertmanagers:
  - static_configs:
  	# 报警模块地址
    - targets: ['localhost:9093']
rule_files:
  # 这里是报警的规则文件
  - "/usr/local/software/prometheus/prometheus-2.3.1.linux-amd64/rule/rules.yml"
```

**rules.yml**

```yaml
groups:
- name: test-rule
  rules:
  # 报警名称
  - alert: errorCount
  	# 匹配规则，这里所指的意思是http_server_requests_seconds_count数据的总数达到80的情况下，触发报警
    expr: http_server_requests_seconds_count{application="boot-server-local",exception="ArithmeticException",instance="statsd-data",method="GET",status="500",uri="/error0"} > 80
    # 多少时间确认一次，这里的状态会有两次变化,分别是resolved、firing
    for: 10s
    labels:
      team: node
    annotations:
      summary: "{{$labels.instance}}: High CPU usage detected"
      description: "{{$labels.instance}}: error count  80% (current value is: {{ $value }}"

```

配置完成之后，

![1531732907669](D:\github\MyHome\image\wz_img\1531732907669.png)

然后根据根据指定的规则当数据达到规则设定的之后，则会触发邮件的回调。

# 插件

[JVM (Micrometer)插件](https://grafana.com/dashboards/4701)

[Spring Boot Statistics ](https://grafana.com/dashboards/6756)

