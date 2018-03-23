## jmap

### heap

查看当前应用下面的内存分布情况

**使用方式**:

```tex
jmap -heap [pid]
```

**得到反馈**:

```java
Attaching to process ID 2020, please wait...
Debugger attached successfully.
Server compiler detected.
JVM version is 24.65-b04

using thread-local object allocation.
Mark Sweep Compact GC

Heap Configuration:
   // 最小堆的适用比例
   MinHeapFreeRatio = 40
   //对应jvm启动参数 -XX:MaxHeapFreeRatio设置JVM堆最大空闲比率(default 70)
   MaxHeapFreeRatio = 70				
   //对应jvm启动参数-XX:MaxHeapSize=设置JVM堆的最大大小
   MaxHeapSize      = 536870912 (512.0MB)
   //对应jvm启动参数-XX:NewSize=设置JVM堆的‘新生代’的默认大小
   NewSize          = 1310720 (1.25MB)
   //对应jvm启动参数-XX:MaxNewSize=设置JVM堆的‘新生代’的最大大小
   MaxNewSize       = 17592186044415 MB
   //对应jvm启动参数-XX:OldSize=<value>:设置JVM堆的‘老生代’的大小
   OldSize          = 5439488 (5.1875MB)
   //对应jvm启动参数-XX:NewRatio=:‘新生代’和‘老生代’的大小比率
   NewRatio         = 2
   //对应jvm启动参数-XX:SurvivorRatio=设置年轻代中Eden区与Survivor区的大小比值
   SurvivorRatio    = 8
   //对应jvm启动参数-XX:PermSize=<value>:设置JVM堆的‘永生代’的初始大小
   PermSize         = 536870912 (512.0MB)
   //对应jvm启动参数-XX:MaxPermSize= :设置JVM堆的‘永生代’的最大大小
   MaxPermSize      = 536870912 (512.0MB)
   // G1区域大小
   G1HeapRegionSize = 0 (0.0MB)

Heap Usage:
New Generation (Eden + 1 Survivor Space):
   capacity = 161021952 (153.5625MB)
   used     = 145838912 (139.08282470703125MB)
   free     = 15183040 (14.47967529296875MB)
   90.57082602004478% used
Eden Space:		// eden区使用情况
   // 总容量
   capacity = 143130624 (136.5MB)
   // 已使用的容量
   used     = 143130624 (136.5MB)
   // 可用容量
   free     = 0 (0.0MB)
   100.0% used
From Space:				// Survivor 0 区域
   // 总容量
   capacity = 17891328 (17.0625MB)
   // 已使用的容量
   used     = 2708288 (2.58282470703125MB)
   // 可用容量
   free     = 15183040 (14.47967529296875MB)
   // 使用比例
   15.13743418040293% used
To Space:					// Survivor 1 区域
	// 总容量
   capacity = 17891328 (17.0625MB)
     // 使用容量
   used     = 0 (0.0MB)
     // 可用容量
   free     = 17891328 (17.0625MB)
     // 使用率
   0.0% used
tenured generation:			// 老年代
	// 总容量
   capacity = 357957632 (341.375MB)
     // 使用容量
   used     = 357957624 (341.37499237060547MB)
     // 可用容量
   free     = 8 (7.62939453125E-6MB)
     // 适用比率
   99.99999776509864% used
Perm Generation:			// 永久带
	// 容量
   capacity = 536870912 (512.0MB)
     // 已使用容量
   used     = 60177968 (57.39018249511719MB)
     // 可用容量
   free     = 476692944 (454.6098175048828MB)
     // 适用比例
   11.209020018577576% used

23806 interned Strings occupying 2450984 bytes.
```



### histo  

查看JVM堆中对象详细占用情况

第一列，序号。无实际意义

第二列，对象实例数量

第三列，对象实例占用总内存数。单位：字节

第四列，对象实例名称

最后一行，总实例数量与总内存占用数





### dump:format=b,file=文件名

导出当前应用的jvm堆情况

**使用**

```java
jmap -dump:format=b,file=dump.hprof [pid]
```



## jstat

### 查看垃圾回收使用情况

```tex
jstat -gc 12783 5000
```

12783 -> pid
5000 	-> 间隔毫秒数

```tex
		  S0C：年轻代中第一个survivor（幸存区）的容量 (字节) 
         S1C：年轻代中第二个survivor（幸存区）的容量 (字节) 
         S0U：年轻代中第一个survivor（幸存区）目前已使用空间 (字节) 
         S1U：年轻代中第二个survivor（幸存区）目前已使用空间 (字节) 
         EC：年轻代中Eden（伊甸园）的容量 (字节) 
         EU：年轻代中Eden（伊甸园）目前已使用空间 (字节) 
         OC：Old代的容量 (字节) 
         OU：Old代目前已使用空间 (字节) 
         PC：Perm(持久代)的容量 (字节) 
         PU：Perm(持久代)目前已使用空间 (字节) 
         YGC：从应用程序启动到采样时年轻代中gc次数 
         YGCT：从应用程序启动到采样时年轻代中gc所用时间(s) 
         FGC：从应用程序启动到采样时old代(全gc)gc次数 
         FGCT：从应用程序启动到采样时old代(全gc)gc所用时间(s) 
         GCT：从应用程序启动到采样时gc用的总时间(s) 
         NGCMN：年轻代(young)中初始化(最小)的大小 (字节) 
         NGCMX：年轻代(young)的最大容量 (字节) 
         NGC：年轻代(young)中当前的容量 (字节) 
         OGCMN：old代中初始化(最小)的大小 (字节) 
         OGCMX：old代的最大容量 (字节) 
         OGC：old代当前新生成的容量 (字节) 
         PGCMN：perm代中初始化(最小)的大小 (字节) 
         PGCMX：perm代的最大容量 (字节)   
         PGC：perm代当前新生成的容量 (字节) 
         S0：年轻代中第一个survivor（幸存区）已使用的占当前容量百分比 
         S1：年轻代中第二个survivor（幸存区）已使用的占当前容量百分比 
         E：年轻代中Eden（伊甸园）已使用的占当前容量百分比 
         O：old代已使用的占当前容量百分比 
         P：perm代已使用的占当前容量百分比 
         S0CMX：年轻代中第一个survivor（幸存区）的最大容量 (字节) 
         S1CMX ：年轻代中第二个survivor（幸存区）的最大容量 (字节) 
         ECMX：年轻代中Eden（伊甸园）的最大容量 (字节) 
         DSS：当前需要survivor（幸存区）的容量 (字节)（Eden区已满） 
         TT： 持有次数限制 
         MTT ： 最大持有次数限制 
```

## 查看内存使用情况

### **查看应用总使用内存**

```te
> pmap [pid]
```

第一列。内存块起始地址

第二列。占用内存大小

第三列，内存权限

第四列。内存名称。anon表示动态分配的内存，stack表示栈内存

最后一行。占用内存总大小，请注意，此处为虚拟内存大小，占用的物理内存大小能够通过top查看



## linux

**linux下获取占用CPU资源最多的10个进程，可以使用如下命令组合：**

```tex
ps aux|head -1;ps aux|grep -v PID|sort -rn -k +3|head
```

**linux下获取占用内存资源最多的10个进程，可以使用如下命令组合：**

```tex
ps aux|head -1;ps aux|grep -v PID|sort -rn -k +4|head
```

**命令组合解析（针对CPU的，MEN也同样道理）：**

```tex
ps aux|head -1;ps aux|grep -v PID|sort -rn -k +3|head
```

**该命令组合实际上是下面两句命令：**

```tex
ps aux|head -1

ps aux|grep -v PID|sort -rn -k +3|head
```

**查看占用cpu最高的进程**

```tex
ps aux|head -1;ps aux|grep -v PID|sort -rn -k +3|head
```

**补充:内容解释**

PID：进程的ID
USER：进程所有者
PR：进程的优先级别，越小越优先被执行
NInice：值
VIRT：进程占用的虚拟内存
RES：进程占用的物理内存
SHR：进程使用的共享内存
S：进程的状态。S表示休眠，R表示正在运行，Z表示僵死状态，N表示该进程优先值为负数
%CPU：进程占用CPU的使用率
%MEM：进程使用的物理内存和总内存的百分比
TIME+：该进程启动后占用的总的CPU时间，即占用CPU使用时间的累加值。
COMMAND：进程启动命令名称

 https://www.cnblogs.com/sparkbj/p/6148817.html

