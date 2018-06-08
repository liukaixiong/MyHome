---
typora-copy-images-to: ..\..\..\image\wz_img
---

# head first 设计模式整理



[原地址](https://www.imooc.com/article/11927?block_id=tuijian_wz)

### 策略模式

链接：http://www.imooc.com/article/11475

#### 原则

1. 找出应用中可能需要变化之处,把他们独立起来,不要和那些不需要变化的整在一起。

2. 针对接口编程，而不是针对实现编程

3. 多用组合，少用继承

   1. 为什么少用继承?

      - 代码在多个子类中重复
        - 比如有的行为是飞，有的是跑，在子类中需要各自去维护
      - 运行时行为不容易改变
        - 一旦大量的类生成了，很难去针对部分做更改
      - 很难知道类的全部行为
        - 比如你定义了行为,但是行为只有在你子类中去实现才知道具体的行为。
      - 改变会牵一发动全身，不容易维护
        - 当你的行为发生改变的时候，所有实现该行为的类可能都需要去改变。

      

策略模式定义了算法组,分别封装起来,让他们之间可以相互替换，此模式让算法的变化独立于使用算法的客户

> 策略模式就是将差异化的东西用接口来描述，接口可以随时替换实现，使之完成不同的功能，根据不同的策略生成最终的具体的产品。
>
> 比如构建一个人物角色:
>
>  	1. 该人物有技能属性 -> 技能有很多种。
> 	2. 该人物肯能够移动 -> 每个人物都能够移动
>
> java 中的sort排序 ， jdk中已经将所有排序的算法全部给你写好了，而你只需要将Comparable的接口实现之后告诉它两个比较大小的(compareTo)实现方法。

### 观察者模式

链接：http://www.imooc.com/article/11579

#### 原则

1. 为了交互对象之间松耦合设计而努力。

观察者模式定义了对象之间的一对多依赖，这样依赖，当每一个对象改变状态时，它的所有依赖者都会受到通知并自动更新。

> 这里的一对多指的是一[生产者]多[消费者],当生产者产生消息的时候,要通知到每个消费者

Observer : 具体的监听者，每个需要监听的类都会被注册到这个类中

Observable : 消息的生产者 ，每当有消息变动时，会触发回调，回调就会通知到每个Observer的实现者

WeatherData : 具体的消息类，继承了Observable类，当自身消息内容发生改变的时候，会触发变动方法。

ForecastDisplay/HeatIndexDisplay/StatisticsDisplay:具体的消息消费者,当被动通知到消息改变时,做各自的业务变化



![观察者的关系图](D:\github\MyHome\image\wz_img\1527231268156.png)

![依赖图](D:\github\MyHome\image\wz_img\1527231465994.png)

### 装饰者模式

1. 类应该对拓展开放，对修改关闭。（开闭原则）
2. **装饰者和被装饰者有相同的超类型**(同源)
3. **你可以使用一个或者多个装饰者包装一个对象**
4. 几人装饰者和被装饰者有相同的超类型,所有在任何需要原始对象(被包装的)场合，可以用装饰过的对象代替它。
5. 装饰者可以在委托和被委托的行为之前之后加上自己的行为,以达到特定的目的
6. 对象可以在任何时候被装饰，所以可以在运行时动态的、不限量地用你喜欢的装饰者对象。

装饰者模式动态地将责任附加到对象上，若要拓展功能，装饰者提供了比集成更有弹性的方案。

> 将特殊的计算方式进行拆分一个小的个体,然后重新组合成业务的规则。

Beverage :具体的业务模型定义

CondimentDecorator : 具体的装饰者,用来装饰调味料的,比如你选择了浓咖啡,然后需要加点mocha.则可以使用Mocah来装饰



![装饰者关系图](D:\github\MyHome\image\wz_img\1527234546516.png)



### 工厂模式

1. 要依赖抽象，而不要依赖具体的实现类(依赖倒置原则)

抽象工厂模式提供一个接口，用于创建相关或依赖对象的家族，而不需要明确指定具体类。

#####  工厂方法模式和抽象工厂的区别?

- 工厂方法是作为一个方法直接挂载在抽象的creator类中的，除了工厂方法外其他的方法外其他的方法都已经具体实现。工厂方法作为抽象方法延后到子类实现
- 抽象工厂在使用场景是创建的不是一个具体的产品,而是一组产品的时候。按照工厂方法的解决思路，就必须要在抽象的creator的类中设置多个工厂方法，这样创建显然不好，所以就将这几个工厂方法抽取到专门的抽象类中，creator类通过组合的方式创建Factory对象来获取工厂方法。

工厂方法用的是继承，抽象工厂用的是组合。工厂方法适用于创建**单个产品**的场景，而抽象工厂则适用于创建**多个产品**的场景。

### 单例模式

1. 确保一个类只有一个实例的存在.,并提供一个全局访问点。

#### 常用的几种实现方式:

 1. ##### 懒汉模式

    禁用构造方法,通过访问静态getInstance获取实例,实例中进行判断是否已经创建过

![1527494996088](D:\github\MyHome\image\wz_img\1527494996088.png)

2. ##### 懒汉(线程安全) 

   将1的方式用synchronized修饰

![1527494981946](D:\github\MyHome\image\wz_img\1527494981946.png)

3. ##### 饿汉

   在构建这个类的时候,就将当前实例初始化。非懒加载

 1. ![1527494970462](D:\github\MyHome\image\wz_img\1527494970462.png)

    4. ##### 饿汉 

       将实例代码放在静态块中去初始化。

![1527494958180](D:\github\MyHome\image\wz_img\1527494958180.png)

5. ##### 静态内部类

![1527495037925](D:\github\MyHome\image\wz_img\1527495037925.png)

6. ##### 枚举

![1527495054242](D:\github\MyHome\image\wz_img\1527495054242.png)

7. ##### 双重检测

双重检验锁模式（double checked locking pattern），是一种使用同步块加锁的方法。程序员称其为双重检查锁，因为会有两次检查 `instance == null`，一次是在同步块外，一次是在同步块内。为什么在同步块内还要再检验一次？因为可能会有多个线程一起进入同步块外的 if，如果在同步块内不进行二次检验的话就会生成多个实例了。 

```java
public static Singleton getSingleton() {
    if (instance == null) {                         //Single Checked
        synchronized (Singleton.class) {
            if (instance == null) {                 //Double Checked
                instance = new Singleton();
            }
        }
    }
    return instance ;
}
```

这段代码看起来很完美，很可惜，它是有问题。主要在于instance = new Singleton()这句，这并非是一个原子操作，事实上在 JVM 中这句话大概做了下面 3 件事情。

1. 给 instance 分配内存
2. 调用 Singleton 的构造函数来初始化成员变量
3. 将instance对象指向分配的内存空间（执行完这步 instance 就为非 null 了）

但是在 JVM 的即时编译器中存在指令重排序的优化。也就是说上面的第二步和第三步的顺序是不能保证的，最终的执行顺序可能是 1-2-3 也可能是 1-3-2。如果是后者，则在 3 执行完毕、2 未执行之前，被线程二抢占了，这时 instance 已经是非 null 了（但却没有初始化），所以线程二会直接返回 instance，然后使用，然后顺理成章地报错。

我们只需要将 instance 变量声明成 volatile 就可以了。

```java
public class Singleton {
    private volatile static Singleton instance; //声明成 volatile
    private Singleton (){}

    public static Singleton getSingleton() {
        if (instance == null) {                         
            synchronized (Singleton.class) {
                if (instance == null) {       
                    instance = new Singleton();
                }
            }
        }
        return instance;
    }
   
}
```

有些人认为使用 volatile 的原因是可见性，也就是可以保证线程在本地不会存有 instance 的副本，每次都是去主内存中读取。但其实是不对的。使用 volatile 的主要原因是其另一个特性：禁止指令重排序优化。也就是说，在 volatile 变量的赋值操作后面会有一个内存屏障（生成的汇编代码上），读操作不会被重排序到内存屏障之前。比如上面的例子，取操作必须在执行完 1-2-3 之后或者 1-3-2 之后，不存在执行到 1-3 然后取到值的情况。从「先行发生原则」的角度理解的话，就是对于一个 volatile 变量的写操作都先行发生于后面对这个变量的读操作（这里的“后面”是时间上的先后顺序）。

但是特别注意在 Java 5 以前的版本使用了 volatile 的双检锁还是有问题的。其原因是 Java 5 以前的 JMM （Java 内存模型）是存在缺陷的，即时将变量声明成 volatile 也不能完全避免重排序，主要是 volatile 变量前后的代码仍然存在重排序问题。这个 volatile 屏蔽重排序的问题在 Java 5 中才得以修复，所以在这之后才可以放心使用 volatile。

相信你不会喜欢这种复杂又隐含问题的方式，当然我们有更好的实现线程安全的单例模式的办法。



### 命令模式

1. 命令模式将"请求"封装成对象，一边使用不同的请求、队列或者日志来参数化其他对象。命令模式也支持可撤销的操作。
2. 命令的发送者和执行者能够很好的解耦，根据业务的需要各自完成自己的不同的生命周期。
3. 支持撤销\重做操作

``` java

/**
 * 命令对象
 */
public interface Command {    
    public void execute(); // 执行命令和重做    
    public void undo();  // 执行撤销操作    
}   

/**
 * 具体的执行者，将执行步骤进行封装，很好的将发送者和执行者解耦。
 * 通过执行者来保存一些执行步骤，并且能够很好的达到撤销和重做的功能。
 *
 */
public class CommandManager {
    // 重做步骤
    private List undoList = new ArrayList();  
    // 撤销步骤
    private List redoList = new ArrayList();  
    
    // 可撤销的步数，-1时无限步  
    private int undoCount = -1;  
      
    public CommandManager() {  
          
        // 可通过配置文件配置撤销步数  
        undoCount = 5;  
    }  
  
    /** 
     * 执行新操作 
     */  
    public void executeCommand(Command cmd) {  
          
        // 执行操作  
        cmd.execute();  
          
        undoList.add(cmd);  
          
        // 保留最近undoCount次操作，删除最早操作  
        if (undoCount != -1 && undoList.size() > undoCount) {  
            undoList.remove(0);  
        }  
          
        // 执行新操作后清空redoList，因为这些操作不能恢复了  
        redoList.clear();  
    }  
      
    /** 
     * 执行撤销操作 
     */  
    public void undo() {  
        if (undoList.size() <= 0) {  
            return;  
        }  
          
        Command cmd = ((Command)(undoList.get(undoList.size() - 1)));  
        cmd.undo();  
          
        undoList.remove(cmd);  
        redoList.add(cmd);  
    }  
  
    /** 
     * 执行重做 
     */  
    public void redo() {  
        if (redoList.size() <= 0) {  
            return;  
        }  
          
        Command cmd = ((Command)(redoList.get(redoList.size() - 1)));  
        cmd.execute();  
          
        redoList.remove(cmd);  
        undoList.add(cmd);  
    }  
}
```



应用场景: 支持撤销重做的功能。

### 适配器模式

1. 适配器将一个类的接口，转换成客户期望的另一个接口，适配器让原本接口不兼容的类可以合作无间。
2. 客户通过目标接口调用适配器的方法对适配器发出请求。
3. 适配器使用被适配者接口把请求转换成被适配者的一个或多个调用接口。
4. 客户接受到调用的结构，但并未察觉这一切是适配器在起转换作用。

> A和B不相关的接口，通过C实现A的方法只会，持有B的引用去在方法中进行具体的实现，能够实现具体的目的。

### 外观模式

​	外观模式提供了一个统一的接口，用来访问自系统中的一群接口。外观定义了一个高层接口，让子系统更容易使用。

 