# mybatis 视频记录

## 什么是mybatis?

1. 类持久化框架
2. 支持定制SQL、存储过程
3. ORM的对象映射
4. 简化了JDBC的操作



## 如何使用mybatis ? 

### maven 配置mybatis 生成插件

pom.xml

```xml
 <plugin>
   <groupId>org.mybatis.generator</groupId>
   <artifactId>mybatis-generator-maven-plugin</artifactId>
   <version>1.3.3</version>
   <configuration>  						<configurationFile>${project.basedir}/src/main/resources/generator/generatorConfig.xml</configurationFile>
     <overwrite>true</overwrite>
   </configuration>
</plugin>
```

generatorConfig.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE generatorConfiguration
        PUBLIC "-//mybatis.org//DTD MyBatis Generator Configuration 1.0//EN"
        "mybatis-generator-config_1_0.dtd">

<generatorConfiguration>
    <classPathEntry location="E:\workspace\code\git\gupaoedu-mybatis\src\main\resources\generator\mysql-connector-java-5.1.8.jar"/>
    <context id="MysqlTables" targetRuntime="MyBatis3">
        <!--去除注释  -->
        <commentGenerator>
            <property name="suppressAllComments" value="true"/>
        </commentGenerator>

        <jdbcConnection driverClass="com.mysql.jdbc.Driver"
                        connectionURL="jdbc:mysql://localhost:3306/gp?useUnicode=true&amp;characterEncoding=utf-8&amp;useSSL=false&amp;useJDBCCompliantTimezoneShift=true&amp;useLegacyDatetimeCode=false&amp;serverTimezone=UTC"
                        userId="root"
                        password="123456">
        </jdbcConnection>

        <javaTypeResolver>
            <property name="forceBigDecimals" value="false"/>
        </javaTypeResolver>

        <javaModelGenerator targetPackage="com.gupaoedu.mybatis.beans" targetProject="E:\workspace\code\git\gupaoedu-mybatis\src\main\java">
            <property name="enableSubPackages" value="true"/>
            <property name="trimStrings" value="true"/>
        </javaModelGenerator>

        <sqlMapGenerator targetPackage="xml" targetProject="E:\workspace\code\git\gupaoedu-mybatis\src\main\resources">
            <property name="enableSubPackages" value="true"/>
        </sqlMapGenerator>

        <javaClientGenerator type="XMLMAPPER" targetPackage="com.gupaoedu.mybatis.mapper" targetProject="E:\workspace\code\git\gupaoedu-mybatis\src\main\java">
            <property name="enableSubPackages" value="true"/>
        </javaClientGenerator>


        <!--<table schema="gp" tableName="test" domainObjectName="Test">-->
            <!--<property name="useActualColumnNames" value="false"/>-->
        <!--</table>-->

        <table schema="gp" tableName="posts" domainObjectName="Posts">
            <property name="useActualColumnNames" value="false"/>
        </table>

    </context>
</generatorConfiguration>
```

3. 执行mvn mybatis-generator:generate

###  mybatis的配置

1. 基于xml配置
   1. 跟接口分离、同一管理
   2. 复杂的语句不影响接口的可读性
   3. -- 过多的xml文件
2. 基于Annotation配置
   1. 接口就能看到sql语句,可读性高、不需要在去找xml、方便
   2. 复杂的联合查询不好维护，可读性差

### Mybatis 中 如何针对特定的类型做转换

需要实现`org.apache.ibatis.type.TypeHandler`接口,并且在配置文件中#{id,jdcb=type,typeHandle=classPath}		



### 如何针对mybatis层面做拦截

需要实现`org.apache.ibatis.plugin.Interceptor`接口,接口可以配置到`mybatis-config.xml`中的plugins

```xml
<configuration>
  <plugins>
    <plugin interceptor="">
      <property name="" value="" />
    </plugin>
  </plugins>
</configuration>
```

或者通过注解@Interceptor({@Signature(Type=Executor.class,method="query",args={MappedStatement.class...})})



通过SqlSessionFactory



## 如何理解SqlSession?

sqlSession是一种会话(也可以理解为线程级会话),mybatis会基于sqlSession的做一级缓存.

举例: 1. 同一个sql执行多次查询,会缓存结果!





## 装饰器模式和委托模式

- 装饰器模式
  - 类与类之间有关系
    - Mybatis的Executor中的cachingExecutor则是装饰,只提供了缓存功能,装饰的对象则是SimpleExecutor
- 委托模式
  - 类与类之间没有关系 : SqlSession中持有Configuration和Executor, 这俩持有对象则是委托,他们分别做配置文件对象解析和数据层的执行两种功能