### 前言

看着上一篇的更新时间，发现已经挺长时间没有提笔了，只能以忙为自己开脱了，如果太闲都不好意思说自己是程序猿了，正好今天有人问了我一个问题：

当一个共享变量被volatile修饰时，它会保证修改的值立即被更新到主存“， 这里的”保证“ 是如何做到的？和 JIT的具体编译后的CPU指令相关吧？
最一开始碰到volatile，我的内心是拒绝的，因为当时做的项目中没有用到，也不清楚可以在什么场景下使用，所以希望这篇文章可以帮助大家理解volatile关键字。

### volatile特性

内存可见性：通俗来说就是，线程A对一个volatile变量的修改，对于其它线程来说是可见的，即线程每次获取volatile变量的值都是最新的。

### volatile的使用场景

通过关键字sychronize可以防止多个线程进入同一段代码，在某些特定场景中，volatile相当于一个轻量级的sychronize，因为不会引起线程的上下文切换，但是使用volatile必须满足两个条件：  
1、对变量的写操作不依赖当前值，如多线程下执行a++，是无法通过volatile保证结果准确性的[==因为它经过了三个步骤:读取>修改>写入 这三个步骤都是没有加锁的,所以操作时会出现问题,俗称竟态条件==]；  
2、该变量没有包含在具有其它变量的不变式中，这句话有点拗口，看代码比较直观。
```
public class NumberRange {
    private volatile int lower = 0;
    private volatile int upper = 10;

    public int getLower() { return lower; }
    public int getUpper() { return upper; }

    public void setLower(int value) { 
        if (value > upper) 
            throw new IllegalArgumentException(...);
        lower = value;
    }
    
    // 假设B线程设置了setUpper这个值为0,而A线程设置了setLower为1,
    //那么他的范围[1,0] 范围便成了无效范围,所以需要通过synchronized
    public void setUpper(int value) { 
        if (value < lower) 
            throw new IllegalArgumentException(...);
        upper = value;
    }
}
```
上述代码中，上下界初始化分别为0和10，假设线程A和B在某一时刻同时执行了setLower(8)和setUpper(5)，且都通过了不变式的检查，设置了一个无效范围（8, 5），所以在这种场景下，需要通过sychronize保证方法setLower和setUpper在每一时刻只有一个线程能够执行。

> 下面是我们在项目中经常会用到volatile关键字的两个场景：

1、状态标记量
在高并发的场景中，通过一个boolean类型的变量isopen，控制代码是否走促销逻辑，该如何实现？
```
public class ServerHandler {
    // 因为volatile是所有线程可见的,所以一旦修改这个值,
    //其他线程马上就能看到,就可以执行指定的逻辑
    private volatile isopen;
    public void run() {
        if (isopen) {
           //促销逻辑
        } else {
          //正常逻辑
        }
    }
    public void setIsopen(boolean isopen) {
        this.isopen = isopen
    }
}
```
场景细节无需过分纠结，这里只是举个例子说明volatile的使用方法，用户的请求线程执行run方法，如果需要开启促销活动，可以通过后台设置，具体实现可以发送一个请求，调用setIsopen方法并设置isopen为true，由于isopen是volatile修饰的，所以一经修改，其他线程都可以拿到isopen的最新值，用户请求就可以执行促销逻辑了。

2、double check  
单例模式的一种实现方式，但很多人会忽略volatile关键字，因为没有该关键字，程序也可以很好的运行，只不过代码的稳定性总不是100%，说不定在未来的某个时刻，隐藏的bug就出来了。
```
class Singleton {
    // 我的理解是
    /**
        当A线程和B线程同时调用这个getInstance方法时,首先会获取instance这个对象的副本.
        
    */
    private volatile static Singleton instance;
    public static Singleton getInstance() {
        if (instance == null) {
            syschronized(Singleton.class) {
                if (instance == null) {
                    instance = new Singleton();
                }
            }
        }
        return instance;
    } 
}
```
不过在众多单例模式的实现中，我比较推荐懒加载的优雅写法Initialization on Demand Holder（IODH）。
```
public class Singleton {  
    static class SingletonHolder {  
        static Singleton instance = new Singleton();  
    }  

    public static Singleton getInstance(){  
        return SingletonHolder.instance;  
    }  
}
```
当然，如果不需要懒加载的话，直接初始化的效果更好。

如何保证内存可见性？

在java虚拟机的内存模型中，有主内存和工作内存的概念，每个线程对应一个工作内存，并共享主内存的数据，下面看看操作普通变量和volatile变量有什么不同：

1、**对于普通变量**：读操作会优先读取工作内存的数据，如果工作内存中不存在，则从主内存中拷贝一份数据到工作内存中；写操作只会修改工作内存的副本数据，这种情况下，其它线程就无法读取变量的最新值。

2、**对于volatile变量**，读操作时JMM会把工作内存中对应的值设为无效，要求线程从主内存中读取数据；写操作时JMM会把工作内存中对应的数据刷新到主内存中，这种情况下，其它线程就可以读取变量的最新值。

volatile变量的内存可见性是基于**内存屏障(Memory Barrier)**实现的，什么是内存屏障？内存屏障，又称内存栅栏，是一个CPU指令。在程序运行时，为了提高执行性能，编译器和处理器会对指令进行重排序，JMM为了保证在不同的编译器和CPU上有相同的结果，通过插入特定类型的内存屏障来禁止特定类型的编译器重排序和处理器重排序，插入一条内存屏障会告诉编译器和CPU：==不管什么指令都不能和这条Memory Barrier指令重排序。==

这段文字显得有点苍白无力，不如来段简明的代码：
```
class Singleton {
    private volatile static Singleton instance;
    private int a;
    private int b;
    private int b;
    public static Singleton getInstance() {
        if (instance == null) {
            syschronized(Singleton.class) {
                if (instance == null) {
                    a = 1;  // 1
                     b = 2;  // 2
                    instance = new Singleton();  // 3
                    c = a + b;  // 4
                }
            }
        }
        return instance;
    } 
}
```
1、如果变量instance没有volatile修饰，语句1、2、3可以随意的进行重排序执行，即指令执行过程可能是3214或1324。
2、如果是volatile修饰的变量instance，会在语句3的前后各插入一个内存屏障。

通过观察volatile变量和普通变量所生成的汇编代码可以发现，操作volatile变量会多出一个**lock前缀指令**：

Java代码：
instance = new Singleton();

汇编代码：
0x01a3de1d: movb $0x0,0x1104800(%esi);
0x01a3de24: **lock** addl $0x0,(%esp);  
这个lock前缀指令相当于上述的内存屏障，提供了以下保证：  
1、将当前CPU缓存行的数据写回到主内存；  
2、这个写回内存的操作会导致在其它CPU里缓存了该内存地址的数据无效。

CPU为了提高处理性能，并不直接和内存进行通信，而是将内存的数据读取到内部缓存（L1，L2）再进行操作，但操作完并不能确定何时写回到内存.    

如果对volatile变量进行写操作，当CPU执行到Lock前缀指令时，会将这个变量所在缓存行的数据写回到内存，不过还是存在一个问题，就算内存的数据是最新的，其它CPU缓存的还是旧值.  

所以为了保证各个CPU的缓存一致性，每个CPU通过**嗅探**在总线上传播的数据来检查自己缓存的数据有效性，当发现自己缓存行对应的内存地址的数据被修改，就会将该缓存行设置成无效状态，当CPU读取该变量时，发现所在的缓存行被设置为无效，就会重新从内存中读取数据到缓存中。

作者：占小狼
链接：http://www.jianshu.com/p/195ae7c77afe
來源：简书
著作权归作者所有。商业转载请联系作者获得授权，非商业转载请注明出处。