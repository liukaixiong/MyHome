> ArrayList中有一个sort排序方法,只要你实现了Comparator的接口,按照你自己的排序业务进行实现,你只要告诉这个接口按照什么类型进行排序就OK了。这种方式类似于设计模式中的策略模式，把流程划分好，具体的业务逻辑由用户指定。这时候我们需要带着问题去看看里面具体是如何实现的..

## 环境描述
JDK : 1.8

伪代码:
```java
 public static void main(String[] args) {
        // 初始化一组数据,这组数据可以是任意对象
        int[] data = {7, 5, 1, 2, 6, 8, 10, 12, 4, 3, 9, 11, 13, 15, 16, 14}; 
        // 构建成一个集合
        List<Integer> list = new ArrayList<>();
        for (int i = 0; i < data.length; i++) {
            list.add(data[i]);
        }
        // 设定自己的比较方式
        // 1顺序 -1倒序
        list.sort(new Comparator<Integer>() {
            @Override
            public int compare(Integer o1, Integer o2) {
                int i = o1 > o2 ? 1 : -1;
                System.out.println("开始比较 [o1] - " + o1 + "\t [o2] - " + o2);
                return i;
            }
        });
        // 打印结果
        System.out.println(JSON.toJSONString(list));
    }
```

## 问题
- 它是如何实现的 ?


## 实践
#### 跟踪代码
1. ArrayList中的 sort方法
```java
public void sort(Comparator<? super E> c) {
        // 集合大小
        final int expectedModCount = modCount;
        // 将排序交给Arrays去实现
        Arrays.sort((E[]) elementData, 0, size, c);
        if (modCount != expectedModCount) {
            throw new ConcurrentModificationException();
        }
        modCount++;
    }
```

2. Arrays中的sort方法又是交给一个TimSort类去实现的,我们直接看TimSort类的sort方法
```java

    static <T> void sort(T[] a, int lo, int hi, Comparator<? super T> c,
                         T[] work, int workBase, int workLen) {
        assert c != null && a != null && lo >= 0 && lo <= hi && hi <= a.length;

        int nRemaining  = hi - lo;
        // 这里表示如果大小小于2则没有排序的必要了
        if (nRemaining < 2)
            return;  // Arrays of size 0 and 1 are always sorted

        // If array is small, do a "mini-TimSort" with no merges
        // 这里会根据数组的大小来使用不同的排序方式
        // 默认的如果大小不超过32则会采用归并排序
        if (nRemaining < MIN_MERGE) {
            // 这里面会根据你数组中数据是递增还是递减的方式来划分成两块
            // 举例   1,4,7,3,6,2 这里一开始是递增直到7结束,如果比较方法得出的的值是-1(递减),
            //则会将1,4,7先进行反转得到 7,4,1 然后划分成两个逻辑部分{7,4,1} , {3,6,2} 进行归并运算
            // 这里的返回值得到的就是划分成两部分的下标索引比如上面举例的就是3
            int initRunLen = countRunAndMakeAscending(a, lo, hi, c);
            // 归并排序
            binarySort(a, lo, hi, lo + initRunLen, c);
            return;
        }


//////////////////////////////////// 这里是数组长度大于32的情况下 //////////////////////////////////////////
        /**
         * March over the array once, left to right, finding natural runs,
         * extending short natural runs to minRun elements, and merging runs
         * to maintain stack invariant.
         */
        TimSort<T> ts = new TimSort<>(a, c, work, workBase, workLen);
        // 得到一个最小的归并长度,根据这个长度来判断这组数据具体要归并几次
        int minRun = minRunLength(nRemaining);
        do {
            // Identify next run
            int runLen = countRunAndMakeAscending(a, lo, hi, c);

            // If run is short, extend to min(minRun, nRemaining)
            if (runLen < minRun) {
                int force = nRemaining <= minRun ? nRemaining : minRun;
                binarySort(a, lo, lo + force, lo + runLen, c);
                //运行长度
                runLen = force;
            }

            // Push run onto pending-run stack, and maybe merge
            // 将运行下标进行记录
            ts.pushRun(lo, runLen);
            ts.mergeCollapse();

            // Advance to find next run
            lo += runLen;
            nRemaining -= runLen;
        } while (nRemaining != 0);

        // Merge all remaining runs to complete sort
        assert lo == hi;
        ts.mergeForceCollapse();
        assert ts.stackSize == 1;
    }


 
private static <T> int countRunAndMakeAscending(T[] a, int lo, int hi,
                                                    Comparator<? super T> c) {
        assert lo < hi;
        // 得到下一个坐标
        int runHi = lo + 1;
        // 如果都等于1 
        if (runHi == hi)
            return 1;

        // Find end of run, and reverse range if descending
        //找到运行结束，如果下降，反向范围
        // 这里面会根据你数组中数据是递增还是递减的方式来划分成两块
        // 举例   1,4,7,3,6,2 这里一开始是递增直到7结束,如果比较方法得出的的值是-1(递减),
        //则会将1,4,7先进行反转得到 7,4,1 然后划分成两个逻辑部分{7,4,1} , {3,6,2} 进行归并运算
        if (c.compare(a[runHi++], a[lo]) < 0) { // Descending
            while (runHi < hi && c.compare(a[runHi], a[runHi - 1]) < 0)
                runHi++;
            reverseRange(a, lo, runHi);
        } else {                              // Ascending
            while (runHi < hi && c.compare(a[runHi], a[runHi - 1]) >= 0)
                runHi++;
        }

        return runHi - lo;
    }

// 具体的归并排序
private static <T> void binarySort(T[] a, int lo, int hi, int start,
                                       Comparator<? super T> c) {
        assert lo <= start && start <= hi;
        if (start == lo)
            start++;

      // 这里的start 是等于上面划分的临界点的值,比如上面举例的就是3,从3的下标值开始和一部分进行比较
        for ( ; start < hi; start++) {
            T pivot = a[start];

            // Set left (and right) to the index where a[start] (pivot) belongs
            // 左边就相当于 {7,4,1}的下标,默认是0
            int left = lo;
            // 右边就相当于{3,6,2}
            int right = start;
            assert left <= right;
            /*
             * Invariants:
             *   pivot >= all in [lo, left).
             *   pivot <  all in [right, start).
             */
            // 找归并位置,必须左边小于右边
            while (left < right) {
                // 运算方式 , 你可以理解成 count / 2 得到的整数
                int mid = (left + right) >>> 1;
                // 如果小于0则改变right的位置
                if (c.compare(pivot, a[mid]) < 0)
                    right = mid;
                else
                // 如果大于 则改变left值,
                    left = mid + 1;
            }
            // 直到相等,表示找到了该值应该落在的区间
            assert left == right;

            /*
             * The invariants still hold: pivot >= all in [lo, left) and
             * pivot < all in [left, start), so pivot belongs at left.  Note
             * that if there are elements equal to pivot, left points to the
             * first slot after them -- that's why this sort is stable.
             * Slide elements over to make room for pivot.
             */
          // 这里是算出要移动的区间长度,如果区间长度在2以内,则交换一下位置就兴了,如果大于2,则采用数据复制移动的方式
            int n = start - left;  // The number of elements to move
            // Switch is just an optimization for arraycopy in default case
            switch (n) {
                case 2:  a[left + 2] = a[left + 1];
                case 1:  a[left + 1] = a[left];
                         break;
                default: System.arraycopy(a, left, a, left + 1, n);
            }
            // 最后将右边预算的值,填充的合适的区间内
            a[left] = pivot;
        }
    }
```

画图理解一下:
1. 初始化数组:
  ![image.png](http://upload-images.jianshu.io/upload_images/6370985-f4a5d038e31d6acb.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

2. 通过countRunAndMakeAscending方法,得到数据的走势,是递增还是递减,逻辑上划分成了两个数组,划分值是下标值3
  ![image.png](http://upload-images.jianshu.io/upload_images/6370985-43f0c8798f1d0fec.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
3. 循环B中的数据与A做归并,这时候是从下标3开始,进行运算
    运算流程:

    ```java
    开始从第三个进行 , 这时候会定义三个变量 : 
          1. left 最左边开始移动的数
          2. right 最右边开始移动数
          3.start 开始移动数

    初始化值:
      left = 0;
      right = 3;
      start = 3;

      移动的运算公式
      int mid = (left + right) >>> 1 ; // 这里可以看作是 移动后的值/2

      循环运算条件 : left < right

      第一次运算:
      mid = 1; // 1的下标值是5.
      // 2 > 5 ? 决定是改变left还是right..  这时候是改变right ,
      right = mid; // 这时候right = 1; left = 0; 

      //循环条件满足

      第二次运算:
      1. 1>>>1 = 0  // 0的下标值是1
      mid = 0;
      // 2 > 1 ? 这时候改变的是left 
      left = mid + 1; // 这时候left = 1;

      不会再做第三次运算了,因为循环条件已经不满足了,现在值是 1 > 1 了 这时候开始进行下一步,值移动
    ```


```java
      int n = start - left; // n = 3  - 1 =2 表示要移动2个值
```

```java
       switch (n) {
            case 2:  a[left + 2] = a[left + 1];
            case 1:  a[left + 1] = a[left];
                     break;
            default: System.arraycopy(a, left, a, left + 1, n);
        }
        // 最后将运算的值,填充的合适的区间内
        a[left] = pivot;

这时候我们看到的"大概"流程:
 1. 7 移动到2的位置
 2. 5移动到7的位置
 3. 5的位置由pivot代替,开始循环的变量值,不懂可以去看上面的代码

```

  ![image.png](http://upload-images.jianshu.io/upload_images/6370985-72844fb5ff62110e.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

 然后开始下一个值的轮询,一直到B组中的数据全部在A中找到对应的区间,完成排序.

## 总结
1. ArrayList中的sort排序是采用归并排序的。
  [一个数组的值的趋势(增长或者减少)打断的地方开始划分]
2. 当数组中的数据非常大的时候,会采用几次归并来完成排序.具体采用几次归并是minRunLength(nRemaining);方法去计算的.





