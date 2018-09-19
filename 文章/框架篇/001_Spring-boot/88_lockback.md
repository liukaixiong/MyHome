# springboot配置lockback.xml文件详解

学习了下psring的日志管理，具体的xml配置文件记录如下，方便以后参考。

```
<?xml version="1.0" encoding="UTF-8"?>
<!-- configuration根节点
    属性说明：
        scan：配置文件改变时是否重新加载 true表示是
        scanPeriod： 监视配置文件是否有修改的间隔时间，默认毫秒，scan为true时才生效
        debug: 是否打印logback内部日志信息 ，true表示是

     总体说明：根节点下有2个属性，三个节点
        属性： contextName 上下文名称； property 设置变量
        节点： appender,  root， logger
      详细说明见具体位置
 -->
<configuration scan="true" scanPeriod="60 seconds" debug="false">
    <!--
        contextName说明：
        每个logger都关联到logger上下文，默认上下文名称为“default”。但可以使用设置成其他名字，
        用于区分不同应用程序的记录。一旦设置，不能修改,可以通过%contextName来打印日志上下文名称。
     -->
    <contextName>train</contextName>
    <!--
        property说明：
        用来定义变量值的标签， 有两个属性，name和value；其中name的值是变量的名称，value的值时
        变量定义的值。通过定义的值会被插入到logger上下文中。定义变量后，可以使“${}”来使用变量。

        目前来说，可以直接配置属性，或者引入外部配置文件方式。引入外部文件可用file或者resource属性，
        但是推荐使用resouce属性。file必须是绝对路径，不推荐。
    -->
    <property resource="log-variables.properties"></property>
    <!--<property name="logback.path" value="F:\\workspaceScala\\log"/>-->
    <!--<property file="F:\workspaceScala\sprngbootjava\src\main\resources\log-variables.properties"></property>-->

    <!--输出到控制台-->
    <appender name="console" class="ch.qos.logback.core.ConsoleAppender">
        <!--展示格式 layout-->
        <encoder>
            <charset>${charset}</charset>
            <pattern>${console.pattern}</pattern>
        </encoder>
    </appender>

    <!-- 日志文件 级别：error -->
    <appender name="file_error" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <!-- file设置打印的文件的路径及文件名，建议绝对路径 -->
        <file>${logback.path}\${error.file}</file>
        <!-- 追加方式记录日志，默认true -->
        <append>true</append>
        <!-- 过滤策略：
            LevelFilter ： 只打印level标签设置的日志级别
            ThresholdFilter：打印大于等于level标签设置的级别，小的舍弃
         -->
        <filter class="ch.qos.logback.classic.filter.LevelFilter">
        <!--<filter class="ch.qos.logback.classic.filter.ThresholdFilter">-->
            <!-- 过滤的日志级别 -->
            <level>${error.level}</level>
            <!--匹配到就允许-->
            <onMatch>ACCEPT</onMatch>
            <!--没有匹配到就禁止-->
            <onMismatch>DENY</onMismatch>
        </filter>
        <!--
            日志记录器的滚动策略
            SizeAndTimeBasedRollingPolicy 按日期，大小记录日志
            另外一种方式：
                rollingPolicy的class设置为ch.qos.logback.core.rolling.TimeBasedRollingPolicy
                triggeringPolicy标签的class设置为ch.qos.logback.core.rolling.SizeBasedTriggeringPolicy
                意思是达到指定大小后重新写文件
        -->
        <rollingPolicy class="ch.qos.logback.core.rolling.SizeAndTimeBasedRollingPolicy">
            <!--
                归档的日志文件的路径，例如今天是2018-08-23日志，当前写的日志文件路径为file节点指定，
                可以将此文件与file指定文件路径设置为不同路径，从而将当前日志文件或归档日志文件置不同的目录。
                而2018-08-23的日志文件在由fileNamePattern指定。%d{yyyy-MM-dd}指定日期格式，%i指定索引
             -->
            <FileNamePattern>${logback.path}\${error.fileNamePattern}</FileNamePattern>
            <!--
                配置日志文件不能超过100M，若超过100M，日志文件会以索引0开始，命名日志文件
                例如error.20180823.0.txt
            -->
            <maxFileSize>100MB</maxFileSize>
            <!-- 只保留最近10天的日志 -->
            <maxHistory>${error.maxHistory}</maxHistory>
        </rollingPolicy>
        <encoder>
            <!-- 编码格式 -->
            <charset>${charset}</charset>
            <!-- 指定日志格式 -->
            <pattern>${error.pattern}</pattern>
        </encoder>
    </appender>

    <!-- 日志文件 级别：warn -->
    <appender name="file_warn" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <file>${logback.path}\${warn.file}</file>
        <filter class="ch.qos.logback.classic.filter.LevelFilter">
            <level>${warn.level}</level>
            <onMatch>ACCEPT</onMatch>
            <onMismatch>DENY</onMismatch>
        </filter>

        <rollingPolicy class="ch.qos.logback.core.rolling.SizeAndTimeBasedRollingPolicy">
            <FileNamePattern>${logback.path}\${warn.fileNamePattern}</FileNamePattern>
            <maxFileSize>100MB</maxFileSize>
            <maxHistory>${warn.maxHistory}</maxHistory>
        </rollingPolicy>
        <encoder>
            <charset>${charset}</charset>
            <pattern>${warn.pattern}</pattern>
        </encoder>
    </appender>

    <!-- 日志文件 级别：info -->
    <appender name="file_info" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <file>${logback.path}\${info.file}</file>
        <filter class="ch.qos.logback.classic.filter.LevelFilter">
            <level>${info.level}</level>
            <onMatch>ACCEPT</onMatch>
            <onMismatch>DENY</onMismatch>
        </filter>
        <rollingPolicy class="ch.qos.logback.core.rolling.SizeAndTimeBasedRollingPolicy">
            <FileNamePattern>${logback.path}\${info.fileNamePattern}</FileNamePattern>
            <maxFileSize>100MB</maxFileSize>
            <maxHistory>${info.maxHistory}</maxHistory>
        </rollingPolicy>
        <encoder>
            <charset>${charset}</charset>
            <pattern>${info.pattern}</pattern>
        </encoder>
    </appender>

    <!--
        root指定最基础的日志输出级别，level属性指定
        appender-ref标识的appender将会添加到这个logger
    -->
    <root level="info">
        <appender-ref ref="console"/>
        <appender-ref ref="file_info"/>
        <appender-ref ref="file_warn"/>
        <appender-ref ref="file_error"/>
    </root>

    <!--
        logger用来设置某一个具体的包或者类的日志打印， name表明包路径或类路径，level指定打印级别，
        addtivity表示是否向上级logger(即，root)传递打印信息
        下例指定了warn及以上级别的日志交给“console”appender打印，并且不向上传递。
    -->
    <logger name="com.lin.train.mapper" level="DEBUG" additivity="false">
        <appender-ref ref="console"/>
    </logger>

    <!--
        多环境日志输出：这里不再详细描述，个人感觉意义不大。无论生产还是开发，配置info级别就OK了
        相应标签：springProfile
    -->
</configuration>123456789101112131415161718192021222324252627282930313233343536373839404142434445464748495051525354555657585960616263646566676869707172737475767778798081828384858687888990919293949596979899100101102103104105106107108109110111112113114115116117118119120121122123124125126127128129130131132133134135136137138139140141142143144145146147148149150151152153154
```

属性文件如下：

```
#log.path=F:\\workspaceScala\\log\\train.log
#日志文件路径
logback.path=F:\\workspaceScala\\log
#日志输出编码
charset=UTF-8

####################### 控制台日志 start ##########################
#日志输出格式
#console.pattern=[lf-1][service][%d{yyyy-MM-dd HH:MM:ss.SSS}] [%-5level] [%t] %msg%n
#%d [%thread] - %contextName %-5level %logger{36}.%M\(%file:%line\) - %msg%n
#说明：               时间                      日志级别    应用上下文       线程名     类名方法名         消息  换行
console.pattern=%d{yyyy-MM-dd HH:mm:ss.sss} %-5level [%contextName] -- [%t] %logger{36}.%method: %msg%n
#日志输出级别
console.level=debug
####################### 控制台日志 end ############################

####################### info日志 start ###########################
#日志输出格式
info.pattern=%d{yyyy-MM-dd HH:mm:ss.sss} %-5level [%contextName] -- [%t] %logger{36}.%method: %msg%n
#日志输出级别
info.level=info
#日志文件路径
info.file=info.log
#日志文件名称格式
info.fileNamePattern=info.%d{yyyy-MM-dd}.%i.txt
#日志文件保留天数
info.maxHistory=7
####################### info日志 end ############################

####################### warn日志 start ###########################
#日志输出格式
warn.pattern=%d{yyyy-MM-dd HH:mm:ss.sss} %-5level [%contextName] -- [%t] %logger{36}.%method: %msg%n
#日志输出级别
warn.level=warn
#日志文件路径
warn.file=warn.log
#日志文件名称格式
warn.fileNamePattern=warn.%d{yyyy-MM-dd}.%i.txt
#日志文件保留天数
warn.maxHistory=7
####################### warn日志 end #############################

####################### error日志 start ###########################
#日志输出格式
error.pattern=%d{yyyy-MM-dd HH:mm:ss.sss} %-5level [%contextName] -- [%t] %logger{36}.%method: %msg%n
#日志输出级别
error.level=error
#日志文件路径
error.file=error.log
#日志文件名称格式
error.fileNamePattern=error.%d{yyyy-MM-dd}.%i.txt
#日志文件保留天数
error.maxHistory=10
####################### error日志 end ###########################
12345678910111213141516171819202122232425262728293031323334353637383940414243444546474849505152535455
```

第一次写博客，希望能记录自己更多的学习过程。 
如有错误，欢迎指正。 
附：参考链接如下： 
<http://tengj.top/2017/04/05/springboot7/> 
<https://www.cnblogs.com/linkstar/p/8309039.html> 
<https://www.cnblogs.com/lixuwu/p/5804793.html>