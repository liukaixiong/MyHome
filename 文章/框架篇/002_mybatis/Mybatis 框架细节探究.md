# mybatis 框架底层探究

## 一个简单的jdbc操作

1. 加载驱动
2. 创建连接
3. 创建语句集
4. 执行语句
5. 关闭连接

如果把简单的jdbc按照这几个步骤划分的话,我们思考一下,mybatis帮我们做了些啥?

我们不用重复的去写上面的代码,这些都通过mybatis底层封装好了可能我们需要做的就是做一些决定:

1. 选用那种连接池? druid？
2. 业务sql 
3. 结果类型处理(根据业务去处理执行的结果)



这时候我们就可以顺着这条思路去看,他到底是如何简化这些步骤的



###  1、2 加载连接

一般会把这两个步骤合为一体,因为本身驱动就在连接之中需要配置

创建一个数据源

```xml
<bean id="mysqlDataSource" class="com.alibaba.druid.pool.DruidDataSource">
        <property name="driverClassName" value="${jdbc.mysql.driverClassName}"/>
        <property name="url" value="${jdbc.mysql.url}"/>
        <property name="username" value="${jdbc.mysql.username}"/>
        <property name="password" value="${jdbc.mysql.password}"/>
</bean>
```



这时候我们会更关心mybatis怎么拿到这个数据源去做事情!

`org.mybatis.spring.SqlSessionFactoryBean`

```xml
<!-- 加载数据源 -->
<bean id="sqlSessionFactory" class="org.mybatis.spring.SqlSessionFactoryBean">
  <!-- 持有数据源 -->
  <property name="dataSource" ref="mysqlDataSource"/>
  <!-- 持有本地文件对象 -->
  <property name="configLocation" value="classpath:dao-mybaties-mapper/mybatis-config.xml"/>
  <!-- 持有mapperXml文件对象 -->
  <property name="mapperLocations">
    <list>
      <value>classpath:customize-mapper/mysql/*.xml</value>
    </list>
  </property>
</bean>
```



`org.mybatis.spring.SqlSessionFactoryBean` 类结构:

![image.png](http://upload-images.jianshu.io/upload_images/6370985-2cc689a105febeb7.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

`org.springframework.beans.factory.InitializingBean` : 执行该类的时候会触发`afterPropertiesSet` 方法 , 它这里面用来做一些必填参数校验,并且构建一个`org.apache.ibatis.session.SqlSessionFactory`对象,mybatis最重要的一个对象,持有`org.apache.ibatis.session.Configuration`(配置文件)和`org.apache.ibatis.executor.Executor`(具体执行sql方法)对象.  



其实这里就已经满足执行sql的条件了 : 

- 加载驱动和创建连接 : 持有了DataSource的引用
- 创建结果集 :  sql语句在哪里? 配置文件中(`Configuration`已经持有了`mapper.xml`对象)
- 执行结果集 :  `Executor` 已经具备了执行条件
- 关闭连接 : 持有了dataSource的对象可以去做



