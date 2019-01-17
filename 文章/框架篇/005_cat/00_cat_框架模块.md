---
typora-copy-images-to: ..\..\..\image\wz_img
---

# CAT 框架源码

## IOC容器的初始化

### Servlet

Cat的Servlet类结构: 

![1540175994450](D:\github\MyHome\image\wz_img\1540175994450.png)

容器的抽象定义 : AbstractContainerServlet

#### AbstractContainerServlet

**初始化方法** : init  -  当所有servlet启动的时候，便会执行这个方法进行初始化。

```java
@Override
public void init(ServletConfig config) throws ServletException {
    super.init(config);

    try {
        if (m_container == null) {
            // 指定默认的容器装载类 , 主要是读取META-INF/plexus/components.xml文件构造容器
            m_container = ContainerLoader.getDefaultContainer();
        }

        m_logger = ((DefaultPlexusContainer) m_container).getLoggerManager().getLoggerForComponent(
            getClass().getName());
		// 回调子类的方法
        initComponents(config);
    } catch (Exception e) {
        if (m_logger != null) {
            m_logger.error("Servlet initializing failed. " + e, e);
        } else {
            System.out.println("Servlet initializing failed. " + e);
            e.printStackTrace(System.out);
        } 
        throw new ServletException("Servlet initializing failed. " + e, e);
    }
}
```

**抽象方法 : initComponents**



> 主要用来初始化容器的，而这个容器的构造文件则是在`META-INF/plexus/components.xml`中解析

> 所有在这个文件里面定义的类都将会被初始化，有点类似Spring的Bean.xml文件。

入口类 : CatServlet

控制类 : org.unidal.web.MVC

### 接口类

#### ModuleInitializer

##### execute执行方法

![1540187639833](D:\github\MyHome\image\wz_img\1540187639833.png)



















## 告警模块



告警模块

ExceptionAlert

规则类型

RuleType





# 菜单栏

请求URL 枚举类 : ReportPage

> 基本上所有的请求路径都会使用该枚举值，查找页面的controller可以从这里面下手

## Dashboard

TopologyGraphManager : 构建一个异步线程

页面入口 : com.dianping.cat.report.page.top.Handler

页面数据(按照小时时间段查询):

根据项目查找 : http://127.0.0.1:2281/cat/r/model/dependency/cat-demo/CURRENT?op=xml

根据时间段查找 : http://127.0.0.1:2281/cat/r/model/top/cat/LAST?op=xml&date=1543309200000



页面入口 : 

页面数据查找:

根据项目查找 : http://192.168.4.239:2281/cat/r/model/transaction/cat-demo/CURRENT?op=xml&ip=All

http://192.168.4.239:2281/cat/r/model/transaction/cat/CURRENT?op=xml&ip=All&requireAll=true&min=37&max=37&name=OutboundPhase&type=MVC

根据时间段查找 : http://192.168.4.239:2281/cat/r/model/transaction/cat-demo/CURRENT?op=xml&ip=All



##  手写一个页面



## 开启CAT开发模式

tomcat启动时加入参数:

```tex
-Dfile.encoding=UTF-8 -DdevMode=true
```

加入之后日志会出现在控制台，包括异常



ModelManager : 存储所有路由映射的handle

拷贝其中一个文件文件夹目录

1. java

**拷贝文件:**

com.dianping.cat.report.page.home

Payload : 代表MVC中的请求参数实体封装

Model : MVC中的出参结果返回实体封装，页面上需要用到

增加代码:

`ReportPage` : 

```
TOPHOUR("tophour", "tophour", "TopHour", "TopHour", true),
```

`ReportModule`:

```
com.dianping.cat.report.page.tophour.Handler.class
```

2. 配置文件

components.xml

```xnk
<!-- 类似于Spring中的IOC管理容器 role代表接口,implementation代表实现,requirements表示注入的实例，这里需要注意的是注入的实例必须由这个IOC容器管理 --> 
<component>
			<role>com.dianping.cat.report.page.tophour.Handler</role>
			<implementation>com.dianping.cat.report.page.tophour.Handler</implementation>
			<requirements>
				<requirement>
					<role>com.dianping.cat.report.page.tophour.JspViewer</role>
				</requirement>
				<requirement>
					<role>com.dianping.cat.mvc.PayloadNormalizer</role>
				</requirement>
				<requirement>
					<role>com.dianping.cat.report.page.dependency.ExternalInfoBuilder</role>
				</requirement>
				<requirement>
					<role>com.dianping.cat.report.page.state.StateBuilder</role>
				</requirement>
				<requirement>
					<role>com.dianping.cat.report.service.ModelService</role>
					<role-hint>top</role-hint>
					<field-name>m_topService</field-name>
				</requirement>
				<requirement>
					<role>com.dianping.cat.report.service.ModelService</role>
					<role-hint>transaction</role-hint>
					<field-name>m_transactionService</field-name>
				</requirement>
				<requirement>
					<role>com.dianping.cat.report.service.ModelService</role>
					<role-hint>problem</role-hint>
					<field-name>m_problemService</field-name>
				</requirement>
				<requirement>
					<role>com.dianping.cat.report.page.top.service.TopReportService</role>
				</requirement>
				<requirement>
					<role>com.dianping.cat.report.page.transaction.transform.TransactionMergeHelper</role>
				</requirement>
				<requirement>
					<role>com.dianping.cat.report.alert.exception.ExceptionRuleConfigManager</role>
				</requirement>
				<requirement>
					<role>com.dianping.cat.helper.JsonBuilder</role>
				</requirement>
			</requirements>
		</component>
		<!-- 每个JSPViewer 都需要先定义 才能被上面给注入进去 -->
		<component>
            <role>com.dianping.cat.report.page.tophour.JspViewer</role>
            <implementation>com.dianping.cat.report.page.tophour.JspViewer</implementation>
            <requirements>
                <requirement>
                    <role>org.unidal.web.mvc.view.model.ModelHandler</role>
                </requirement>
            </requirements>
        </component>
```



3. web层

**Handler.java**

```java
@Override
@PayloadMeta(Payload.class)
@InboundActionMeta(name = "tophour")
public void handleInbound(Context ctx) throws ServletException, IOException {
    // display only, no action here
}

@Override
@OutboundActionMeta(name = "tophour")
public void handleOutbound(Context ctx) throws ServletException, IOException {
	 Model model = new Model(ctx);
    Payload payload = ctx.getPayload();
    Action action = payload.getAction();
    model.setAction(action);
    // 跳转页面
    model.setPage(ReportPage.TOPHOUR);
    // 返回页面类型
    model.setAction(Action.VIEW);
    
    // 业务操作
     if (action == Action.VIEW) {
         if (!ctx.isProcessStopped()) {
             m_jspViewer.view(ctx, model);
         }
     } else if (action == Action.API) {
         ctx.getHttpServletResponse().getWriter().write(m_builder.toJson(model.getTopMetric()));
     }
}
```



## 如何自定义DAO处理?

### CAT的这部分内容存放在哪里?

我们看CAT的源码发现它的Model和JDBC存放的位置在哪里?

通常都是target/genrated-sources的dal-jdbc和dal-model中

dal-model : 存放的是公共的基类

dal-jdbc : 存放的是数据库相关的对象的映射

### 他们是如何生成的?

从pom.xml中我们可以看到有一个自动生成的插件:

```xml
<plugin>
    <groupId>org.unidal.maven.plugins</groupId>
    <artifactId>codegen-maven-plugin</artifactId>
    <executions>
        <execution>
            <id>generate data model</id>
            <phase>generate-sources</phase>
            <goals>
                <goal>dal-model</goal>
            </goals>
            <configuration>
                <!-- 对应的实体生成 这一部分定义的会生成在dal-model目录下 -->
                <manifest>${basedir}/src/main/resources/META-INF/dal/model/server-config-manifest.xml,
                    ${basedir}/src/main/resources/META-INF/dal/model/url-pattern-manifest.xml,
                    ${basedir}/src/main/resources/META-INF/dal/model/server-filter-config-manifest.xml,
                    ${basedir}/src/main/resources/META-INF/dal/model/sample-config-manifest.xml,
                    ${basedir}/src/main/resources/META-INF/dal/model/business-report-config-manifest.xml,
                    ${basedir}/src/main/resources/META-INF/dal/model/atomic-message-config-manifest.xml,
                    ${basedir}/src/main/resources/META-INF/dal/model/tp-value-statistic-config-manifest.xml,
                    ${basedir}/src/main/resources/META-INF/dal/model/report-reload-config-manifest.xml,
                </manifest>
            </configuration>
        </execution>
        <execution>
            <id>generate dal jdbc model</id>
            <phase>generate-sources</phase>
            <goals>
                <goal>dal-jdbc</goal>
            </goals>
            <!-- 基础的配置类 -->
            <configuration>
                <!-- 这一部分配置的内容会生成在dal-jdbc下 -->
                <manifest>
                    <!-- 报表对应的对象处理 -->
                    ${basedir}/src/main/resources/META-INF/dal/jdbc/report-manifest.xml,
                    <!-- 配置对应的数据库处理生成配置 -->
                    ${basedir}/src/main/resources/META-INF/dal/jdbc/config-manifest.xml,
                </manifest>
            </configuration>
        </execution>
    </executions>
</plugin>
```

这里有个规范就是 : 

manifest结尾的配置都是主文件，里面包含了两个文件

dal : 生成的目录

codegen : 表的定义以及需要用到的SQL语句

> 这里需要注意的是，你所有的操作必须由这个生成工具来生成，自己手动去代码中改的话，下次生成会被覆盖掉。

#### 如何编写自定义的SQL?

CAT默认生成的DAO类简单的只会包含增删改查，特别基础的。

查询也只会根据主键查找，如果我们需要根据某几列值去查询的话应该怎么去做呢？

举例: report-codegen.xml

假设我们有一个新表 : top_day

```xml
<!-- name: 实体名称-表示驼峰会转换, table : 表名 alias: 别名,生成的SQL语句会加上这个别名 -->
<entity name="top-day" table="top_day" alias="top">
    <member name="id" field="id" value-type="int" length="10" nullable="false" key="true" auto-increment="true" />
    <member name="domain" field="domain" value-type="String" length="128" />
    <member name="data-time" field="data_time" value-type="Date" nullable="false" />
    <member name="data-json" field="data_json" value-type="String" length="65535" />
    <member name="type" field="type" value-type="String" length="128" />
    <member name="index-data" field="index_data" value-type="String" length="128" />
    <member name="create-time" field="create_time" value-type="Date" />
    <var name="key-id" value-type="int" key-member="id" />
    <primary-key name="PRIMARY" members="id" />
    <readsets>
      <readset name="FULL" all="true" />
    </readsets>
    <updatesets>
      <updateset name="FULL" all="true" />
    </updatesets>
    <query-defs>
      <query name="find-by-PK" type="SELECT">
        <param name="key-id" />
        <statement><![CDATA[SELECT <FIELDS/>
        FROM <TABLE/>
        WHERE <FIELD name='id'/> = ${key-id}]]></statement>
      </query>
      <query name="insert" type="INSERT">
        <statement><![CDATA[INSERT INTO <TABLE/>(<FIELDS/>)
        VALUES(<VALUES/>)]]></statement>
      </query>
      <query name="update-by-PK" type="UPDATE">
        <param name="key-id" />
        <statement><![CDATA[UPDATE <TABLE/>
        SET <FIELDS/>
        WHERE <FIELD name='id'/> = ${key-id}]]></statement>
      </query>
      <query name="delete-by-PK" type="DELETE">
        <param name="key-id" />
        <statement><![CDATA[DELETE FROM <TABLE/>
        WHERE <FIELD name='id'/> = ${key-id}]]></statement>
      </query>
        <!-- 这里就是比较自定义的SQL生成的方式 --> 
        <!-- query 表示 执行的SQL语句 -->
        <!-- name 方法名称 -->
        <!-- type : Select语句类型 -->
        <!-- multiple : 表示返回的结果集是一个List -->
      <query name="findByList" type="SELECT" multiple="true" >
          <!-- param : 入参 这里最好和实体中的名称相对应 -->
        <param name="type" />
        <param name="data-time" />
        <param name="index-data" />
          <!-- 你自己写的SQL语句 -->
        <statement><![CDATA[SELECT <FIELDS/>
        FROM <TABLE/>
        WHERE <FIELD name='type'/> = ${type} AND  <FIELD name='data-time'/> = ${data-time} AND  <FIELD name='index-data'/> = ${index-data} ]]></statement>
      </query>
    </query-defs>
  </entity>
```

基本上上面定义好了之后，mvn install 之后 对应的目录就会生成对应的实体和DB对应层。

### 如果生成好了对应的文件应该如何处理?

一旦数据库的实体对应生成好了之后，项目中如果需要应用到它的处理方式和Spring的类似，不过没有Spring灵活，需要在`components.xml`文件中先定义该对象，如果是生成的貌似会在这个文件生成。

例如 : 

```xml
<component>
    <role>com.dianping.cat.core.dal.TopDayDao</role>
    <implementation>com.dianping.cat.core.dal.TopDayDao</implementation>
    <requirements>
        <requirement>
            <role>org.unidal.dal.jdbc.QueryEngine</role>
        </requirement>
    </requirements>
</component>
```

如果Service需要使用和Spring类似:

需要手动去注入进去

```xml
 <component>            <role>com.dianping.cat.report.page.toptransaction.service.TopTransactionReportService</role>
      
 <implementation>com.dianping.cat.report.page.toptransaction.service.TopTransactionReportService
            </implementation>
     <requirements>
         <requirement>
             <role>com.dianping.cat.core.dal.HourlyReportDao</role>
         </requirement>
         <requirement>
             <role>com.dianping.cat.core.dal.HourlyReportContentDao</role>
         </requirement>
         <requirement>
             <role>com.dianping.cat.core.dal.DailyReportDao</role>
         </requirement>
         <requirement>
             <role>com.dianping.cat.core.dal.DailyReportContentDao</role>
         </requirement>
         <requirement>
             <role>com.dianping.cat.core.dal.WeeklyReportDao</role>
         </requirement>
         <requirement>
             <role>com.dianping.cat.core.dal.WeeklyReportContentDao</role>
         </requirement>
         <requirement>
             <role>com.dianping.cat.core.dal.MonthlyReportDao</role>
         </requirement>
         <requirement>
             <role>com.dianping.cat.core.dal.MonthlyReportContentDao</role>
         </requirement>
         <requirement>
             <role>com.dianping.cat.core.dal.TopDayDao</role>
         </requirement>
     </requirements>
</component>
```

> 这里有个比较坑的地方，如果你在Handle中注入了某个类，但是启动的时候说某个类创建失败，那么你就需要自己去分析这个类里面注入的属性是否都在components.xml中定义过，如果是路径写错了或者注入的属性类是没有在容器中定义的都会报错，但是报错的提示可能不太清晰，需要自己去反复校验是哪个属性出错了。

# 异常总结 : 

- 如果某个类加载失败，记得去配置文件去判断哪个类没有注入进来,因为异常特别不明确。

