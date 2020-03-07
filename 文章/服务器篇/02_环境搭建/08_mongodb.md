# mongodb

1. 重启

   进入到指定目录

   ```shell
   ./mongod -f ../master.conf
   ```

   

2. mongodb 一定要设置帐号密码

```conf
auth = true            #是否开启验证
```

一些常用参数 : 

```properties
dbpath = /elab/mongodb-4.0.2/db/master       #从服务器
logpath = /elab/mongodb-4.0.2/log/master.log        # 日志存放地址
directoryperdb = true   #数据库是否分目录存放
logappend = true        #日志追加方式存放
#replSet = elabdb        #Replica Set的名字
maxConns = 5000         #最大连接数，默认2000
port = 27017            #主数据库端口号
bind_ip = 172.19.189.121  #从数据库所在服务器
oplogSize = 70000         #设置oplog的大小（MB）
#keyFile和auth选项要在集群配置好后，并且添加了验证用户后在启用
#keyFile = /elab/mongodb-4.0.2/log/mongodb.key      #节点之间用于验证文件，内容必须保持一致，权限600，仅Replica Set 模式有效
auth = true            #是否开启验证
fork = true             #是否后台启动
```

**验证用户**

```shell
use admin
db.auth("adminUser", "adminPass")
```

**登录用户**

```shell
# 1. 先查看mongodb的ip

# 2. 进入mongo的bin目录
./mongo --host ip
```

