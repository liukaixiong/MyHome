---
typora-root-url: img
---

分布式事务`tx-lcn`调研

## tx-lcn 介绍

LCN分布式事务框架是一款事务协调性的框架，框架本身并不创建事务，只是对本地事务做协调控制。因此该框架与其他第三方的框架兼容性强，支持所有的关系型数据库事务，支持多数据源，支持与第三方数据库框架一块使用（例如 sharding-jdbc），在使用框架的时候只需要添加分布式事务的注解即可，对业务的侵入性低。LCN框架主要是为微服务框架提供分布式事务的支持，在微服务框架上做了进一步的事务机制优化，在一些负载场景上LCN事务机制要比本地事务机制的性能更好，4.0以后框架开方了插件机制可以让更多的第三方框架支持进来。



## 源码资料



- github : https://github.com/codingapi/tx-lcn
- 官网地址: [https://www.txlcn.org](https://www.txlcn.org/)
- demo：
  1. springcloud ： https://github.com/codingapi/springcloud-lcn-demo
  2. dubbo：https://github.com/codingapi/dubbo-lcn-demo
  3. motan ： https://gitee.com/zfvipCase/motan-lcn-demo 



## 依赖组件

- tx-manage 
  1. redis 
  2. eureka  - 据说可以拓展
     1. war 包 : : http://central.maven.org/maven2/com/netflix/eureka/eureka-server
     2. 搭建文档: http://blog.chinaunix.net/uid-119476-id-4759938.html
     3. jar包 ： https://pan.baidu.com/s/1mjbONPI
        1. java -jar (jarName)



## 相关项目解读

1. tx-client 是LCN核心tx模块端控制框架
2. **tx-manager** : 是LCN 分布式事务协调器
   1. **创建事务组**:事务发起方在执行业务代码前先调用tx-manager创建事务组对象，然后拿到事务标示GroupId的过程
   2. **添加事务组**: 参与事务执行方执行业务方法以后,会将该模块的事务信息通知给TxManger的操作
   3. **关闭事务组**:发起方完成业务操作之后,将发起方的事务操作通知给TxManager的动作,当执行完关闭事务的操作以后,TxManger将根据事务组信息来通知相应的参与模块提交或回滚事务
3. **tx-plugins-db**: 是LCN 对关系型数据库的插件支持.
4. **tx-plugins-nodb** : 是LCN 对于无数据库模块的插件支持
5. **tx-plugins-redis** : 是LCN 对于redis模块的插件支持（功能暂未实现）

## 分布式事务实现思路

LCN事务控制原理是由事务模块TxClient下的代理连接池与TxManager的协调配合完成的事务协调控制。

TxClient的代理连接池实现了`javax.sql.DataSource`接口，并重写了`close`方法，事务模块在提交关闭以后TxClient连接池将执行"假关闭"操作，等待TxManager协调完成事务以后在关闭连接。

### 对于代理连接池的优化

1. 自动超时机制
   任何通讯都有最大超时限制，参与模块在等待通知的状态下也有最大超时限制，当超过时间限制以后事务模块将先确认事务状态，然后再决定执行提交或者回滚操作，主要为了给最大资源占用时间加上限制。
2. 智能识别创建不同的连接 对于只读操作、非事务操作LCN将不开启代理功能，返回本地连接对象，对于补偿事务的启动方将开启回滚连接对象，执行完业务以后马上回滚事务。
3. LCN连接重用机制 当模块在同一次事务下被重复执行时，连接资源会被重用，提高连接的使用率。

## 环境搭建步骤

##### dubbo 环境搭建略..

1. 下载上面提供的demo 
2. tx-manage : https://github.com/codingapi/tx-lcn/wiki/TxManager%E5%90%AF%E5%8A%A8%E8%AF%B4%E6%98%8E

##### 代码层面:

1. dubbo的配置文件:

   ```java
   <dubbo:consumer  filter="transactionFilter" />

   ```

2. datasource配置文件:

   ```xml
   <!-- 连接代理池 重写了DataSource方法,并且添加了maxCount属性 -->
   <bean name="lcnDataSourceProxy" 	class="com.codingapi.tx.datasource.relational.LCNTransactionDataSource">
           <property name="dataSource" ref="dataSource"/>
     		<!-- 连接资源最大值,如果超过这个值会进行等待 -->
           <property name="maxCount" value="20"/>
       </bean>
   ```

3. SpringContext.xml

   ```xml
   <!-- 开启@Autowired注解扫描类 -->       
   <bean class="org.springframework.beans.factory.annotation.AutowiredAnnotationBeanPostProcessor"/>

   <!-- 扫描这个包下面的类,因为这里面植入了很多@Autowried注解 -->
   <context:component-scan base-package="com.codingapi.tx.*"/>
   <!-- 开启切面注解功能 -->
   <aop:aspectj-autoproxy expose-proxy="true" proxy-target-class="true"/>

   ```

4. pom.xml

   ```xml
    		<dependency>
               <groupId>com.codingapi</groupId>
               <artifactId>transaction-dubbo</artifactId>
               <version>${lcn.last.version}</version>
           </dependency>

           <dependency>
               <groupId>com.codingapi</groupId>
               <artifactId>tx-plugins-db</artifactId>
               <version>${lcn.last.version}</version>
           </dependency>

   ```

5. 业务代码:

   ```java
     @TxTransaction // 分布式注解
   ```

   ​

