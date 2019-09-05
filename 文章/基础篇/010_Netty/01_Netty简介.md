## 什么是Netty?

- Netty是一个使用Java网络编程框架。
- 基于网络编程的封装

## Netty和Tomcat的区别?

tomcat

- 基于Http协议的，实质上是一个http协议的web容器。

Netty

- 基于各种协议的封装。
- 通过codec自己来编码/解码字节流，完成类似redis访问的功能。

## 传统RPC调用性能差的三宗罪

1. 阻塞IO不具备弹性伸缩能力，高并发导致宕机
2. Java序列化编解码性能问题。
3. 传统IO线程模型过多占用CPU资源

## Netty的优势?

- 并发高 : 基于NIO开发的网络通信框架，对比阻塞IO，性能得到很大的提升。
- 传输快：**零拷贝**，java中的内存有堆内存和栈内存和字符串常量池等等，其中堆内存是占用内存空间最大的一块，也是java对象存放的地方，一般我们的数据如果需要从IO读取到堆内存中，中间需要经过Socket缓冲区，也就是说一个数据会被拷贝两次才会到达它的终点，如果数据量大，就会造成不必要的资源浪费。而零拷贝是指：**当它需要接受数据的时候，他会在堆内存之外开辟一块内存，数据就直接从IO读到那块内存中去，在Netty里面通过ByteBuff直接对这些数据进行操作，从而加快了传输速度。**
- 封装好：
  - Channel : 数据传输流。
    - Channel:表示一个连接，可以理解为每一个请求，就是一个Channel。
    - ChannelHandler：核心处理业务就在这里，用于处理业务请求。
    - ChannelHandlerContext：用于传输业务数据。
    - ChannelPipeline:用于保存处理过程中要用到的ChannelHandler和ChannelHandlerContext。

![img](https://upload-images.jianshu.io/upload_images/1089449-afd9e14197e1ef11.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/700) 

- ByteBuf : 存储字节的容器，特点就是使用方便。有自己的读索引和写索引，方便你对整个字节缓冲进行读写。

三种缓冲区的使用模式：

	- heap Buffer 堆缓冲区

堆缓冲区是ByteBuf最常用的模式，他将数据存储在堆空间。

- Direct Buffer 直接缓冲区

  直接缓冲区是ByteBuf的另外一种常用模式，他的内存分配都不发生在堆，jdk1.4引入的nio的ByteBuffer类允许jvm通过本地方法调用分配内存，这样做有两个好处 

  - 通过免去中间交换的内存拷贝, 提升IO处理速度; 直接缓冲区的内容可以驻留在垃圾回收扫描的堆区以外。
  - DirectBuffer 在 -XX:MaxDirectMemorySize=xxM大小限制下, 使用 Heap 之外的内存, GC对此”无能为力”,也就意味着规避了在高负载下频繁的GC过程对应用线程的中断影响.

- Composite Buffer 复合缓冲区

复合缓冲区相当于多个不同ByteBuf的视图，这是netty提供的，jdk不提供这样的功能。

 

 

##  Netty 三件套

### 缓冲区Buffer

#### position

 被写入或者读取的元素索引，值由get()/out()自动更新，被初始值为0；

当前所操作的位置，根据读取或者写入发生变化。

#### limit

指定还有多少数据需要取出(在缓冲区写入通道时)，或者还有多少空间可以放入数据（在从通道读入缓冲区时）。

#### capacity

缓冲区中的最大数据容量.

**缓冲区的意义**

对byte进行封装，更加方便快捷的操作数据。



**直接缓冲区**

ByteBuffer

不经过JVM内存，直接去操作系统内存。直接减少了将堆外内存拷贝到JVM内存中。

提高IO速度，但是会影响到对象回收。因为JVM内存只是保存它的引用，但并非对象实例。



**IO映射缓冲区**

MappedByteBuffer

把文件读进来，在内存中改变数据，并直接在文件中体现出来，不需要写。

### selector

调度器，总控中心。

主线程去分配各种worker线程，根据事件去分发。



![img](https://segmentfault.com/img/remote/1460000015484191)

## Channel

传输通道。



## 



## 多路复用



### select



### poll



### epoll



### kqueue



## 线程模型

参考文章:https://blog.csdn.net/u010623927/article/details/87948212

### 单线程模型

![img](https://images2017.cnblogs.com/blog/285763/201801/285763-20180123121112287-1483895090.png)

### 多线程模型

![img](https://images2017.cnblogs.com/blog/285763/201801/285763-20180123121127162-471886539.png)



### 主从线程模型

![img](https://images2017.cnblogs.com/blog/285763/201801/285763-20180123121145006-1931312241.png)