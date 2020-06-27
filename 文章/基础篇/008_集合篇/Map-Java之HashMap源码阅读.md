> 工作中常常会遇到常用的类,但是由于封装的太好,一般也不会出现太多的问题,就导致对底层的实现了解的比较少,最近想把这些东西全部都梳理一下,也顺便多学习一些实现思路。欢迎共同探讨

带着几个问题去读源码:
1. HashMap是基于哪种数据结构实现的?
2. HashMap是如何存储的?
3. HashMap是如何取值的?

边读代码边理解:
>其实只要阅读他的Put方法就能够知道前两个问题的答案!

###put方法

```java
	public V put(K key, V value) {
		// 第一个值是通过Hash去摸的形式获取定位这个key应该存在的位置
		// 第二三个是 键和值
		// 第四个表示如果为true的话,则表示不改变已经存在的值
		// 第五个参数表示是初始化的表格
        return putVal(hash(key), key, value, false, true);
    }

	// 具体的实现方法
	final V putVal(int hash, K key, V value, boolean onlyIfAbsent,
                   boolean evict) {
        // Node 表示一个链表节点,基本上就能够确定两种结构存储 数组和链表
        Node<K,V>[] tab; Node<K,V> p; int n, i;
        // 首先划分步骤,方便以下阅读
		// 第一步:
        if ((tab = table) == null || (n = tab.length) == 0)
	        // 如果一开始是初始化的情况下,则开始调整Map的大小.初始化大小是16
            n = (tab = resize()).length;
        // 第二步
        // 表示 当前数组大小 - 1 之后hash取模一下,定位这个key在数组中的位置,如果为null表示不存在
        if ((p = tab[i = (n - 1) & hash]) == null)
	        // 如果定位到的位置不存在的情况下,则创建一个Node对象
            tab[i] = newNode(hash, key, value, null);
        else {
        // 第三步
            Node<K,V> e; K k;
            // 表示第二步中定位到了数组位置,需要在链表中去获取
            // 如果这个数组位置的key和传递进来的key一致的话,则将这个对象赋给e做下一步操作
            if (p.hash == hash &&
                ((k = p.key) == key || (key != null && key.equals(k))))
                e = p;
            // 这个表示红黑树节点的情况下
            else if (p instanceof TreeNode)
                e = ((TreeNode<K,V>)p).putTreeVal(this, tab, hash, key, value);
            //
            else {
	            // 循环遍历这个链表去找数据
                for (int binCount = 0; ; ++binCount) {
	                //如果下一个节点为null的话,表示已经遍历到链表的最尾端
                    if ((e = p.next) == null) {
	                    //将这个值作为链表的最尾端赋值
                        p.next = newNode(hash, key, value, null);
                        // 如果当前的链表大小大于指定的门槛值 8 的话,则将链表结构改造成红黑树结构
                        if (binCount >= TREEIFY_THRESHOLD - 1) // -1 for 1st
	                        // 红黑树结构构建
                            treeifyBin(tab, hash);
                        break;
                    }
                    //如果找到了指定数据,则结束
                    if (e.hash == hash &&
                        ((k = e.key) == key || (key != null && key.equals(k))))
                        break;
                    // 如果没有找到,则将e赋值给b继续查找他的下一级节点
                    p = e;
                }
            }
            // e 对象如果不为空的话
            if (e != null) { // existing mapping for key
	            // 将老值取出来
                V oldValue = e.value;
                // 将新值替换进去
                if (!onlyIfAbsent || oldValue == null)
                    e.value = value;
                afterNodeAccess(e);
                // 然后返回老值
                return oldValue;
            }
        }
        //总是大小 + 1
        ++modCount;
        // 如果大小超过设定的大小则进行重新调整
        if (++size > threshold)
            resize();
        // 这个方法应该是交给你拓展的后置方法处理
        afterNodeInsertion(evict);
        return null;
    }
```
**resize()方法 - 一个调整HashMap大小的方法,这个方法很关键,为后面的优化做了一些策略**

```java
final Node<K,V>[] resize() {
        Node<K,V>[] oldTab = table;
        int oldCap = (oldTab == null) ? 0 : oldTab.length;
        int oldThr = threshold;
        int newCap, newThr = 0;
        if (oldCap > 0) {
	        // 当大小超过了1E的时候,就默认给定最大值
            if (oldCap >= MAXIMUM_CAPACITY) {
                threshold = Integer.MAX_VALUE;
                return oldTab;
            }
            // 如果小于1E并且值又大于默认的阀值大小时
            else if ((newCap = oldCap << 1) < MAXIMUM_CAPACITY &&
                     oldCap >= DEFAULT_INITIAL_CAPACITY)
                // **将当前大小调整为两倍大小**
                newThr = oldThr << 1; // double threshold
        }
        else if (oldThr > 0) // initial capacity was placed in threshold
            newCap = oldThr;
        else {               // 零初始阈值意味着使用默认值。
		    // **初始化的时候,默认阀值大小为16**
            newCap = DEFAULT_INITIAL_CAPACITY;
            // **这是一个门槛值 当大于这个值是按这个Map大小的0.75递增**
            newThr = (int)(DEFAULT_LOAD_FACTOR * DEFAULT_INITIAL_CAPACITY);
        }
        // 计算新的resize上限
        if (newThr == 0) {
            float ft = (float)newCap * loadFactor;
            newThr = (newCap < MAXIMUM_CAPACITY && ft < (float)MAXIMUM_CAPACITY ?
                      (int)ft : Integer.MAX_VALUE);
        }
        //调整阀值大小
        threshold = newThr;
        @SuppressWarnings({"rawtypes","unchecked"})
        // 重新构建一个新的数组链表,并将大小调整至阀值的大小
            Node<K,V>[] newTab = (Node<K,V>[])new Node[newCap];
        table = newTab;
        // 老的HashMap不为空的情况下
        if (oldTab != null) {
            for (int j = 0; j < oldCap; ++j) {
                Node<K,V> e;
                if ((e = oldTab[j]) != null) {
                    oldTab[j] = null;
                    // 如果链表的下一级为空了,表示已经到了最尾端
                    if (e.next == null)
	                    // 重新通过Hash分配数组位置,设置为链表的头部
                        newTab[e.hash & (newCap - 1)] = e;
                        // 如果是红黑树的情况下
                    else if (e instanceof TreeNode)
                        ((TreeNode<K,V>)e).split(this, newTab, j, oldCap);
                    else { // preserve order ###开始执行链表的秩序
		                //// 链表优化重hash的代码块 - 这一部分代码很关键
		                // 这一部分表示原索引放入 bucket 中
                        Node<K,V> loHead = null, loTail = null;
                        // 这一部分表示原索引+oldCap放入bucket中
                        Node<K,V> hiHead = null, hiTail = null;
                        Node<K,V> next;
                        do {
	                        // 取出下一级
                            next = e.next;
                            //通过位运算获取该对象应该存在数组的位置
                            /**
		                      只需要看看原来的hash值新增的那个bit是1还是0就好了，是0的话索引没 
		                      变，是1的话索引变成“原索引+oldCap” 
			                 */
			                 // 原索引处理规则
                            if ((e.hash & oldCap) == 0) {
	                            //将判断链表头部对象是否存在,null表示不存在,如果不存在,则将当前对
	                            //象设置为头部
                                if (loTail == null)
	                                // 头部赋值
                                    loHead = e;
                                else
	                                // 否则设置该链表的下一级
                                   loTail.next = e;
                                //将尾部重新定义为当前对象,方便下一个对象进来直接定位到尾部
                                loTail = e;
                            }
                            // 这里用来处理非原索引的逻辑,和上面差不多
                            else {
	                            // 如果尾部为空的话
                                if (hiTail == null)
	                                //则将头部设置为他
                                    hiHead = e;
                                else
	                                // 将尾部进行赋值
                                    hiTail.next = e;
                                // 将当前值设置为尾部
                                hiTail = e;
                            }
                        } 
                        // 循环遍历链表的下一级节点!!!!
						while ((e = next) != null);
						// 原索引还是存放到原来的位置
                        if (loTail != null) {
                            loTail.next = null;
                            newTab[j] = loHead;
                        }
                        // 非原索引则根据当作数组位置+老的极限值大小的位置,相加,得到存储的位置
                        if (hiTail != null) {
                            hiTail.next = null;
                            newTab[j + oldCap] = hiHead;
                        }
                    }
                }
            }
        }
        return newTab;
    }
```
#### 梳理一下上面所了解到的知识:
```wiki
1. HashMap是由数组+链表+红黑树组成
2. HashMap的初始化数组大小是16,存储阀值大小当前数组大小的75%,当数组中的实际大小大于这个阀值是开始重新调整数组大小,调整方案是以2倍递增,当大小进行到Integer.MAX_VALUE,将不在扩容。
3. 扩容的方式是重新构建一个新的链表数组,将老的数组进行重组放入新的数组链表中
4. HashMap优化点:
	1.  当链表长度超过8时,则将改造成TreeMap,也就是常说的红黑树,这样做的目的就是为了防止某一个链表非常长,查找速度很慢.
	2.  扩容时会将链表进行遍历重组,重组的规则是判断它的最后一个bit是0还是1,因为我们使用的是2次幂的扩展(指长度扩为原来2倍)，所以元素的位置要么是在原位置，要么是在原位置再移动2次幂的位置,所以打个比方,当前key处于数组大小16的索引15位置,经过扩容之后的位置为15+16=31的位置。
	3. 定位数组的位置一共采用了三步:取key的hashCode、高位运算、取模运算
```
```wiki
方法一：
static final int hash(Object key) {   //jdk1.8 & jdk1.7
     int h;
     // h = key.hashCode() 为第一步 取hashCode值
     // h ^ (h >>> 16)  为第二步 高位参与运算
     return (key == null) ? 0 : (h = key.hashCode()) ^ (h >>> 16);
}
方法二：
static int indexFor(int h, int length) {  //jdk1.7的源码，jdk1.8没有这个方法，但是实现原理一样的
     return h & (length-1);  //第三步 取模运算
}
```

### Map是如何取值的?

> 你如果了解了上面如何定位数组位置的话,应该就能够有大概的思路,还是上遍代码吧.

```java
	// 第一个值是key的hash值
	final Node<K,V> getNode(int hash, Object key) {
        Node<K,V>[] tab; Node<K,V> first, e; int n; K k;
        // 数组不为空的情况下
        if ((tab = table) != null && (n = tab.length) > 0 &&
	        // 这里会通过取模运算得到数组的位置
            (first = tab[(n - 1) & hash]) != null) {
			// 判断位置是否是第一个,如果是第一个则返回
            if (first.hash == hash && // always check first node
                ((k = first.key) == key || (key != null && key.equals(k))))
                return first;
                // 如果不是第一个,则默认循环查找该链表,如果是红黑树则调用getTreeNode方法查找,然后返回.没有找到则返回null
            if ((e = first.next) != null) {
                if (first instanceof TreeNode)
                    return ((TreeNode<K,V>)first).getTreeNode(hash, key);
                do {
                    if (e.hash == hash &&
                        ((k = e.key) == key || (key != null && key.equals(k))))
                        return e;
                } while ((e = e.next) != null);
            }
        }
        return null;
    }
```

参考资料:http://www.importnew.com/20386.html - **写的真他妈不是一般的好**

### 补充

[以下来源](https://www.bilibili.com/video/BV1Qk4y1672n?from=search&seid=9376509036993552262)

1. hash的理解

把任意长度的输入通过hash算法转化成固定长度的输出。

存在的问题就是出现hash的冲突。

1. 好点的hash算法，应该考虑的点：
   1. 效率得高。要做到长文本也能高效计算。
   2. 不能逆推出原文
   3. ​