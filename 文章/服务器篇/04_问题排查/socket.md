# Socket过高

1. 通过netstat查看服务器各个进程的情况

```shell
netstat -ntpl
# 1、查看当前系统的连接
netstat -antp | awk '{a[$6]++}END{ for(x in a)print x,a[x]}'
```

