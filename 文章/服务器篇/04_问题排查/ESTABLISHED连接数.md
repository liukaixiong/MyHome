# 连接数问题排查

查看网络连接数：

netstat -an |wc -l

netstat -an |grep xx |wc -l        查看某个/特定ip的连接数

netstat -an |grep TIME_WAIT|wc -l    查看连接数等待time_wait状态连接数

netstat -an |grep ESTABLISHED |wc -l    查看建立稳定连接数量



## 查看不同状态的连接数量

```shell
netstat -an | awk '/^tcp/ {++y[$NF]} END {for(w in y) print w, y[w]}'
```

## 查看每个ip跟服务器建立的连接数

```shell
netstat -nat|awk '{print$5}'|awk -F : '{print$1}'|sort|uniq -c|sort -rn
```

> （PS：正则解析：显示第5列，-F : 以：分割，显示列，sort 排序，uniq -c统计排序过程中的重复行，sort -rn 按纯数字进行逆序排序）

## 查看每个ip建立的ESTABLISHED/TIME_OUT状态的连接数

```shell
 netstat -nat|grep ESTABLISHED|awk '{print$5}'|awk -F : '{print$1}'|sort|uniq -c|sort -rn
```



[其他的可以参考](https://blog.csdn.net/bluetjs/article/details/80965967)

