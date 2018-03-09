# JVM相关命令适用介绍



> pid 进程号



## jinfo 

> 可以查看一些JVM参数,也可以设置一些JVM参数

- 查看jvm配置参数

```
jinfo -flags pid
```

- 查看java系统参数

```
jinfo -sysprops pid
```

- 查看GC日志文件大小

```
jinfo -flag GCLogFileSize  pid
// 查看新生代晋升老年代的年龄值
jinfo -flag MaxTenuringThreshold pid
```

- 打开GC的一些配置参数

```
jinfo -flag+PrintGCDetails pid
jinfo -flag+PrintGC pid
```

