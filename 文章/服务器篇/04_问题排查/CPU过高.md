## 如何定位一个CPU占用100的线程是哪个引起的?

- 首先通过top -H 定位到占用线程最大的CPU的线程编号
- 然后通过 top 定位到占用最大进程的进程编号
- 然后通过 jstack PID[第二步的进程编号]
- 然后将第一步获取到的CPU的线程编号转换成16进制
    - 转换16进制的方法 : Integer.toHexString(3583); 里面填上PID就行了
- 然后就找到对应的线程
    - 查看16进制 : printf "%x \n" 线程号
    - 这里需要注意
        - 最好你要将每个线程命名会更好排查问题
        - 代码中最好不要出现死循环这种情况

## 定位代码中最耗CPU的位置

#### JProfiles

1. 参考 https://blog.csdn.net/wytocsdn/article/details/79258247 



https://plugins.jetbrains.com/plugin/253-jprofiler

注册码 : https://blog.csdn.net/liyantianmin/article/details/86534544

另外思路 : 火焰图

## 另外推荐一个非常好用的Linux排查工具

https://github.com/oldratlee/useful-scripts/blob/master/docs/java.md#beer-show-busy-java-threadssh

https://github.com/aqzt/kjyw









## linux

### 查看当前CPU消耗排行

ps -aux | sort -rnk 3 | head -20