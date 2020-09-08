相关链接地址 : [架构解析](https://blog.csdn.net/caohao0591/article/details/80207806)

## 部署步骤

1. 下载源码

   ```
   https://github.com/dianping/cat.git
   ```

2. 编译源码

   ```tex
   1. 在CAT目录下，用maven构建项目
   > mvn clean install -DskipTests
   2. 配置CAT环境
   > mvn cat:install
   ```

3. 构建环境

   1. 启动单机版

      - 检查下/data/appdatas/cat/ 下面需要的几个配置文件，配置文件在源码script 。

      - 在cat目录下执行 mvn install -DskipTests 。

      - ##### 配置CAT的运行需要配置信息

        `mvn cat:install`

      - 进入cat-home目录下,启动自带的Jetty容器

      - mvn jetty:run

      - 

   2. 环境部署

      1. linux可以参考cat/框架埋点方案集成/Dianping CAT 安装说明文档.md

   3. 注意查看文档

      1. **cat/Dianping CAT 配置加载说明.md**
      2. **Cat技术入门总结-0.1.0.doc**

   4. 客户端集成

      1. 一定要将CAT部署完的包全部上传到本地manve私服上面去

         `cat/pom.xml`

      ```xml
       <distributionManagement>
      	   <repository>
      		   <id>releases</id>
      		   <name>Nexus Release Repository</name>
      		   <url>资源地址</url>
      	   </repository>
            <!--<snapshotRepository>-->
               <!--<id>snapshots</id>-->
               <!--<url>${snapshots.repo}</url>-->
            <!--</snapshotRepository>-->
         </distributionManagement>
      ```

      	执行:`mvn clean package deploy -Dmaven.test.skip=true`

      2. 客户端的服务

         1. `META-INF/app.properties` 里面`app.name=cat-demo`
         2. pom.xml

         ```xml
          <dependency>
            <groupId>com.dianping.cat</groupId>
            <artifactId>cat-core</artifactId>
            <version>2.0.0</version>
         </dependency>
         ```

   5. 源码集成

      1. 进入https://github.com/dianping/cat/tree/mvn-repo地址
      2. 下载下来并且放入到本地Maven私服中
      3. 注释掉不存在的maven引用

      ```xml
      <!--<dependency>-->
        <!--<groupId>com.dianping.cat</groupId>-->
        <!--<artifactId>cat-consumer-advanced</artifactId>-->
        <!--<version>${project.version}</version>-->
      <!--</dependency>-->
      ```

      4. 启动jetty	

   6. 邮件发送

      1. 配置 - 登录 - 应用监控配置 - 异常报警配置 - 配置好你的项目名称 - 异常名称为 Total
      2. 全局告警配置 - 默认告警人 - 配置你的邮件 , 如果有多个以","分割
      3. 如果需要修改点击弹到你的默认页面请修改 : resources/freemaker/`exceptionAlert.ftl`和 `thirdpartyAlert.ftl`两个模版内容

   7. 与dubbo的总结

      [dubbo的消息树构建](https://github.com/dubboclub/dubbo-plus)

## 功能

### 报表模块(Heartbeat)

##### System Info  : `free -m` || `top -Hp 进程号` 查看

LoadAverage : 负荷平均值 (top -Hp 进程号查看)

FreePhysicalMemory : 可用的物理内存

FreeSwapSpaceSize : 已经使用的物理内存大小

##### GC Info (jstat -gccause 30544 60000 查看)

PS ScavengeCount  : 新生代回收次数

PS ScavengeTime  : 新生代回收时间

PS MarkSweepCount : fullGC次数

PS MarkSweepTime ：fullGC时间

##### JVMHeap Info

Code Cache : 代码的缓存大小

Metaspace : 

Compressed Class Space  :  压缩的类空间大小

PS Eden Space  : 新生代总空间

PS Survivor Space  : s块的空间使用情况

PS Old Gen : 已经使用的老年代大小

##### FrameworkThread Info

HttpThread  : http线程数

PigeonThread :

ActiveThread : 活跃的线程数

CatThread : 

StartedThread : 已经使用过的线程数

##### Disk Info




## 错误介绍

1. 调整CAT的`plexus/components-cat-client.xml`文件修改消息类型的时候将`com.dianping.cat.message.MessageProducer`的实现类`implementation`的路径写错了,导致服务器爆出的异常为`Unable to get instance of MessageManager, please make sure the environment was setup correctly`。这个异常比较麻烦的就是本地不会出现,但是服务器有可能会出现!!!!!


   	**非常有可能是jar包加载顺序的问题**

2. Netty write buffer is full  || Could not load META-INF/services/javax.xml.parsers.SAXParserFactory

   **如果出现非常多的话**-> **如果是tomcat部署的话一定要记得查看是否是不是停止的时候进程没有删完毕** [ **ps -ef|grep tomcat** ] + **是不是端口出现了问题，比如端口是2281写成了2181 也是会出问题的。**

3. 如果使用IDEA并且内置自己的tomcat的时候，**LogViews**出现乱码：

   1. VM options : -Dfile.encoding=UTF-8   // 设置编码格式
   2. 另外D:\dev\IntelliJ IDEA 2018.1.3\bin\idea.exe.vmoptions 最后一行加入 : -Dfile.encoding=UTF-8

4. 单机 - 版本升级到3.0的时候，发现历史报表无法显示内容？

   1. 首先进入cat管理后台的config - 全局系统配置 - 服务端配置 - 然后更新 job-machine = true 。

   2. 这里需要了解一点:

      1. CAT在选择task任务机的时候会判断上面的属性是否为true，如果为true表示这条机器是报告工作机

      2. 报告机的特点就是会在启动的时候创建一个独立的任务消费线程去处理。代码在CatHomeModule.execute中

         ```java
         if (serverConfigManager.isJobMachine()) {
             DefaultTaskConsumer taskConsumer = ctx.lookup(DefaultTaskConsumer.class);
             Threads.forGroup("cat").start(taskConsumer);
         }
         ```

      也就是说在**启动**的时候会判断该属性是否为true，为true的话则会开启线程，你更改了属性的同时，记得要重启服务，不然不会生效，因为它是在启动的时候触发这个任务线程的。

5. Unable to get instance of Logger, please make sure the environment was setup correctly!


### 源码笔记

`ComponentModelManager` : 扫描类,专门扫描META-INF下面的文件夹的

- plexus
  - components-cat-client.xml
    - com.dianping.cat.configuration.ClientConfigManager ： 客户端配置管理类
    - com.dianping.cat.message.internal.MessageIdFactory : Id生成工厂类
    - com.dianping.cat.message.spi.MessageManager : 消息管理配置类
    - com.dianping.cat.message.MessageProducer : 消息生产者 , 具体对客户端暴露的消息生产接口
    - com.dianping.cat.message.io.TcpSocketSender : 实际的消息发送者,利用tcp的方式,将消息传输到Cat的服务端
    - com.dianping.cat.message.io.TransportManager : 具体的事务消息管理器,通过MessageManager 调度
    - com.dianping.cat.message.spi.MessageStatistics : 消息的统计汇总
    - com.dianping.cat.status.StatusUpdateTask : 状态更新任务,应该是发送给服务端心跳的
    - 


`AlertManager` : 消息发送管理类

`TcpSocketReceiver`: 2280端口具体接收

`MessageHandler`: 消息处理器,专门用来处理接收的端口数据

`MessageConsumer`: 消息消费者接口定义

`CatServlet` : 服务启动初始化类

 - init方法
   - 定义了初始化`cat-client-xml`、`cat-server-xml`两个文件的加载入口



`CatHomeModule`: Cat的环境配置文件具体执行类



## 页面

### Problem

客户端数据接收处理器: `LongExecutionProblemHandler.handle`

| 描述             | 客户端埋点的key标记(注意带小写) | 时间维度划分                   |
| ---------------- | ------------------------------- | ------------------------------ |
| **Long-url**     | `URL`                           | 1000, 2000, 3000, 5000         |
| **Long-sql**     | `SQL`                           | 100, 500, 1000, 3000, 5000     |
| **Long-service** | `PigeonService` 或者 `Service`  | 50, 100, 500, 1000, 3000, 5000 |
| **Long-cache**   | 以`Cache.`开始                  | 10, 50, 100, 500               |
| **Long-call**    | `PigeonCall` 或者 `Call`        | 100, 500, 1000, 3000, 5000     |

如果需要调整可能需要改这个里面的源码和页面时间段源码



## CAT数据库中需要定时清理的大表

`daily_report_content` : 天报表二进制内容

`graph` : 小时图表曲线

`report` : 存放实时报表信息

`report_content` : 小时报表二进制内容

### 清理的SQL

保留最近一个月的数据

```sql
-- 删除表数据
delete from daily_report_content where  report_id <= (select * from (select MAX(report_id) from daily_report_content where creation_date < '2020-07-15 23:59:59') a);
delete from hourly_report_content where report_id <= (select * from(select MAX(report_id) from hourly_report_content where creation_date < '2020-07-15 23:59:59') a);

delete from graph where id <= (select * from(select MAX(id) from graph where period < '2020-07-15 23:59:59') a);

-- 清理磁盘空间
optimize table daily_report_content;
optimize table hourly_report_content;
optimize table graph;
```

