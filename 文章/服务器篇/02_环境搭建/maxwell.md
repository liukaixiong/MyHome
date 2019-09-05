





**订阅binLog，并将数据推送到指定的队列中**

## 安装好Mysql



## 开启Mysql的BinLog

```shell
vim /etc/my.cnf
```



```shell
[mysqld]
server-id=1
log-bin=master  # 这里开启binlog
binlog_format=row
```

### 重启Mysql服务

```shell
service mysqld restart
```



### 查看是否开启

```sql
show variables like '%log_bin%';
```



```tex
log_bin											ON
log_bin_basename						/var/lib/mysql/master
log_bin_index							/var/lib/mysql/master.index
log_bin_trust_function_creators					OFF
log_bin_use_v1_row_events						OFF
sql_log_bin										ON
```

```shell
./bin/maxwell --user=kaifa --password=elab@123 --host='127.0.0.1' --producer=kafka --kafka.bootstrap.servers=172.19.189.145:9092,172.19.189.144:9092,172.19.189.143:9092 --kafka_topic=maxwell --include_dbs=marketing_db --include_tables=behavior_mini_web
```



### 授权账户

```shell
mysql> CREATE USER 'maxwell'@'%' IDENTIFIED BY 'XXXXXX';
mysql> GRANT ALL ON maxwell.* TO 'maxwell'@'%';
mysql> GRANT SELECT, REPLICATION CLIENT, REPLICATION SLAVE ON *.* TO 'maxwell'@'%';

# or for running maxwell locally:

mysql> CREATE USER 'maxwell'@'localhost' IDENTIFIED BY 'XXXXXX';
mysql> GRANT ALL ON maxwell.* TO 'maxwell'@'localhost';
mysql> GRANT SELECT, REPLICATION CLIENT, REPLICATION SLAVE ON *.* TO 'maxwell'@'localhost';
mysql> flush privileges;
```







## maxwell

### 下载

```shell
wget https://github.com/zendesk/maxwell/releases/download/v1.10.7/maxwell-1.10.7.tar.gz 
```

### 解压

```shell
tar-zxf maxwell-1.10.6.tar.gz
```

### 运行

[各端参考](http://maxwells-daemon.io/quickstart/)

**kafka**

```shell
bin/maxwell --user='maxwell' --password='XXXXXX' --host='127.0.0.1' \
   --producer=kafka --kafka.bootstrap.servers=localhost:9092 --kafka_topic=maxwell 
```

如果要过滤数据库和表

```shell
--include_dbs=db1,db2
--include_dbs=db3 --include_tables=t1,t2,t3
```

