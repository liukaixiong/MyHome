# 相关资料

github : https://github.com/knightliao/disconf

demo : <https://github.com/knightliao/disconf-demos-java>

文档: [http://disconf.readthedocs.io](http://disconf.readthedocs.io/)



## 项目环境

**项目编译**

进入到disconf/disconf-web

```tex
mvn clean install -Dadditionalparam=-Xdoclint:none
```

**注意，记得执行将application-demo.properties复制成application.properties：**



## 使用记录



### 必填

```xml
<!-- 开启AOP的注解扫描 -->	
<aop:aspectj-autoproxy proxy-target-class="true"/>

<!-- 使用disconf必须添加以下配置 -->
<bean id="disconfMgrBean" class="com.baidu.disconf.client.DisconfMgrBean"
      destroy-method="destroy">
  <!-- 需要扫描的包 -->
  <property name="scanPackage" value="com.example.disconf"/>
</bean>
<bean id="disconfMgrBean2" class="com.baidu.disconf.client.DisconfMgrBeanSecond"
      init-method="init" destroy-method="destroy">
</bean>

```



### 一. 如何将实体配置和disConf关联

**注解方式**

1. `@DisconfFile(filename = "simple.properties")`

对应web上面的配置文件名

2. `@DisconfFileItem(name = "host")`

对应上面配置文件的内容键

**配置文件方式**

spring.xml

```xml
<!-- 使用托管方式的disconf配置(无代码侵入, 配置更改会自动reload)-->
<bean id="configproperties_disconf"
      class="com.baidu.disconf.client.addons.properties.ReloadablePropertiesFactoryBean">
  <property name="locations">
    <list>
      <value>classpath*:autoconfig.properties</value>
    </list>
  </property>
</bean>

 <bean id="propertyConfigurer" class="com.baidu.disconf.client.addons.properties.ReloadingPropertyPlaceholderConfigurer">
   		<!-- 如果文件没有找到则可忽略 -->
        <property name="ignoreResourceNotFound" value="true"/>
   		<!-- 忽略已经无效的配置 -->
        <property name="ignoreUnresolvablePlaceholders" value="true"/>
        <property name="propertiesArray">
            <list>
                <ref bean="configproperties_disconf"/>
            </list>
        </property>
    </bean>
 
<!-- 这里可以引用上面autoconfig.properties里的的配置 -->
<bean id="autoService" class="com.example.disconf.config.AutoService">
    <property name="auto" value="${auto}"/>
</bean>
```



### 二. 会从disConf下载配置文件,但是不会自动更改

```xml
<!-- 使用托管方式的disconf配置(无代码侵入, 配置更改不会自动reload)-->
<bean id="configproperties_no_reloadable_disconf"
      class="com.baidu.disconf.client.addons.properties.ReloadablePropertiesFactoryBean">
    <property name="locations">
        <list>
            <value>myserver.properties</value>
        </list>
    </property>
</bean>

<bean id="propertyConfigurerForProject1"
      class="org.springframework.beans.factory.config.PropertyPlaceholderConfigurer">
    <property name="ignoreResourceNotFound" value="true"/>
    <property name="ignoreUnresolvablePlaceholders" value="true"/>
    <property name="propertiesArray">
        <list>
            <ref bean="configproperties_no_reloadable_disconf"/>
        </list>
    </property>
</bean>
```

### 三.为应用内的配置项更改做回调监听

场景: 当你的redis环境地址发生改变的时候,你可以通过disconf无缝更改,触发回调重新生成对象

1. 实现回调接口`IDisconfUpdate` 



2. 通过注解标识你这个监听是为哪个类触发的

```java
// Coefficients.key 发生变化的key
// JedisConfig : 表示当 JedisConfig.class 这个配置文件更新时，此回调类将会被调用, 或者，使用 confFileKeys 也可以。
@DisconfUpdateService(classes = {JedisConfig.class}, itemKeys = {Coefficients.key})
// 监听多个配置文件key
@DisconfUpdateService(confFileKeys = {"autoconfig.properties", "autoconfig2.properties"})
```



### 四.为单独的变量赋值

场景: 假设你要的变量非配置文件中的值,而仅仅只是作为一个变更变量如何处理?

```java
// 在指定的变量上的get方法上面定义
   @DisconfItem(key = key)
    public Double getDiscount() {
        return discount;
    }
  // spring通过@Value(key = xxx)
    @Value(value = "2.0d")
    private Double discount;
```



### 五. 为静态变量动态赋值

```java
/**
 * 静态 配置文件 示例
 *
 * @author liaoqiqi
 * @version 2014-6-17
 */
@DisconfFile(filename = "static.properties")
public class StaticConfig {

    private static int staticVar;

    @DisconfFileItem(name = "staticVar", associateField = "staticVar")
    public static int getStaticVar() {
        return staticVar;
    }

    public static void setStaticVar(int staticVar) {
        StaticConfig.staticVar = staticVar;
    }

}
```

### 使用

```java
package com.example.disconf.demo.service;

import com.baidu.disconf.client.common.annotations.DisconfItem;
import com.example.disconf.demo.config.StaticConfig;

/**
 * 使用静态配置文件的示例<br/>
 * Plus <br/>
 * 静态配置项 使用示例
 *
 * @author liaoqiqi
 * @version 2014-8-14
 */
public class SimpleStaticService {

    private static int staticItem = 56;

    /**
     *
     * @return
     */
    public static int getStaticFileData() {

        return StaticConfig.getStaticVar();
    }
}
```



### 六. 不需要disconf托管,读取本地文件

```
disconf.ignore=jdbc-mysql.properties
```



### 七. 线上发布通过命令启动



1. **问题**

​	一直以来，凡是使用 disconf的程序均需要 `disconf.properties` ，在这个文件里去控制 app/env/version。

​	因此，我们要部署到不同的环境中，还是需要 不同的 `disconf.properties`。

​	有一种解决方法是，通过 jenkins 来进行打包，准备多份 `disconf.properties` 文件。

2. **解决方法**

   真正的解决方法是，使用 java 命令行参数

   目前 disconf 已经支持 `disconf.properties` 中所有配置项 通过参数传入方式 启动。

   支持的配置项具体可参见： [link](http://disconf.readthedocs.io/zh_CN/latest/config/src/client-config.html)

   这样的话，未来大家只要通过 Java 参数 就可以 动态的改变启动的 app/env/version

   ​

**standalone 启动示例**

```
java  -Ddisconf.env=rd \
    -Ddisconf.enable.remote.conf=true \
    -Ddisconf.conf_server_host=127.0.0.1:8000 \
    -Dlogback.configurationFile=logback.xml \
    -Dlog4j.configuration=file:log4j.properties \
    -Djava.ext.dirs=lib \
    -Xms1g -Xmx2g -cp ampq-logback-client-0.0.1-SNAPSHOT.jar \
    com.github.knightliao.consumer.ConsumerMain >/dev/null 2>&1 &
```



### 八. 从disconf下载agent到指定的位置

可以修改一下 disconf-demos/disconf-standalone-demo 这个项目，让其变成一个 长驻进程，并指定

[disconf.user_define_download_dir](http://disconf.readthedocs.io/zh_CN/latest/config/client-config.html) 这个配置到你想指定的路径。



### 九. 针对配置文件更改回调

只要实现 `IDisconfUpdatePipeline` 接口即可。不要求必须是 java bean.

- 函数 `reloadDisconfFile` 是针对分布式配置文件的。key是文件名；filePath是文件路径。用户可以在这里(read file freely)按你喜欢的解析文件的方式进行处理。
- 函数 `reloadDisconfItem` 是针对分布式配置项的。key是配置项名；content是其值，并且含有类型信息。

示例代码：

```
/**
 */
@Service
public class UpdatePipelineCallback implements IDisconfUpdatePipeline {
	
	// 修改配置文件
    public void reloadDisconfFile(String key, String filePath) throws Exception {
        System.out.println(key + " : " + filePath);
    }
	// 修改配置文件中的内容
    public void reloadDisconfItem(String key, Object content) throws Exception {
        System.out.println(key + " : " + content);
    }
}
```

### 通过统一类获取任何配置数据

增加统一的类 来个性化编程式的获取任何配置数据, 目前只支持 .properties 文件

直接通过静态方法获取整个文件的属性

```
public class DisconfDataGetter {

    private static IDisconfDataGetter iDisconfDataGetter = new DisconfDataGetterDefaultImpl();

    /**
     * 根据 分布式配置文件 获取该配置文件的所有数据，以 map形式呈现
     *
     * @param fileName
     *
     * @return
     */
    public static Map<String, Object> getByFile(String fileName) {
        return iDisconfDataGetter.getByFile(fileName);
    }

    /**
     * 获取 分布式配置文件 获取该配置文件 中 某个配置项 的值
     *
     * @param fileName
     * @param fileItem
     *
     * @return
     */
    public static Object getByFileItem(String fileName, String fileItem) {
        return iDisconfDataGetter.getByFileItem(fileName, fileItem);
    }

    /**
     * 根据 分布式配置 获取其值
     *
     * @param itemName
     *
     * @return
     */
    public static Object getByItem(String itemName) {
        return iDisconfDataGetter.getByItem(itemName);
    }
}
```

## 配置文件介绍

**`disconf.properties`**

```properties
# 是否使用远程配置文件
# true(默认)会从远程获取配置 false则直接获取本地配置
disconf.enable.remote.conf=true

#
# 配置服务器的 HOST,用逗号分隔  127.0.0.1:8000,127.0.0.1:8000
#
disconf.conf_server_host=127.0.0.1:8080

# 版本, 请采用 X_X_X_X 格式
disconf.version=1_0_0_0

# APP 请采用 产品线_服务名 格式
disconf.app=disconf_demo

# 环境
disconf.env=rd

# debug
disconf.debug=true

# 忽略哪些分布式配置，用逗号分隔
disconf.disconf.ignore=

# 获取远程配置 重试次数，默认是3次
disconf.conf_server_url_retry_times=1
# 获取远程配置 重试时休眠时间，默认是5秒
disconf.conf_server_url_retry_sleep_seconds=1
# 用户定义的下载文件夹, 远程文件下载后会放在这里。注意，此文件夹必须有有权限，否则无法下载到这里
# 注意这里的默认值	./disconf/download
disconf.user_define_download_dir=./disconf/download

# 下载的文件会被迁移到classpath根路径下，强烈建议将此选项置为 true(默认是true)
disconf.enable_local_download_dir_in_class_path=true

```

#### 自定义 disconf.properties 文件的路径

一般情况下，disconf.properties 应该放在应用程序的根目录下，如果想自定义路径可以使用：

```
-Ddisconf.conf=/tmp/disconf.properties
```

------







## 源码笔记

`架构地址`:http://disconf.readthedocs.io/zh_CN/latest/design/src/%E5%88%86%E5%B8%83%E5%BC%8F%E9%85%8D%E7%BD%AE%E7%AE%A1%E7%90%86%E5%B9%B3%E5%8F%B0Disconf.html



`ClientCnxn`:事件触发





### 如何基于Spring手动更改值的?

基于`Zookeeper`的监听机制

`DisconfItemCoreProcessorImpl`: 默认的配置修改流程控制器

​	`updateOneConfAndCallback`: 更新消息

`DisconfStoreItemProcessorImpl` 

​	`updateOneConf`: 修改配置

​		`SpringRegistry` : 更改Spring中的值

​		`DisconfCenterStore`: disconf仓库实例

1. 如果更改了值之后,Zookeeper会触发一个回调事件,首先是需要应用能够监听自己关注的这一部分
2. 将新该的值注册到仓库[`SingletonHolder.instance-DisconfCenterStore`]中,并同时修改容器中的值
3. `DisconfAspectJ` : 所有`DisconfFile`注解都会被代理

### 如何从web上面下载的文件并且读取到Spring容器中的?

#### 程序启动入口

`DisconfMgrBean`：实现了`BeanDefinitionRegistryPostProcessor`接口,也就是说在Spring容器启动的refresh()方法的`this.invokeBeanFactoryPostProcessors(beanFactory);`阶段将会被初始化

`DisconfMgr`: 只需要关注这个类的`firstScan`方法就好了,整个流程都是在这里运转的

 1.  这个类主要做了两件事:

     导入配置

     构建一个`SpringRegistry`配置,并且让它拥有处理上下文的对象

     `ReflectionScanStatic`: 构建一个扫描包对象,并且对指定的disconf注解对象做扫描

     ​	`DisconfFile`: 类注解,扫描指定的配置文件

     ​	`DisconfFileItem`: 方法注解,根据上面的的配置文件找对应的配置项

     ​	`DisconfItem` : 扫描普通变量,不在配置文件中的

     ​	`DisconfActiveBackupService`:标识需要进行主备切换的服务,需要指定它影响的配置数据

     ​	`DisconfUpdateService`:标识配置更新时需要进行更新的服务,需要指定它影响的配置数据

     ​	`IDisconfUpdatePipeline`:这是个接口类,用来触发配置文件名称和字节点更改的回调通知

     `ScanStaticModel`:上面扫描对象之后,会将分析出来的数据并存储到该对象中

     `DisconfMgr`: 全局管理对象

     `StaticScannerMgr`: 文件管理对象,最终配置都会通过该文件去生成处理

     `DisconfCenterStore`: 最终生成配置文件对象

#### 初始化配置

`ConfigMgr` : 读取配置模块

`init`: 初始化功能

---



#### 