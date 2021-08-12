# 连接数问题排查



## 查看linux最大连接数量

```shell
ulimit -n # 查看最大连接数

```

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

## TCP连接出现大量TIME_WAIT的解决办法

1 查看

```shell
netstat -an | awk '/^tcp/ {++y[$NF]} END {for(w in y) print w, y[w]}' # 查看当前tcp的连接数状态分组
```

执行该命令如果出现了大量的 TIME_WAIT 连接数目的话，如下：
**FIN_WAIT2 50
CLOSING 63
TIME_WAIT 15000**
如果是这种情况的话，可以通过一下设置来减缓
我们用vim打开配置文件（打开之前最好先备份一下该文件）：

```
#vim /etc/sysctl.conf
```

然后，在这个文件中，加入下面的几行内容：

```tex
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_fin_timeout = 30
```

最后输入下面的命令，让内核参数生效：

```shell
#/sbin/sysctl -p
```

简单的说明下，上面的参数的含义：

```shell
net.ipv4.tcp_syncookies = 1 表示开启SYN Cookies。当出现SYN等待队列溢出时，启用cookies来处理，可防范少量SYN攻击，默认为0，表示关闭；
net.ipv4.tcp_tw_reuse = 1 表示开启重用。允许将TIME-WAIT sockets重新用于新的TCP连接，默认为0，表示关闭；
net.ipv4.tcp_tw_recycle = 1 表示开启TCP连接中TIME-WAIT sockets的快速回收，默认为0，表示关闭；
net.ipv4.tcp_fin_timeout 修改系統默认的 TIMEOUT 时间。
```

在经过这样的调整之后，除了会进一步提升服务器的负载能力之外，还能够防御一定程度的DDoS、CC和SYN攻击，是个一举两得的做法。

此外，如果你的连接数本身就很多，我们可以再优化一下TCP/IP的可使用端口范围，进一步提升服务器的并发能力。依然是往上面的参数文件中，加入下面这些配置：

```shell
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 10000 65000
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_max_tw_buckets = 5000
```

这几个参数，建议只在流量非常大的服务器上开启，会有显著的效果。一般的流量小的服务器上，没有必要去设置这几个参数。这几个参数的含义如下：

```shell
net.ipv4.tcp_keepalive_time = 1200 表示当keepalive起用的时候，TCP发送keepalive消息的频度。缺省是2小时，改为20分钟。
net.ipv4.ip_local_port_range = 10000 65000 表示用于向外连接的端口范围。缺省情况下很小：32768到61000，改为10000到65000。（注意：这里不要将最低值设的太低，否则可能会占用掉正常的端口！）
net.ipv4.tcp_max_syn_backlog = 8192 表示SYN队列的长度，默认为1024，加大队列长度为8192，可以容纳更多等待连接的网络连接数。
net.ipv4.tcp_max_tw_buckets = 5000 表示系统同时保持TIME_WAIT的最大数量，如果超过这个数字，TIME_WAIT将立刻被清除并打印警告信息。默 认为180000，改为5000。对于Apache、Nginx等服务器，上几行的参数可以很好地减少TIME_WAIT套接字数量，但是对于 Squid，效果却不大。此项参数可以控制TIME_WAIT的最大数量，避免Squid服务器被大量的TIME_WAIT拖死。
```

