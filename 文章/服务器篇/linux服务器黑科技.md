

# [the_silver_searcher](https://github.com/ggreer/the_silver_searcher): 大文本搜查工具

```shell
sudo yum install the_silver_searcher
```

常用用法:

```shell
# 查找匹配文件的文本内容为"string-to-search"
ag -G ".+\.java" "string-to-search" /path/to/directory
ag "string-to-search" /path/to/directory

```



# 日志服务器分析工具

## goaccess

安装

```shell
yum -y install goaccess
```

使用方式

```shell
goaccess xxx.log -a -o xxx.html --log-format=COMBINED
```

- xxx.log：为日志文件具体路径
- xxx.html：HTML报告的名字，可指定到站点目录，然后直接访问查看
- –log-format=日志文件格式，COMBINED为标准格式

解析日志选择第三个，标准化格式输出。

![1558935810823](D:\github\MyHome\image\wz_img\1558935810823.png)

分别对应了:

- 请求文件数
- 静态资源请求数据
- 404找不到的数据