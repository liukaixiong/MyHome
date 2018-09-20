# 相关资料

[github](https://github.com/alibaba/arthas)

[使用文档](https://alibaba.github.io/arthas/install-detail.html)

# 简介

`arthas`是阿里巴巴开源的java诊断工具，注重解决线上问题排查。

简单场景:

1. 帮你找到指定类是从哪个jar包加载的。
2. 线上定位加载到内存的字节码，并且能够反编译成源码，帮助你定位线上代码是否是最新的。
3. 拥有和btrace一样的自动加载类的能力，不需要你写特别复杂的植入类。能够很快帮你加载到内存中并且运行起来，不需要启动。
4. 查看线上某个方法的调用耗时情况，以及方法的调用链路
5. 监控JVM目前的运行情况。
6. 监控系统的运行情况。

# 使用

安装Arthas:

```
curl -L https://alibaba.github.io/arthas/install.sh | sh
```



# 实操

### 基础使用命令

#### cls

清空当前屏幕

### jvm相关

- [dashboard](https://alibaba.github.io/arthas/dashboard.html)——当前系统的实时数据面板
- [thread](https://alibaba.github.io/arthas/thread.html)——查看当前 JVM 的线程堆栈信息
- [jvm](https://alibaba.github.io/arthas/jvm.html)——查看当前 JVM 的信息
- [sysprop](https://alibaba.github.io/arthas/sysprop.html)——查看和修改JVM的系统属性
- **New!** [getstatic](https://alibaba.github.io/arthas/getstatic.html)——查看类的静态属性

## monitor/watch/trace相关

> 请注意，这些命令，都通过字节码增强技术来实现的，会在指定类的方法中插入一些切面来实现数据统计和观测，因此在线上、预发使用时，请尽量明确需要观测的类、方法以及条件，诊断结束要执行 `shutdown` 或将增强过的类执行 `reset` 命令。

- [monitor](https://alibaba.github.io/arthas/monitor.html)——方法执行监控
- [watch](https://alibaba.github.io/arthas/watch.html)——方法执行数据观测
- [trace](https://alibaba.github.io/arthas/trace.html)——方法内部调用路径，并输出方法路径上的每个节点上耗时
- [stack](https://alibaba.github.io/arthas/stack.html)——输出当前方法被调用的调用路径
- [tt](https://alibaba.github.io/arthas/tt.html)——方法执行数据的时空隧道，记录下指定方法每次调用的入参和返回信息，并能对这些不同的时间下调用进行观测

## options

- [options](https://alibaba.github.io/arthas/options.html)——查看或设置Arthas全局开关



## 管道

Arthas支持使用管道对上述命令的结果进行进一步的处理，如`sm org.apache.log4j.Logger | grep <init>`

- grep——搜索满足条件的结果
- plaintext——将命令的结果去除颜色
- wc——按行统计输出结果



## 后台异步任务

当线上出现偶发的问题，比如需要watch某个条件，而这个条件一天可能才会出现一次时，异步后台任务就派上用场了，详情请参考[这里](https://alibaba.github.io/arthas/async.html)

- 使用 > 将结果重写向到日志文件，使用 & 指定命令是后台运行，session断开不影响任务执行（生命周期默认为1天）
- jobs——列出所有job
- kill——强制终止任务
- fg——将暂停的任务拉到前台执行
- bg——将暂停的任务放到后台执行



## Web Console

通过websocket连接Arthas。

- [Web Console](https://alibaba.github.io/arthas/web-console.html)



# 实战

1. 查看已经类的加载信息，首先需要确保类已经加载到内存中了，如果排查出来的

```shell
sc com.elab.core.spring.common.utils.BeanUtils
Affect(row-cnt:0) cost in 30 ms. [表示没有加载到内存中]

## 已经加载到内存中了.
$ sc com.elab.core.spring.common.utils.BeanUtils
com.elab.core.spring.common.utils.BeanUtils
Affect(row-cnt:1) cost in 10 ms.
```

2. 查看指定类下面的所有方法

```shell
> sm com.elab.marketing.auth.service.impl.ElaberServiceImpl

com.elab.marketing.auth.service.impl.ElaberServiceImpl$$EnhancerBySpringCGLIB$$22ca59f2->elabLogin
com.elab.marketing.auth.service.impl.ElaberServiceImpl$$EnhancerBySpringCGLIB$$22ca59f2->addHouseAuthSub
com.elab.marketing.auth.service.impl.ElaberServiceImpl$$EnhancerBySpringCGLIB$$22ca59f2->modifyHouseAuth
com.elab.marketing.auth.service.impl.ElaberServiceImpl$$EnhancerBySpringCGLIB$$22ca59f2->addHouseAuth

```

3. 加载外部的class文件到内存中

> redefine -p  D:/dev/arthas-3.0.20180906014854-bin/arthas/ElaberServiceImpl.class

比如在代码中打印一个输出日志,然后通过这个命令加入到内存中,会发现打印日志被触发了。

4. 打印并且反编译字节码转成源码

> jad com.elab.marketing.auth.service.impl.ElaberServiceImpl

5. 针对某个方法进行监控

> monitor -c 5  com.elab.marketing.auth.service.impl.ElaberServiceImpl elabLogin

表示每5秒打印一次统计结果

| 监控项    | 说明                       |
| --------- | -------------------------- |
| timestamp | 时间戳                     |
| class     | Java类                     |
| method    | 方法（构造方法、普通方法） |
| total     | 调用次数                   |
| success   | 成功次数                   |
| fail      | 失败次数                   |
| rt        | 平均RT                     |
| fail-rate | 失败率                     |

6. 观察方法的入参和出参

> watch com.elab.marketing.auth.service.impl.ElaberServiceImpl elabLogin "{params,returnObj}" -x 3

{params,returnObj} : 出参入参 ,只要是一个合法的 ognl 表达式，都能被正常支持

-x 遍历深度，例如-2 表示对象级别 -3 就是对象的属性级别

这里面还包括了满足条件才打印、异常信息等等，非常强大

https://alibaba.github.io/arthas/watch.html

7. 查看方法调用的耗时情况

> trace com.elab.marketing.auth.service.impl.ElaberServiceImpl elabLogin

```tex
`---ts=2018-09-18 15:24:08;thread_name=http-nio-5301-exec-2;id=5c;is_daemon=true;priority=5;TCCL=org.springframework.boot.context.embedded.tomcat.TomcatEmbeddedWebappClassLoader@2fe53885
    `---[13.219132ms] com.elab.marketing.auth.service.impl.ElaberServiceImpl$$EnhancerBySpringCGLIB$$6886b0e2:elabLogin()
        `---[13.027645ms] org.springframework.cglib.proxy.MethodInterceptor:intercept()
            `---[8.421019ms] com.elab.marketing.auth.service.impl.ElaberServiceImpl:elabLogin()
                +---[0.015018ms] com.ecloud.common.dto.response.ObjectResponseModel:<init>()
                +---[0.004096ms] com.elab.marketing.auth.service.request.ElaberRequest:getAccountNo()
                +---[0.002731ms] com.elab.marketing.auth.service.request.ElaberRequest:getPassword()
                +---[0.002731ms] com.elab.marketing.auth.dao.entity.ElaberEntity:<init>()
                +---[0.002389ms] com.elab.marketing.auth.dao.entity.ElaberEntity:setAccountNo()
                +---[0.035498ms] java.io.PrintStream:println()
                +---[6.268917ms] com.elab.marketing.auth.dao.IElaberDao:selectElaberLogin()
                +---[0.006144ms] com.elab.marketing.auth.service.response.ElabAccountResponse:<init>()
                +---[0.003072ms] com.elab.marketing.auth.dao.entity.ElaberEntity:getAccountPwd()
                +---[0.014677ms] java.lang.String:equals()
                +---[1.780733ms] com.elab.core.spring.common.utils.BeanUtils:copyProperties()
                `---[0.007168ms] com.ecloud.common.dto.response.ObjectResponseModel:setSingle()
```

8. 查看当前方法被调用的路径

> stack com.elab.marketing.auth.service.impl.ElaberServiceImpl elabLogin

![1537256219093](C:\Users\DELL\AppData\Local\Temp\1537256219093.png)



9. 