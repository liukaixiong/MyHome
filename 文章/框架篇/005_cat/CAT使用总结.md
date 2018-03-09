## 部署步骤

1. 下载源码

   ```
   https://github.com/dianping/cat.git
   ```

   ​

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
      - 进入cat-home目录下,启动自带的Jetty容器
      - mvn jetty:run

   2. 环境部署

      1. linux可以参考cat/框架埋点方案集成/Dianping CAT 安装说明文档.md

   3. 注意查看文档

      1. cat/Dianping CAT 配置加载说明.md
      2. Cat技术入门总结-0.1.0.doc

   4. 客户端集成

      1. 一定要将CAT部署完的包全部上传到本地manve私服上面去

         `cat/pom.xml`

      ```xml
       <distributionManagement>
      	   <repository>
      		   <id>releases</id>
      		   <name>Nexus Release Repository</name>
      		   <url>http://192.168.0.11:8081/nexus/content/repositories/elab/</url>
      	   </repository>
            <!--<snapshotRepository>-->
               <!--<id>snapshots</id>-->
               <!--<url>${snapshots.repo}</url>-->
            <!--</snapshotRepository>-->
         </distributionManagement>
      ```

      ​	执行:`mvn clean package deploy -Dmaven.test.skip=true`

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




## 错误介绍

1. 调整CAT的`plexus/components-cat-client.xml`文件修改消息类型的时候将`com.dianping.cat.message.MessageProducer`的实现类`implementation`的路径写错了,导致服务器爆出的异常为`Unable to get instance of MessageManager, please make sure the environment was setup correctly`。这个异常比较麻烦的就是本地不会出现,但是服务器有可能会出现!!!!!



### 源码笔记

   

`ComponentModelManager` : 扫描类,专门扫描META-INF下面的文件夹的





