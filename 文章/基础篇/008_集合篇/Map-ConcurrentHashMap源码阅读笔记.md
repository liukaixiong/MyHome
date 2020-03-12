> HashMap是我们用的比较多的数据结构，但是它在高并发下面进行put操作时,很有可能会引起死循环,这主要是在它扩容的情况下,导致链表头尾可能存在重复节点，而这时候解决的办法有很多,如Hashtable和Collections.synchronizedMap(hashMap),但是这俩货的性能是存在缺陷的,因为都是锁整个对象。  
> 这时候ConcurrentHashMap出现了，他很好的弥补了HashMap的并发缺陷，也兼顾了上两个方案的高性能读写。 

### Question : 
- 它在高并发下是如何做到的？
    - 如何做到高性能写入?
    - 如何避免HashMap的扩容引发的血案[多线程下扩容会出现链表死循环]?

### 相关概念介绍
```java
// 数组节点 , 初始化是16 
transient volatile Node<K,V>[] table;

// 默认为null，扩容时新生成的数组，其大小为原数组的两倍。可以理解为为扩容所做的临时变量,临时用来做数据交换的,扩容完毕则设置为null
private transient volatile Node<K,V>[] nextTable;
  // 一个基础计数器,用于统计ConcurrentHashMap的计算次数
  private transient volatile long baseCount;
  /* 默认为0，用来控制table的初始化和扩容操作，具体应用在后续会体现出来。
      -1 代表table正在初始化
      -N 表示有N-1个线程正在进行扩容操作
      其余情况：
      1、如果table未初始化，表示table需要初始化的大小。
      2、如果table初始化完成，表示table的容量，默认是table大小的0.75倍，居然用这个公式算0.75（n - (n >>> 2)）。 
  */
 private transient volatile int sizeCtl;

// 扩容时候需要用到的下标计数值,需要通过cas去设置的下标值
 private transient volatile int transferIndex;
```

### put 方法
```java
 /** Implementation for put and putIfAbsent */
    final V putVal(K key, V value, boolean onlyIfAbsent) {
        if (key == null || value == null) throw new NullPointerException();
        // 通过Hash算法得到要存入Key的HashCode码
        int hash = spread(key.hashCode());
        int binCount = 0;
        for (Node<K,V>[] tab = table;;) {
            Node<K,V> f; int n, i, fh;
            if (tab == null || (n = tab.length) == 0)
                // 初始化表格,初始化完成之后赋给tab,让下一次循环继续
                tab = initTable();
            // 判断内存中的对象是否为null,如果为空则新创建一个链表,把该对象作为首节点插入
            else if ((f = tabAt(tab, i = (n - 1) & hash)) == null) {
                // 通过原子性的修改查看值是否能够被插入成功,成功则结束循环
                //但是!!!! 如果不成功,不成功的可能性就是该节点的值发生了改变,一旦发生了改变,则需要重新比较。可能下一次就不是进入这个判断了,因为这个判断刚刚执行失败了,已经被初始化了
                if (casTabAt(tab, i, null,
                             new Node<K,V>(hash, key, value, null)))
                    break;                   // no lock when adding to empty bin
            }
            // 表示正在扩容的情况下,这里出现的场景是,正在扩容,将老的table数据迁移到新的table数据,而同时有线程在获取老的数据里面的值
            else if ((fh = f.hash) == MOVED)
                // 这里据说是为了未完成扩容的情况下,这里会帮助另一个线程加速扩容
                /**
                  这是一个协助扩容的方法。这个方法被调用的时候，当前ConcurrentHashMap一定已
                  经有了nextTable对象，首先拿到这个nextTable对象，调用transfer方法。回看上面的
                  transfer方法      可以看到，当本线程进入扩容方法的时候会直接进入复制阶段。
                */
                tab = helpTransfer(tab, f);
            else {
                // 能够进入到这里的情况有以下几种:
                // 1 它Hash到的下标链表已经有值了,有值了,也可能存在两个条件 
                //           1.存在重复的Hash值,需要覆盖,2.不存在重复的值,则需要将它添加到尾节点
                V oldVal = null;

                // 注意了,这里使用了synchronized , 
                //猜想是因为f是node链表,这里是为了防止这个链表在更新时出现数据不一致的问题.... 
                //这里也就是在插入的时候会进行链表的锁定,这时候就可以放心的对链表做操作了
                synchronized (f) {
                    // 通过CAS去获取内存中的node节点对象
                    if (tabAt(tab, i) == f) {
                        // fh是当前key的hashCode
                        if (fh >= 0) {
                            // 表示计数
                            binCount = 1;
                            // 下面是循环这个链表节点,取出链表中的hash码与当前key做比较
                            for (Node<K,V> e = f;; ++binCount) {
                                K ek;
                                // 判断链表中的Hash码是否存在,存在则替换,不存在则添加到尾节点
                                if (e.hash == hash &&
                                    ((ek = e.key) == key ||
                                     (ek != null && key.equals(ek)))) {
                                    // 如果存在,则将老的值取出来,作为返回出去的结果
                                    oldVal = e.val;
                                    // 在这个值为false的情况下,进行替换,表示是否覆盖
                                    if (!onlyIfAbsent)
                                        // 将新的值赋给这个链表
                                        e.val = value;
                                    break;
                                }
                                Node<K,V> pred = e;
                                //如果链表中不存在这个key相关的节点,则默认插入这个链表的尾部
                                if ((e = e.next) == null) {
                                    pred.next = new Node<K,V>(hash, key,
                                                              value, null);
                                    break;
                                }
                            }
                        }
                        // 这里会判断当前节点是否是Tree节点,
                        // 这一种情况会出现在链表大小达到8个的时候,会将node转化成TreeBin。
                        else if (f instanceof TreeBin) {
                            Node<K,V> p;
                            binCount = 2;
                            if ((p = ((TreeBin<K,V>)f).putTreeVal(hash, key,
                                                           value)) != null) {
                                oldVal = p.val;
                                if (!onlyIfAbsent)
                                    p.val = value;
                            }
                        }
                    }
                }
                if (binCount != 0) {
                    if (binCount >= TREEIFY_THRESHOLD)
                        treeifyBin(tab, i);
                    if (oldVal != null)
                        return oldVal;
                    break;
                }
            }
        }
        addCount(1L, binCount);
        return null;
    }


// 初始化table的方法
private final Node<K,V>[] initTable() {
        Node<K,V>[] tab; int sc;
        // 
        while ((tab = table) == null || tab.length == 0) {
            // 如果当前sizeCtl标识小于0(-1表示正在初始化)时,则线程
            if ((sc = sizeCtl) < 0)
                // 表示让出CPU,处于就绪状态。
                Thread.yield(); // lost initialization race; just spin
             // compareAndSwapInt -> CAS 原子性操作,通过原子操作将当前表格设置为初始化
            //这个方法有四个参数，其中第一个参数为需要改变的对象，第二个为偏移量(即之前求出来的valueOffset的值)，
            //第三个参数为期待的值(这里默认为0)，第四个为更新后的值(-1上面概念中提到-1表示table正在初始化)
            else if (U.compareAndSwapInt(this, SIZECTL, sc, -1)) {
                try {
                    // 这里会先判断table是否为null,因为害怕其他线程先一步已经创建好了.
                    if ((tab = table) == null || tab.length == 0) {
                        // 默认初始化table大小,DEFAULT_CAPACITY = 16
                        int n = (sc > 0) ? sc : DEFAULT_CAPACITY;
                        @SuppressWarnings("unchecked")
                        // 构建一个上面指定的数组大小
                        Node<K,V>[] nt = (Node<K,V>[])new Node<?,?>[n];
                        // 将这个变量赋给一个全局变量,就是为了避免上面  if ((tab = table) == null)的情况
                        table = tab = nt;
                        // 这里会设定一个阀值,就是当前的0.75,可以这么理解                    
                        sc = n - (n >>> 2);
                    }
                } finally {
                    // 初始化完成之后.将这个阀值赋给全局变量
                    sizeCtl = sc;
                }
                break;
            }
        }
        // 返回创建的table
        return tab;
    }

    // 下面 4 个原子性操作
    // 获取内存中的地址
    static final <K,V> Node<K,V> tabAt(Node<K,V>[] tab, int i) {
         //getObjectVolatile 获取obj对象中offset偏移地址对应的object型field的值,支持volatile load语义。
        // 第一个参数是读取节点对象
        // 第二个参数是内存中的偏移量,也就是说位置
        return (Node<K,V>)U.getObjectVolatile(tab, ((long)i << ASHIFT) + ABASE);
    }
    
      //compareAndSwapObject 
     
    /**
     * 在obj的offset位置比较object field和期望的值，如果相同则更新。这个方法
     * 的操作应该是原子的，因此提供了一种不可中断的方式更新object field。
     * 
     *  @param obj the object containing the field to modify.
     *    包含要修改field的对象 
     * @param offset the offset of the object field within <code>obj</code>.
     *         <code>obj</code>中object型field的偏移量
     * @param expect the expected value of the field.
     *               希望field中存在的值
     * @param update the new value of the field if it equals <code>expect</code>.
     *               如果期望值expect与field的当前值相同，设置filed的值为这个新值
     * @return true if the field was changed.
     *              如果field的值被更改
     */
  public native boolean compareAndSwapObject(Object obj, long offset,Object expect,     Object update);

      static final <K,V> boolean casTabAt(Node<K,V>[] tab, int i,
                                        Node<K,V> c, Node<K,V> v) {
        // 这里传入的第一个参数 是数组table
        // 第二个参数传入的是数组的位置下标
        // 第三个参数是节点本身对象
        // 第四个是期望更新后的节点对象
        return U.compareAndSwapObject(tab, ((long)i << ASHIFT) + ABASE, c, v);
    }
```

## 扩容方法的实现 : 
```java
 private final void addCount(long x, int check) {
        CounterCell[] as; long b, s;
        if ((as = counterCells) != null ||
            !U.compareAndSwapLong(this, BASECOUNT, b = baseCount, s = b + x)) {
            CounterCell a; long v; int m;
            boolean uncontended = true;
            if (as == null || (m = as.length - 1) < 0 ||
                (a = as[ThreadLocalRandom.getProbe() & m]) == null ||
                !(uncontended =
                  U.compareAndSwapLong(a, CELLVALUE, v = a.value, v + x))) {
                fullAddCount(x, uncontended);
                return;
            }
            if (check <= 1)
                return;
            s = sumCount();
        }
        // 这里是否需要检测扩容,因为上面增加了一个值
        if (check >= 0) {
            Node<K,V>[] tab, nt; int n, sc;
            // s 表示当前数组大小.sizeCtl 表示达到阀值大小也就是初次的值 12 ,一旦满足扩容条件
            while (s >= (long)(sc = sizeCtl) && (tab = table) != null &&
                   (n = tab.length) < MAXIMUM_CAPACITY) {
               // 计算一个机器码
                int rs = resizeStamp(n);
                if (sc < 0) {
                    if ((sc >>> RESIZE_STAMP_SHIFT) != rs || sc == rs + 1 ||
                        sc == rs + MAX_RESIZERS || (nt = nextTable) == null ||
                        transferIndex <= 0)
                        break;
                    if (U.compareAndSwapInt(this, SIZECTL, sc, sc + 1))
                        transfer(tab, nt);
                }
                // 通过cas设置SIZECTL的值,一旦设置成功,则满足下列方法
                else if (U.compareAndSwapInt(this, SIZECTL, sc,
                                             (rs << RESIZE_STAMP_SHIFT) + 2))
                    // 数据迁移
                    transfer(tab, null);
                // 计算总数
                s = sumCount();
            }
        }
    }



     // 数据迁移方法 , 也包括扩容
      private final void transfer(Node<K,V>[] tab, Node<K,V>[] nextTab) {
        // 获得当前数组长度
        int n = tab.length, stride; 
        if ((stride = (NCPU > 1) ? (n >>> 3) / NCPU : n) < MIN_TRANSFER_STRIDE)
            stride = MIN_TRANSFER_STRIDE; // subdivide range
        // 表示扩容操作
        if (nextTab == null) {            // initiating
            try {
                @SuppressWarnings("unchecked")
                // n << 1 可以理解为当前数组长度的两倍递增
                Node<K,V>[] nt = (Node<K,V>[])new Node<?,?>[n << 1];  
                // 将新的数组传递
                nextTab = nt;
            } catch (Throwable ex) {      // try to cope with OOME
                sizeCtl = Integer.MAX_VALUE;
                return;
            }
            nextTable = nextTab;
            transferIndex = n;
        }
        int nextn = nextTab.length;
        ForwardingNode<K,V> fwd = new ForwardingNode<K,V>(nextTab);
        boolean advance = true;
        boolean finishing = false; // to ensure sweep before committing nextTab
        for (int i = 0, bound = 0;;) {
            Node<K,V> f; int fh;
            while (advance) {
                int nextIndex, nextBound;
                // 这里能够触发的情况是在下两个条件执行完成之后,会为i赋值一个默认的
                if (--i >= bound || finishing)
                    advance = false; // while不需要再循环了,已经得到了下标值了
                // 这里是表示已经到最后一个的标志
                else if ((nextIndex = transferIndex) <= 0) {
                    i = -1;
                    advance = false;
                }
                // 通过CAS去为这个TRANSFERINDEX变量赋值
                // TRANSFERINDEX 扩容后的大小值
                // nextBound 
                else if (U.compareAndSwapInt
                         (this, TRANSFERINDEX, nextIndex,
                          nextBound = (nextIndex > stride ?
                                       nextIndex - stride : 0))) {
                    bound = nextBound;
                     // 将下一个坐标值赋i,然外面的for循环根据这个下标去table中迁移数据
                    i = nextIndex - 1;
                    // 停止while的循环
                    advance = false;
                }
            }
            if (i < 0 || i >= n || i + n >= nextn) {
                int sc;
                // 这里有点绕.何时会满足这个条件?
                // 1. 当老数组全部数据迁移完毕之后,这时候会将finishing设置为true
                // 2.会执行一次数据检查,就是说再遍历一次.看是否还有没有迁移的值,直到检查完毕之后,则会满足这个条件,
                // 通俗一点来说,这个标记位表示所有迁移工作全部完成..
                if (finishing) {
                    // 将这个临时变量设置为null,下一次扩容再用
                    nextTable = null;
                    // 将新的数组赋值给老的
                    table = nextTab;
                    // 这里是设置新数组大小的阀值,比如扩容到32了,他的阀值是32 * 75% 则是扩容条件
                    // (n >>> 1) 理解为 0.75 ,总的理解就是上面的,实际上是32 - 8 ;
                    sizeCtl = (n << 1) - (n >>> 1);
                    return;
                }
                // 当执行到最后一个节点完成之后,将SIZECTL设置为-1 表示正在初始化
                if (U.compareAndSwapInt(this, SIZECTL, sc = sizeCtl, sc - 1)) {
                    if ((sc - 2) != resizeStamp(n) << RESIZE_STAMP_SHIFT)
                        return;
                    finishing = advance = true;
                   // 这里将i重新设置为老数组的长度,是为了检查是否还有没有需要提交的数据(PS:我也不是特别理解这一步的意义.. 重复检查 ? )
                    i = n; // recheck before commit
                }
            }
            // 获取table中的[i]下标链表,如果该链表为空,则给他赋予默认值
            else if ((f = tabAt(tab, i)) == null)
                // 如果获取到的节点链表为空的情况,那就好办了,直接赋值为null,
                //新的数组也不用迁移 , 需要注意的是赋值的null对象是一个自定义的ForwardingNode节点
                // 他使用这个节点的意义应该是能够快速标识出目前正处于扩容阶段
                // 其他线程如果也在执行扩容的话,如果标识出该链表为fwd类型的表示该链表已经迁移完成
                advance = casTabAt(tab, i, null, fwd);
            // 如果上面获取到的链表的Hash码为-1,表示已经处理过
            // 这里就表示取出来的链表节点为ForwardingNode节点,表示迁移完成
            else if ((fh = f.hash) == MOVED)
                // 这里是为了重读检查设置的,为null的节点,不做任何处理,只是为了检查一下
                advance = true; // already processed
            else {
                // 这里开始迁移数据了.用的还是同步,防止链表出现更改的情况
                synchronized (f) {
                    // 这里还是获取i的下标节点
                    if (tabAt(tab, i) == f) {
                        // 这俩变量是用来做数据迁移的
                        // ln表示不迁移的数据链表,hn表示迁移的数据链表
                        Node<K,V> ln, hn;
                        // hash码不为0的时候
                        if (fh >= 0) {
                            // 这里会将你的hashcode与老的数组大小做一次运算
                            // 这里的运算决定了你的数据是需要迁移
                            // 如果运算出来得到的值为0表示不迁移,如果不等于0 则默认迁移到新的数组那边去
                            // 举例 : 运算得到 16 这时候 i 是 15 ,因为不为0表示迁移到 16+15 = 31 的数组下标中去
                            int runBit = fh & n;
                            // 获取当前节点
                            Node<K,V> lastRun = f;
                            // 循环遍历当前节点的下一级节点
                            for (Node<K,V> p = f.next; p != null; p = p.next) {
                                int b = p.hash & n;
                                if (b != runBit) {
                                    runBit = b;
                                    lastRun = p;
                                }
                            }
                           // 这里就是为0的表示不迁移,还是重新放入到当前下标i中
                            if (runBit == 0) {
                                ln = lastRun;
                                hn = null;
                            }
                            // 不为0的时候
                            else {
                                hn = lastRun;
                                ln = null;
                            }
                            // 这里类似于一个递归,循环获取下级节点,并且将这些节点进行分类(需要迁移的节点,不需要迁移的节点)
                            for (Node<K,V> p = f; p != lastRun; p = p.next) {
                                int ph = p.hash; K pk = p.key; V pv = p.val;
                                // 这里是分类的依据
                                if ((ph & n) == 0)
                                    ln = new Node<K,V>(ph, pk, pv, ln);
                                else
                                    hn = new Node<K,V>(ph, pk, pv, hn);
                            }
                            // 这里开始重新设置值
                            // 设置不迁移的数据,还是在原来的数组下标中
                            setTabAt(nextTab, i, ln);
                            // 需要迁移的数据通过当前下标+原来数组大小得到最终存放的下标
                            setTabAt(nextTab, i + n, hn);
                            // 设置原来的节点数据为空
                            setTabAt(tab, i, fwd);
                            advance = true;
                        }
                        // 下面是红黑树结构的扩容
                        else if (f instanceof TreeBin) {
                            TreeBin<K,V> t = (TreeBin<K,V>)f;
                            TreeNode<K,V> lo = null, loTail = null;
                            TreeNode<K,V> hi = null, hiTail = null;
                            int lc = 0, hc = 0;
                            for (Node<K,V> e = t.first; e != null; e = e.next) {
                                int h = e.hash;
                                TreeNode<K,V> p = new TreeNode<K,V>
                                    (h, e.key, e.val, null, null);
                                if ((h & n) == 0) {
                                    if ((p.prev = loTail) == null)
                                        lo = p;
                                    else
                                        loTail.next = p;
                                    loTail = p;
                                    ++lc;
                                }
                                else {
                                    if ((p.prev = hiTail) == null)
                                        hi = p;
                                    else
                                        hiTail.next = p;
                                    hiTail = p;
                                    ++hc;
                                }
                            }
                            ln = (lc <= UNTREEIFY_THRESHOLD) ? untreeify(lo) :
                                (hc != 0) ? new TreeBin<K,V>(lo) : t;
                            hn = (hc <= UNTREEIFY_THRESHOLD) ? untreeify(hi) :
                                (lc != 0) ? new TreeBin<K,V>(hi) : t;
                            setTabAt(nextTab, i, ln);
                            setTabAt(nextTab, i + n, hn);
                            setTabAt(tab, i, fwd);
                            advance = true;
                        }
                    }
                }
            }
        }
    }

      // 计算当前数组中的总数
      final long sumCount() {
        CounterCell[] as = counterCells; CounterCell a;
        long sum = baseCount;
        if (as != null) {
            for (int i = 0; i < as.length; ++i) {
                if ((a = as[i]) != null)
                    sum += a.value;
            }
        }
        return sum;
    }
```
## 从看代码中衍生的问题
1. 在写入的时候,我们会发现它最外层就是一个循环, 为什么就插入一个值也要用到一个循环呢?

   ```tex
    这就是为了防止多线程写入,在通过CAS插入值的时候,遇到失败的情况下,通过自旋的方式,一直尝试插入,直到成功为止。
   ```

2. get方法里为什么需要用tabAt方法去读取table[i]，而不是直接用table[i]？

   ```wiki
    虽然table是用volatile方式修饰的,在多线程的环境之下都能保持可见,但table是一个数组。
    不能确保数组里面的节点内容也是最新的,也可能出现CPU缓存或者副本的情况,
    所以每次更新也是通过CAS去内存里面直接更新,获取也是直接从内存中直接获取..
   ```

3. 为什么扩容一定要按照2倍的方式?

        这样做的好处就是方便数据迁移,也就是说在该下标值中的链表只要划分出一半的数据出去
        (其实就是说通过Key的hashCode的高位运算为0的放入原来的位置,不等于0的划分到当前下标+老的数组长度的位置),
        不用做过多的复杂计算就能够完成扩容。

4. 高并发下扩容是如何实现的?

        1. 在扩容的时候,会将当前链表进行锁定,这样可以避免HashMap中一旦满足扩容条件,多个线程都会出现扩容竞争的情况,
        而ConcurrentHashMap则是会让另一个线程帮助加速扩容这方面来,
        2. 为了保证链表的一致性,采用了cas和synchronized进行加锁的操作,保证每个链表都是原子性的操作.
        3.在进行老的table复制到新的table的时候,老的table会将已经清空链表设置为
        ForwardingNode对象,很巧妙的实现了节点的并发移动。当多个线程同时扩容的时候,
        只要发现有节点中有ForwardingNode对象表示正在扩容,
        则会加入到帮助扩容里面,而不是重新扩容,在已经扩容的基础上,再去帮助未复制的节点进行扩容.

## 解答
1. 如何做到高性能写入?

        1. 借助使用CAS来实现非阻塞无锁的特点来实现线程安全的高效插入
        2. 基于链表的操作还是用了synchronized来保证线程安全,不过目前1.8的synchronized已经效率很高了.
        3. 其实也就是引入分段的概念.高并发下不会锁住整个table数组,而是单个链表的头节点,来保证安全,

2. 如何避免HashMap的扩容引发的血案?

        1. 采用synchronized加锁来保证了链表节点的线程安全操作
        2. 并发下扩容,多个线程扩容,并不会重复的扩容。只会帮助它继续未完成扩容的节点，例如helpTransfer()方法。
           它利用ForwardingNode节点来标识当前链表是否已经迁移完毕，其他线程可以根据这个节点来帮助加速扩容。