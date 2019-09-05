## 概念  
> CAS(compare and swap)，比较和交换，是原子操作的一种，可用于在多线程编程中实现不被打断的数据交换操作，从而避免多线程同时改写某一数据时由于执行顺序不确定性以及中断的不可预知性产生的数据不一致问题。 该操作通过将内存中的值与指定数据进行比较，当数值一样时将内存中的数据替换为新的值  
> **现代的大多数CPU都实现了CAS,它是一种==无锁==(lock-free),且==非阻塞==的一种算法，保持数据的一致性**


# 1.java中的原子性操作
##     1.1java如何实现原子性操作的
        在java中通过锁和循环cas的方式实现原子操作
##        2.1cas是如何实现的
        jvm中的CAS操作是基于处理器的CMPXCHG指令实现的
    CAS有三个操作数：
    内存值V、旧的预期值A、要修改的值B。，
    当且仅当预期值A和内存值V相同时，将内存值修改为B并返回true，
    否则什么都不做并返回false
```
实现分析:
public int a = 1;
public boolean compareAndSwapInt(int b) {
    if (a == 1) {
        a = b;
        return true;
    }
    return false;
}
```

### cas步骤还原:
- 需要传递三个参数 1.当前线程中获取的旧值 2.新值 3.内存地址中的值
- 循环比较旧值和内存地址中的值,直到比较成功为止,即使失败,旧值是用volatile修饰的,保证一旦发生改变,能够被其他线程所察觉.然后再进行比较

##           2.1.1CAS存在的3个问题
            ABA问题 : 当两个线程同时操作数据A时,当线程1操作数据A之后将值改为了B,后面又改成了A,这时候Cas默认还是值是没有改变的
​            


##             java中的AtomicInteger的原子操作

```
java.util.concurrent.atomic包下的原子操作类都是基于CAS实现的，接下去我们通过AtomicInteger来看看是如何通过CAS实现原子操作的：

public class AtomicInteger extends Number implements java.io.Serializable {
    // setup to use Unsafe.compareAndSwapInt for updates
    private static final Unsafe unsafe = Unsafe.getUnsafe();
    private static final long valueOffset;

    static {
        try {
            valueOffset = unsafe.objectFieldOffset
                (AtomicInteger.class.getDeclaredField("value"));
        } catch (Exception ex) { throw new Error(ex); }
    }
    // 可见性,为了在多线程环境中能看到最新的值
    private volatile int value;
    public final int get() {return value;}
}
1. Unsafe是CAS的核心类，Java无法直接访问底层操作系统，而是通过本地（native）方法来访问。不过尽管如此，JVM还是开了一个后门，JDK中有一个类Unsafe，它提供了硬件级别的原子操作。
2. valueOffset表示的是变量值在内存中的偏移地址，因为Unsafe就是根据内存偏移地址获取数据的原值的。
3. value是用volatile修饰的，保证了多线程之间看到的value值是同一份。

```
接下去，我们看看AtomicInteger是如何实现并发下的累加操作：


```
//jdk1.8实现
public final int getAndAdd(int delta) {    
    return unsafe.getAndAddInt(this, valueOffset, delta);
}

public final int getAndAddInt(Object var1, long var2, int var4) {
    int var5;
    do {
        var5 = this.getIntVolatile(var1, var2);
    } while(!this.compareAndSwapInt(var1, var2, var5, var5 + var4));
    return var5;
}
```

在jdk1.8中，比较和替换操作放在unsafe类中实现。

假设现在线程A和线程B同时执行getAndAdd操作：

1. AtomicInteger里面的value原始值为3，即主内存中AtomicInteger的value为3，根据Java内存模型，线程A和线程B各自持有一份value的副本，值为3。
2. 线程A通过getIntVolatile(var1, var2)方法获取到value值3，线程切换，线程A挂起。
3. 线程B通过getIntVolatile(var1, var2)方法获取到value值3，并利用compareAndSwapInt方法比较内存值也为3，比较成功，修改内存值为2，线程切换，线程B挂起。
4. 线程A恢复，利用compareAndSwapInt方法比较，发手里的值3和内存值4不一致，此时value正在被另外一个线程修改，线程A不能修改value值。
5. 线程的compareAndSwapInt实现，循环判断，重新获取value值，**因为value是volatile变量，所以线程对它的修改，线程A总是能够看到**。线程A继续利用compareAndSwapInt进行比较并替换，直到compareAndSwapInt修改成功返回true。

整个过程中，利用CAS保证了对于value的修改的线程安全性。

# Unsafe的compareAndSwapInt方法做了哪些操作?

```
public final native boolean compareAndSwapInt(Object paramObject, long paramLong, int paramInt1, int paramInt2);
```
可以看到，这是一个本地方法调用，这个本地方法在openjdk中依次调用c++代码：unsafe.cpp，atomic.cpp，atomic_window_x86.inline.hpp。下面是对应于intel X86处理器的源代码片段。

```
inline jint Atomic::cmpxchg (jint exchange_value, volatile jint* dest, jint compare_value) {
    int mp = os::isMP(); //判断是否是多处理器
    _asm {
        mov edx, dest
        mov ecx, exchange_value
        mov eax, compare_value
        LOCK_IF_MP(mp)
        cmpxchg dword ptr [edx], ecx
    }
}
```
- 如果是多处理器，为cmpxchg指令添加lock前缀。
- 反之，就省略lock前缀。（单处理器会不需要lock前缀提供的内存屏障效果）
  intel手册对lock前缀的说明如下：

1. 确保对内存读改写操作的原子执行。
    在Pentium及之前的处理器中，带有lock前缀的指令在执行期间会锁住总线，使得其它处理器暂时无法通过总线访问内存，很显然，这个开销很大。在新的处理器中，Intel使用缓存锁定来保证指令执行的原子性。缓存锁定将大大降低lock前缀指令的执行开销。
2. 禁止该指令，与前面和后面的读写指令重排序。
3. 把写缓冲区的所有数据刷新到内存中。

上面的第2点和第3点所具有的内存屏障效果，保证了CAS同时具有volatile读和volatile写的内存语义。

# CAS缺点

CAS存在一个很明显的问题，即ABA问题。
如果变量V初次读取的时候是A，并且在准备赋值的时候检查到它仍然是A，那能说明它的值没有被其他线程修改过了吗？如果在这段期间它的值曾经被改成了B，然后又改回A，那CAS操作就会误认为它从来没有被修改过。针对这种情况，java并发包中提供了一个带有标记的原子引用类"AtomicStampedReference"，它可以通过控制变量值的版本来保证CAS的正确性。

[关于ABA问题参考](http://www.cnblogs.com/java20130722/p/3206742.html)

[参考占小狼博客](http://www.jianshu.com/p/fb6e91b013cc?utm_campaign=maleskine&utm_content=note&utm_medium=pc_all_hots&utm_source=recommendation)