java并发采用的是共享内存模型，线程之间的通信对程序员来说是透明的，内存可见性问题很容易困扰着java程序员，今天我们就来揭开java内存模型的神秘面纱。

---
在揭开面纱之前，我们需要认识几个基础概念：内存屏障（memory Barriers），指令重排序，happens-before规则，as-if-serial语义。

---
#### 什么是 Memory Barrier（内存屏障）？

```
内存屏障，又称内存栅栏，是一个CPU指令，基本上它是一条这样的指令：
1、保证特定操作的执行顺序。
2、影响某些数据（或则是某条指令的执行结果）的内存可见性。
```
编译器和CPU能够重排序指令，保证最终相同的结果，尝试优化性能。插入一条Memory Barrier会告诉编译器和CPU：不管什么指令都不能和这条Memory Barrier指令重排序。

**Memory Barrier所做的另外一件事是强制刷出各种CPU cache，如一个 Write-Barrier（写入屏障）将刷出所有在 Barrier 之前写入 cache 的数据，因此，任何CPU上的线程都能读取到这些数据的最新版本。**


![image](http://upload-images.jianshu.io/upload_images/2184951-ad0094fa98e6cda0.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

这和java有什么关系？**volatile是基于Memory Barrier实现的**。

#### volatile关键字的作用?
用volatile关键字修饰的变量在多个线程之间相互共享,并且可以同时操作,也会被其他线程所看到.
JMM,插入一个Write-Barrier指令,并且在读这个字段之前插入一个Read-barrier指令

![image](http://upload-images.jianshu.io/upload_images/2184951-6b466ec6493b0a4f.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

这样的话就保证了:
​    
- 当一个线程对Volatile变量进行写入时,任何线程都能访问到操作后的变量值
- 在写入变量之前,其更新的数据对其他线程也是可见的.因为memory Barrier会刷出cache之前所有的写入操作.
- ​

## JVM内存分为那几个区?每个区的作用是什么?
1. 堆
   所有线程共享的一块内存,在虚拟机启动的时候创建,几乎存放了所有的对象的创建,因此这里也是GC回收比较频繁的区域.
2. 虚拟机栈 - 栈内存
   - 他为java方法服务,每个方法在执行的时候都会创建一个桢,用于存放局部变量表,操作数栈、动态连接和方法出口的信息
   - 每个方法从被调用开始到执行结束就对应一个栈帧在虚拟中从入栈到出栈的过程
   - 虚拟机栈是私有的,它的生命周期和线程相关
   - 局部变量表里存储的是基本数据类型,returnAddress类型(指向一条字节码指令的地址)和对象的引用,这个对象的引用是指向对象起始地址的一个指针,其实就是堆内存的位置.

3.本地方法栈
-    和虚拟机栈差不多,主要为java提供操作native方法服务。
-    本地方法栈与虚拟机栈所发挥的作用类似，唯一的区别是，虚拟机栈是为虚拟机运行java方法服务，而本地方法栈是为虚拟机使用到Native方法服务。本地方法栈也会抛出StackOverflowError和OutOfMemoryError异常。

4.方法区
​    