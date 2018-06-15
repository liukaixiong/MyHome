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



## jstat

jstat -gc 30544 60000 -> 每分钟打印一次GC情况

- `s0` : **Heap上的 Survivor space 0 区已使用空间的百分比**   
- `s1` :  **Heap上的 Survivor space 1 区已使用空间的百分比** 
- `E` : **Heap上的 Eden space 区已使用空间的百分比** 
- `O` : **Heap上的 Old space 区已使用空间的百分比** 
- `P` :  **Perm space 区已使用空间的百分比**  
- `YGC` : **从应用程序启动到采样时发生 Young GC 的次数**  
- `YGCT` : **从应用程序启动到采样时 Young GC 所用的时间(单位秒)     FGC — 从应用程序启动到采样时发生 Full GC 的次数**  
- `FGCT`- **从应用程序启动到采样时 Full GC 所用的时间(单位秒)     GCT — 从应用程序启动到采样时用于垃圾回收的总时间(单位秒)**  
- 