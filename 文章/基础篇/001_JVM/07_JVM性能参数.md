# 性能关注点

[纯洁的微笑 - 优化篇](https://www.cnblogs.com/ityouknow/p/7653129.html)

## GC优化点

**需要关注的方向**

- 将进入老年代的对象降到最低
  - 提高进入老年代的门槛`-XX:MaxTenuringThreshold=30` , 表示只有经过了30次GC之后还活着，才会进入老年代。
- 降低Full GC的时间
  - full GC 触发的条件就是老年代的内存不够，需要将老年代的大小调大



### 影响GC性能的参数

- 堆的大小
  - -Xms : 启动JVM时初始化堆内存的大小
  - -Xmx:  堆内存的最大限制

- 新生代空间的大小
  - -XX:NewRatio	: 新生代和老年代的内存比，=1 表示1：1 、 =2表示 1：2 ，也就是说这个值越大，老年代的比例越高
  - -XX:NewSize  :  新生代的内存大小
  - -XX:SurvivorRatio : Eden区和Survivor区的内存比 

> 只有出现OutOfMemoryError异常时，才需要去设置永久代的内存

- 垃圾收集器的类型

| GC类型                   | 参数                                                         | 备注                            |      |
| ------------------------ | ------------------------------------------------------------ | ------------------------------- | ---- |
| Serial GC                | -XX:+UseSerialGC                                             | 串行收集器                      |      |
| Parallel GC              | -XX:UseParallelGC                                            | 并行收集器                      |      |
| Parallel   Compacting GC | -XX:+UseParallelOldGC                                        |                                 |      |
| CMS GC                   | -XX:+UseConcMarkSweepGC -XX:+UseParNewGC -XX:+CMSParallelRemarkEnabled -XX:CMSInitiatingOccupancyFraction=value -XX:+UseCMSInitiatingOccupancyOnly |                                 |      |
| G1                       | -XX:+UnlockExperimentalVMOptions -XX:+UseG1GC                | 在JDK 6中这两个参数必须配合使用 |      |

![img](https://img.alicdn.com/tfs/TB1z9BsRFXXXXXzXVXXXXXXXXXX-865-704.png)

### **是否优化的标准**

1. **Minor GC**执行非常迅速（**50ms以内**）
2. **Minor GC** 没有频繁GC (**大约10s执行一次**)
3. **Full GC**执行非常迅速(**1s以内**)
4. **Full GC**没有频繁执行 (**10分钟执行一次**)

### 优化步骤

**通过命令行**

1. 使用`jstat -gcutil $pid 毫秒数` 在服务器上获取结果

**通过日志**

打印日志

> GC_LOG_PATH=$APP_HOME/logs/start-logs/gc-$APP_NAME-$ADATE.log
>
> XX:+HeapDumpOnOutOfMemoryError -XX:+PrintGCDateStamps -Xloggc:$GC_LOG_PATH -XX:+PrintGCDetails

将日志下载下来之后登陆http://gceasy.io,将日志文件上传上去进行分析



**通过监控平台**

通过**CAT** 或者 **prometheus** 等可以监控应用的数据

# 性能参数

[参考文章](http://calvin1978.blogcn.com/articles/jvmoption-7.html)



## -XX:+PrintFlagsFinal

打印参数值



## -XX:AutoBoxCacheMax=20000

Integer i = 3;

这语句有着自动装箱成Integer的过程，jdk默认只缓存了-128~127的数据，超出范围的数字就要及时构建新的对象。

**为什么是20000?**

因为**-XX:+AggressiveOpts**里也是这个值。



## -XX:MaxTenuringThreshold=2

Young GC熬过多少次GC之后会升级到老年代。

CMS 是 6 , G1的是 15 .

Young GC是最大的应用停顿来源，而新生代里GC后存活对象的多少又直接影响停顿的时间，所以如果清楚Young GC的执行频率和应用里大部分临时对象的最长生命周期，可以把它设的更短一点，让其实不是临时对象的新生代对象赶紧晋升到年老代，别呆着。

用-XX:+PrintTenuringDistribution观察下，如果后面几代的大小总是差不多，证明过了某个年龄后的对象总能晋升到老生代，就可以把晋升阈值设小，比如JMeter里2就足够了。

## -XX:+ExplicitGCInvokesConcurrent

full gc时，使用CMS算法，不是全程停顿，必选。

但像R大说的，System GC是保护机制（如堆外内存满时清理它的堆内引用对象），禁了system.gc() 未必是好事，只要没用什么特别烂的类库，真有人调了总有调的原因，所以不应该加这个烂大街的参数。





