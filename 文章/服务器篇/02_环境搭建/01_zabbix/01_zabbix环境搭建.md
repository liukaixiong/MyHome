# 第1章 zabbix监控

## 1.1 为什么要监控

   　　在需要的时刻，提前提醒我们服务器出问题了

  　　 当出问题之后，可以找到问题的根源

 　　  网站/服务器 的可用性

### 1.1.1 网站可用性

　　在软件系统的高可靠性（也称为可用性，英文描述为HA，High Available）里有个衡量其可靠性的标准——X个9，这个X是代表数字3~5。X个9表示在软件系统1年时间的使用过程中，系统可以正常使用时间与总时间（1年）之比，我们通过下面的计算来感受下X个9在不同级别的可靠性差异。

```
    1个9：(1-90%)*365=36.5天，表示该软件系统在连续运行1年时间里最多可能的业务中断时间是36.5天
    2个9：(1-99%)*365=3.65天 ， 表示该软件系统在连续运行1年时间里最多可能的业务中断时间是3.65天
    3个9：(1-99.9%)*365*24=8.76小时，表示该软件系统在连续运行1年时间里最多可能的业务中断时间是8.76小时。
    4个9：(1-99.99%)*365*24=0.876小时=52.6分钟，表示该软件系统在连续运行1年时间里最多可能的业务中断时间是52.6分钟。
    5个9：(1-99.999%)*365*24*60=5.26分钟，表示该软件系统在连续运行1年时间里最多可能的业务中断时间是5.26分钟。
    6个9：(1-99.9999%)*365*24*60*60=31秒， 示该软件系统在连续运行1年时间里最多可能的业务中断时间是31秒
```

## 1.2 监控什么东西

监控一切需要监控的东西，只要能够想到，能够用命令实现的都能用来监控



### 1.2.1 监控范畴

![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123164550743-1527232078.png)

## 1.3 怎么来监控

### 1.3.1 远程管理服务器

如果想**远程管理服务器**就有远程管理卡，比如Dell idRAC，HP ILO，IBM IMM

### 1.3.2 监控硬件

查看硬件的温度/风扇转速，电脑有鲁大师，服务器就有ipmitool。

使用ipmitool实现对服务器的命令行远程管理

```
yum -y install OpenIPMI ipmitool  #->IPMI在物理机可以成功，虚拟机不行

[root@KVM ~]# ipmitool sdr type Temperature
Temp             | 01h | ns  |  3.1 | Disabled
Temp             | 02h | ns  |  3.2 | Disabled
Temp             | 05h | ns  | 10.1 | Disabled
Temp             | 06h | ns  | 10.2 | Disabled
Ambient Temp     | 0Eh | ok  |  7.1 | 22 degrees C
Planar Temp      | 0Fh | ns  |  7.1 | Disabled
IOH THERMTRIP    | 5Dh | ns  |  7.1 | Disabled
CPU Temp Interf  | 76h | ns  |  7.1 | Disabled
Temp             | 0Ah | ns  |  8.1 | Disabled
Temp             | 0Bh | ns  |  8.1 | Disabled
Temp             | 0Ch | ns  |  8.1 | Disabled
```

### 1.3.3 查看cpu相关

　　lscpu、uptime、top、htop vmstat mpstat

   其中htop需要安装，安装依赖与epel源。

```
[znix@clsn ~]$lscpu
Architecture:          x86_64
CPU op-mode(s):        32-bit, 64-bit
Byte Order:            Little Endian
CPU(s):                1
On-line CPU(s) list:   0
Thread(s) per core:    1
Core(s) per socket:    1
Socket(s):             1
NUMA node(s):          1
Vendor ID:             GenuineIntel
CPU family:            6
Model:                 85
Model name:            Intel(R) Xeon(R) Platinum 8163 CPU @ 2.50GHz
Stepping:              4
CPU MHz:               2494.150
BogoMIPS:              4988.30
Hypervisor vendor:     KVM
Virtualization type:   full
L1d cache:             32K
L1i cache:             32K
L2 cache:              1024K
L3 cache:              33792K
NUMA node0 CPU(s):     0
```

### 1.3.4 内存够不够可以用

　　free

```
[znix@clsn ~]$free -h
             total       used       free     shared    buffers     cached
Mem:          996M       867M       128M       712K       145M       450M
-/+ buffers/cache:       271M       725M
Swap:         1.0G         0B       1.0G
```

### 1.3.5 磁盘剩多少写的快不快可以用

　　df、dd、iotop

```
[znix@clsn ~]$df -h
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda1        40G   24G   15G  62% /
tmpfs           499M   20K  499M   1% /dev/shm
/dev/vdb1        20G  4.4G   15G  24% /data
```

### 1.3.6 监控网络

　　iftop nethogs

```
iftop   监控主机间流量  -i 指定监控网卡
nethogs 监控进程流量
```

## 1.4 监控工具总览

　　mrtg 流量监控出图

　　nagios 监控

　　cacti  流量监控出图

　　**zabbix** **监控+****出图**

## 1.5 zabbix介绍

　　Zabbix 是由 Alexei Vladishev 开发的一种网络监视、管理系统，基于 Server-Client 架构。可用于监视各种网络服务、服务器和网络机器等状态。

　　使用各种 Database-end 如 MySQL, PostgreSQL, SQLite, Oracle 或 IBM DB2 储存资料。Server 端基于 C语言、Web 管理端 frontend 则是基于 PHP 所制作的。Zabbix 可以使用多种方式监视。可以只使用 Simple Check 不需要安装 Client 端，亦可基于 SMTP 或 HTTP ... 各种协定做死活监视。

　　在客户端如 UNIX, Windows 中安装 Zabbix Agent 之后，可监视 CPU Load、网络使用状况、硬盘容量等各种状态。而就算没有安装 Agent 在监视对象中，Zabbix 也可以经由 SNMP、TCP、ICMP、利用 IPMI、SSH、telnet 对目标进行监视。

另外，Zabbix 包含 XMPP 等各种 Item 警示功能。

### 1.5.1 zabbix的组成

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123164838290-262268018.png)

zabbix官网: https://www.zabbix.com

zabbix 主要由2部分构成 zabbix server和 zabbix agent

zabbix proxy是用来管理其他的agent，作为代理

### 1.5.2 zabbix监控范畴

　　²  硬件监控 ：Zabbix IPMI Interface

　　²  系统监控 ：Zabbix Agent Interface

　　²  Java 监控：ZabbixJMX Interface

　　²  网络设备监抟：Zabbix SNMP Interface

　　²  应用服务监控：Zabbix Agent UserParameter

　　²  MySQL 数据库监控：percona-monitoring-pldlgins

　　²  URL监控：Zabbix Web监控

# 第2章 安装zabbix

## 2.1 环境检查

```
[root@m01 ~]# cat /etc/redhat-release
CentOS Linux release 7.4.1708 (Core)

[root@m01 ~]# uname -r
3.10.0-693.el7.x86_64

[root@m01 ~]# getenforce
Disabled

[root@m01 ~]# systemctl status firewalld.service
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; disabled; vendor preset: enabled)
   Active: inactive (dead)
     Docs: man:firewalld(1)
```

## 2.2 安装zabbix过程

### 2.2.1 安装方式选择

　　编译安装 （服务较多，环境复杂）

　　yum安装（干净环境）

　　使用yum 需要镜像yum源 http://www.cnblogs.com/clsn/p/7866643.html

### 2.2.2 服务端快速安装脚本

```
#!/bin/bash
#clsn

#设置解析 注意：网络条件较好时，可以不用自建yum源
# echo '10.0.0.1 mirrors.aliyuncs.com mirrors.aliyun.com repo.zabbix.com' >> /etc/hosts

#安装zabbix源、aliyun YUM源
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-6.repo
curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-6.repo
rpm -ivh http://repo.zabbix.com/zabbix/3.0/rhel/7/x86_64/zabbix-release-3.0-1.el7.noarch.rpm

#安装zabbix 
yum install -y zabbix-server-mysql zabbix-web-mysql

#安装启动 mariadb数据库
yum install -y  mariadb-server
systemctl start mariadb.service

#创建数据库
mysql -e 'create database zabbix character set utf8 collate utf8_bin;'
mysql -e 'grant all privileges on zabbix.* to zabbix@localhost identified by "zabbix";'

#导入数据
zcat /usr/share/doc/zabbix-server-mysql-3.0.13/create.sql.gz|mysql -uzabbix -pzabbix zabbix

#配置zabbixserver连接mysql
sed -i.ori '115a DBPassword=zabbix' /etc/zabbix/zabbix_server.conf

#添加时区
sed -i.ori '18a php_value date.timezone  Asia/Shanghai' /etc/httpd/conf.d/zabbix.conf

#解决中文乱码
yum -y install wqy-microhei-fonts
\cp /usr/share/fonts/wqy-microhei/wqy-microhei.ttc /usr/share/fonts/dejavu/DejaVuSans.ttf

#启动服务
systemctl start zabbix-server
systemctl start httpd

#写入开机自启动
chmod +x /etc/rc.d/rc.local
cat >>/etc/rc.d/rc.local<<EOF
systemctl start mariadb.service
systemctl start httpd
systemctl start zabbix-server
EOF

#输出信息
echo "浏览器访问 http://`hostname -I|awk '{print $1}'`/zabbix"
```

### 2.2.3 客户端快速部署脚本

```
#!/bin/bash
#clsn

#设置解析
echo '10.0.0.1 mirrors.aliyuncs.com mirrors.aliyun.com repo.zabbix.com' >> /etc/hosts

#安装zabbix源、aliyu nYUM源
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-6.repo
curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-6.repo
rpm -ivh http://repo.zabbix.com/zabbix/3.0/rhel/7/x86_64/zabbix-release-3.0-1.el7.noarch.rpm

#安装zabbix客户端
yum install zabbix-agent -y
sed -i.ori 's#Server=127.0.0.1#Server=172.16.1.61#' /etc/zabbix/zabbix_agentd.conf
systemctl start  zabbix-agent.service

#写入开机自启动
chmod +x /etc/rc.d/rc.local
cat >>/etc/rc.d/rc.local<<EOF
systemctl start  zabbix-agent.service
EOF
```

## 2.3 检测连通性

### 2.3.1 服务端安装zabbix-get检测工具

```
yum install zabbix-get
```

### 2.3.2 在服务端进行测试

注意：只能在服务端进行测试

```
zabbix_get -s 172.16.1.61 -p 10050 -k "system.cpu.load[all,avg1]"
zabbix_get -s 172.16.1.21 -p 10050 -k "system.cpu.load[all,avg1]"
```

**测试结果**

```
[root@m01 ~]# zabbix_get -s 172.16.1.61 -p 10050 -k "system.cpu.load[all,avg1]"
0.000000

[root@m01 ~]# zabbix_get -s 172.16.1.21 -p 10050 -k "system.cpu.load[all,avg1]"
0.000000
```

# 第3章 web界面操作

## 3.1 zabbix的web安装

### 3.1.1 使用浏览器访问

　　*http://10.0.0.61/zabbix/setup.php*

![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123165129915-1709791299.png)

   在检测信息时，可查看具体的报错信息进行不同的解决

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123165144836-1283273644.png)

   选择mysql数据库，输入密码即可

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123165152977-895376822.png)

   host与port不需要修改，name自定义

![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123165200477-1599173970.png) 

确认信息,正确点击下一步

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123165208680-1427555138.png)

   安装完成、点击finsh

![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123165214680-2000908902.png) 

​      进入登陆界面  账号**Admin**密码**zabbix**   **注意A****大写**

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123165223211-1228760809.png)





### 3.2.2 web界面

1. 点击右上角的admin用户设置
2. 将语言设置成zh_cn
3. 更新





## 3.2 常用命令

1. zabbix_server服务重启

> ```
> systemctl start  zabbix-serviecs
> ```

或者

> ```
> systemctl start  zabbix-agent.service
> ```

2. zabbix_agentd客户端重启

> service zabbix-agentd restart

或者

> service zabbix_agentd restart

- 服务器目录

  - 配置目录

  > /etc/zabbix/

  - 日志文件

    PidFile=/var/run/zabbix/zabbix_agentd.pid

    LogFile=/var/log/zabbix/zabbix_agentd.log

    

## 3.2 添加监控信息

### 3.2.1 修改监控管理机zabbix server

配置 >> 主机

![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123165230774-1531918261.png) 

主机名称： 要与主机名相同，这是zabbix server程序用的

可见名称： 显示在zabbix网页上的，给我们看的

![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123165237899-1084816018.png) 

   修改后，要将下面的已启用要勾上

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123165247196-1455730420.png)

   添加完成就有了管理机的监控主机

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123165256383-843667682.png)

### 3.2.2 添加新的主机

配置 >> 主机 >> 创建主机

![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123165304852-1665046481.png) 

注意勾选以启用

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123165312352-145910641.png)

   然后添加模板，选择linux OS ，先点小添加，再点大添加。

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123165322399-2072948610.png)

   添加完成，将会又两条监控主机信息

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123165329915-280518565.png)

### 3.2.3 查看监控内容

检测中  >> 最新数据

   在最新数据中需要筛选，

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123165409336-1358964269.png)

   输入ip或者名字都能够搜索出来

![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123165415821-1695498925.png) 

在下面就会列出所有的监控项

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123165432227-67525405.png)

### 3.2.4 查看图像

检测中 >> 图形

   选择正确的主机。选择要查看的图形即可出图

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123165443274-1821091326.png)

# 第4章 自定义监控与监控报警

## 4.1 自定义监控

### 4.1.1 说明

zabbix自带模板Template OS Linux (Template App Zabbix Agent)提供CPU、内存、磁盘、网卡等常规监控，只要新加主机关联此模板，就可自动添加这些监控项。

**需求：**服务器登陆人数不能超过三人，超过三人报警

### 4.1.2 预备知识

自定义key能被server和agent认可

```
# 正确的key
[root@m01 ~]# zabbix_get -s 172.16.1.21 -p 10050 -k "system.uname"
Linux cache01 3.10.0-693.el7.x86_64 #1 SMP Tue Aug 22 21:09:27 UTC 2017 x86_64 
```

```
# 没有登记的，自定义的key
[root@m01 ~]# zabbix_get -s 172.16.1.21 -p 10050 -k "login-user"
ZBX_NOTSUPPORTED: Unsupported item key. 
```

```
# 写错的key
[root@m01 ~]# zabbix_get -s 172.16.1.21 -p 10050 -k "system.uname1"
ZBX_NOTSUPPORTED: Unsupported item key.
```

## 4.2 实现自定义监控

### 4.2.1 自定义语法

```
UserParameter=<key>,<shell command>
UserParameter=login-user,who|wc -l
UserParameter=login-user,/bin/sh /server/scripts/login.sh
```

### 4.2.2 agent注册

```
[root@cache01 ~]# cd /etc/zabbix/zabbix_agentd.d/

[root@cache01 zabbix_agentd.d]# vim userparameter_login.conf
UserParameter=login-user,who|wc -l
UserParameter=login-user2,who|wc -l
UserParameter=login-user3,who|wc -l
```

   **注意：**key名字要唯一，多个key以行为分割

\# 修改完成后重启服务

```
[root@cache01 zabbix_agentd.d]# systemctl restart zabbix-agent.service
```

   在server端进行get测试

```
[root@m01 ~]# zabbix_get -s 172.16.1.21 -p 10050 -k "login-user"
3

[root@m01 ~]# zabbix_get -s 172.16.1.21 -p 10050 -k "login-user2"
3

[root@m01 ~]# zabbix_get -s 172.16.1.21 -p 10050 -k "login-user3"
3

[root@m01 ~]# zabbix_get -s 172.16.1.21 -p 10050 -k "login-user4"
ZBX_NOTSUPPORTED: Unsupported item key.
```

### 4.2.3 在server端注册(web操作)

**①**   **创建模板**

配置 >> 模板 >> 创建模板

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123165620586-851212835.png)

点击添加，即可创建出来模板

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123165631508-690881873.png)

   查看创建出来的模板。↑

**②**   **创建应用集**

应用集类似(目录/文件夹)，其作用是给监控项分类。

点击 应用集 >> 创建应用集

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123165642571-891321995.png)

​      自定义应用集的名称，然后点击添加

**③**   **创建监控项**

监控项 >> 创建监控项

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123165654165-1565485900.png)

**键值** -- key,即前面出创建的login-user。

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123165702071-1170253454.png)

   注意：创建监控项的时候，注意选择上应用集，即之前创建的安全。

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123165711852-864078357.png)

**④**   **创建触发器**

触发器的作用：当监控项获取到的值达到一定条件时就触发报警

*(**根据需求创建)*

触发器 >> 创建触发器

创建触发器，自定义名称，该名称是报警时显示的名称。

   表达式，点击右边的添加，选择**表达式**。 

   严重性自定义。

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123165725977-1129776976.png)

   **表达式的定义** **↓** **，选择**之前创建的监控项，

最新的T值为当前获取到的值。

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123165735415-365506827.png)

   添加完成，能够在触发器中看到添加的情况

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123165748336-296817387.png)

**⑤**   **创建图形**

以图形的方式展示出来监控信息

图形 >> 创建图形

名称自定义，关联上监控项。

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123165759430-719975746.png)

**⑥**   **主机关联模板**

配置 >> 主机

   一个主机可以关联多个模板

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123165807899-367891158.png)

### 4.2.4 查看监控的图形

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123165818196-1388422323.png)

## 4.3 监控报警

### 4.3.1 第三方报警平台

http://www.**onealert**.com

   　 通过 OneAlert 提供的通知分派与排班策略，以及全方位的短信、微信、QQ、电话提醒服务，您可以在最合适的时间，将最重要的信息推送给最合适的人员。

### 4.3.2 onealert配置

添加应用，注意添加的是zabbix

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123165835258-571043802.png)

   实现微信报警需要关注微信公众号即可。

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123165843243-961963757.png)

### 4.3.3 安装 onealert Agent

1.切换到zabbix脚本目录(如何查看zabbix脚本目录)：

```
cd /usr/local/zabbix-server/share/zabbix/alertscripts

#查看zabbix脚本目录
vi /etc/zabbix/zabbix_server.conf
查看AlertScriptsPath
```

2.获取OneITSM agent包：

```
wget http://www.onealert.com/agent/release/oneitsm_zabbix_release-1.0.1.tar.gz
```

3.解压、安装。

```
tar -zxf oneitsm_zabbix_release-1.0.1.tar.gz
cd oneitsm/bin
bash install.sh --#个人生成的key
```

注：在安装过程中根据安装提示，**输入****zabbix****管理地址、管理员用户名、密码**。

```
Zabbix管理地址: http://10.0.0.61/zabbix/
Zabbix管理员账号: Admin
Zabbix管理员密码:
```

4.当提示"安装成功"时表示安装成功!

```
验证告警集成

产生新的zabbix告警(problem),动作状态为“已送达”表示集成成功。
```

### 4.3.1 如何删除onealert Agent

①  删除报警媒介类型中的脚本

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123165948977-426444787.png)

②  删除创建的用户

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123165955852-1528016746.png)

③  删除用户群组

![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123170003821-2087815115.png)

④  删除创建的动作

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123170016071-1437693768.png)

### 4.3.2 触发器响应，发送报警信息

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123170023977-1957213587.png)

   在微信和邮件中，均能收到报警信息。

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123170030383-1285440863.png)

   **注意：当状态改变的时候才会发邮件**

   　　 好-->坏

　　    坏-->好

## 4.4 监控可视化

### 4.4.1 聚合图形

最新数据 >> 图形

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123170055649-256096162.png)

   自定义名称

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123170105915-85092776.png)

   点击聚合图形的名称，进行更改，添加要显示的图形即可。

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123170116883-527462565.png)

### 4.4.2 幻灯片

添加幻灯片

监测中 >> 复合图形 >> 幻灯片演示

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123170126399-1885224195.png)

   创建幻灯片，名称自定，选择要显示的

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123170138008-232612835.png)

   幻灯片根据设定的时间自动播放

## 4.5 模板的共享

### 4.5.1 主机共享

在主机页打开，全选后点击导出

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123170147836-1807397032.png)

   导入

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123170154024-1119374996.png)

### 4.5.2 模板共享

**https://github.com/zhangyao8/zabbix-community-repos**

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123170205430-2041676107.png)

# 第5章 监控全网服务器

## 5.1 需求说明

实际需求：

　　公司已经有了100台服务器，现在需要使用zabbix全部监控起来。

## 5.2 规划方案

常规监控：cpu，内存，磁盘，网卡  问题：怎样快速添加100台机器

   　　方法1：使用克隆的方式

 　　  方法2：自动注册和自动发现

 　　  方法3：调用zabbix api接口  curl 、python

​        　　  开发自己的运维平台兼容zabbix的通道

　　　**服务监控，url****监控等特殊监控**：自定义监控

### 5.2.1 api接口使用（*curl*）

```
    curl -i -X POST -H 'Content-Type:application/json' -d'{"jsonrpc": "2.0","method":"user.login","params":{"user":"Admin","password":"zabbix"},"auth": null,"id":0}' "http://10.0.0.61/zabbix/api_jsonrpc.php"

    curl -i -X POST -H 'Content-Type:application/json' -d'
    {
        "jsonrpc": "2.0",
        "method": "host.get",
        "params": {
            "output": [
                "hostid",
                "host"
            ],
            "selectInterfaces": [
                "interfaceid",
                "ip"
            ]
        },
        "id": 2,
        "auth": "6a450a8fc3dce71fd310cfe338746578"
    }' "http://10.0.0.61/zabbix/api_jsonrpc.php"
```

## 5.3 具体实施规划

### 5.3.1 硬件、系统、网络监控

　　所有集群节点（所有虚拟机）都监控上

　　交换机，路由器监控（简单方法：换成端口对应服务器网卡流量监控；标准方法：监控交换机的网卡）

　　snmp监控

### 5.3.2 应用服务监控

\1. 监控备份服务器，简单方法是监控rsync端口，如果有其他更佳方案可以说明；

```
    方法1：监控873端口net.tcp.port[,873]
    方法2：模拟推送拉取文件
```

\2. 监控NFS服务器，使用监控NFS进程来判断NFS服务器正常，如果有其他更佳方案可以说明；

```
    方法1：端口（通过111的rpc端口获取nfs端口） net.tcp.port[,111]
    方法2：showmount -e ip|wc -l
```

\3. 监控MySQL服务器，简单方法监控mysql的3306端口，或者使用zabbix提供的Mysql模板，如果有其他更佳方案可以说明；

```
    方法1：端口（通过3306的mysql端口） net.tcp.port[,3306]
    方法2：mysql远程登录
    方法3：使用zabbix agent自带的模板及key
```

\4. 监控2台web服务器，简单方法监控80端口，如果有其他更佳方案可以说明；

```
    方法1：端口（通过80的web端口） net.tcp.port[,80]
    方法2：看网页状态码、返回内容==zabbix 自带WEB检测
```

\5. 监控URL地址来更精确的监控我们的网站运行正常；

```
    使用zabbix自带的监控Web监测 进行监控
```

\6. 监控反向代理服务器，PPTP服务器等你在期中架构部署的服务。

```
nginx，pptp
ntp 端口udp 123
```

\7. 监控Nginx的7种连接状态。

```
    自定义监控
```

### 5.3.3 监控服务通用方法

　　1. 监控端口 netstat ss lsof  ==》 wc -l

　　2. 监控进程 ps -ef|grep 进程|wc -l  试运行一下

　　3. 模拟客户端的使用方式监控服务端

  　　    web  ==》 curl

​     　　 mysql ==》 select insert

   　　   memcache ==》 set再get

## 5.4 实施全网监控

*安装客户端脚本，for centos6*

```
#!/bin/bash

#设置解析
# echo '10.0.0.1 mirrors.aliyuncs.com mirrors.aliyun.com repo.zabbix.com' >> /etc/hosts

#安装zabbix源、aliyu nYUM源
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-6.repo
curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-6.repo
rpm -ivh http://repo.zabbix.com/zabbix/3.0/rhel/6/x86_64/zabbix-release-3.0-1.el6.noarch.rpm

yum clean all
yum clean all
#安装zabbix客户端
yum install zabbix-agent -y
sed -i.ori 's#Server=127.0.0.1#Server=172.16.1.61#' /etc/zabbix/zabbix_agentd.conf
/etc/init.d/zabbix-agent start

#写入开机自启动
chmod +x /etc/rc.d/rc.local
cat >>/etc/rc.d/rc.local<<EOF
/etc/init.d/zabbix-agent start
EOF
```

### 5.4.1 使用自动发现规则

添加自动发现规则

![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123170517165-1405132488.png) 

   创建发现动作

![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123170548790-1913820945.png) 

   查看自动发现的机器。

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123170556196-399583243.png)

### 5.4.2 监控备份服务器

利用系统自带键值进行监控*net.tcp.listen[port]* 创建新的模板

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123170605461-15380890.png)

在服务端进行测试

```
[root@m01 ~]# zabbix_get -s 172.16.1.41 -p 10050 -k "net.tcp.listen[873]"
1

# 1为端口在监听 0为端口未监听
```

将模板添加到主机

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123170623211-1934949165.png)

### 5.4.3 监控NFS服务器

创建nfs监控模板

使用 *proc.num[<name>,<user>,<state>,<cmdline>]*  键值，检测nfs进程的数量

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123170642743-1530283916.png) 

在服务端进行测试

```
[root@m01 ~]# zabbix_get -s 172.16.1.31 -p 10050 -k "proc.num[,,,rpc]"
5

[root@m01 ~]# zabbix_get -s 172.16.1.31 -p 10050 -k "proc.num[nfsd,,,]
8
```

 

将模板绑定到主机

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123170706790-398071765.png)

### 5.4.4 监控MySQL服务器

将自带的mysqlkey值加上mysql的账户密码，否则不能获取到数据。

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123170716633-1544519962.png)

使用系统自带模板  net.tcp.port[<ip>,port] 利用自带的监控端口键值进行监控

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123170725196-1197139845.png)

添加新的mysql监控项端口

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123170733586-1565655135.png)

```
[root@m01 ~]# zabbix_get -s 172.16.1.51 -p 10050 -k "net.tcp.port[,3306]"
1

#检查是否能建立 TCP 连接到指定端口。返回 0 - 不能连接；1 - 可以连接
```

将模板关联到主机

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123170751618-1705878150.png)

### 5.4.5 监控web服务器

创建监控模板 监控 nginx服务与 80 端口

```
    proc.num[<name>,<user>,<state>,<cmdline>]   进程数。返回整数
    net.tcp.port[<ip>,port] 检查是否能建立 TCP 连接到指定端口。返回 0 - 不能连接；1 - 可以连接
```

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123170811836-1213059726.png)

```
[root@m01 ~]# zabbix_get -s 172.16.1.8 -p 10050 -k "proc.num[,,,nginx]"
2

[root@m01 ~]# zabbix_get -s 172.16.1.8 -p 10050 -k "net.tcp.port[,80]"
1
```

将模板关联到主机

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123170830836-1859599772.png)

### 5.4.6 监控URL地址

创建监测页面

```
echo ok >> /application/nginx/html/www/check.html
```

 

测试监控面页

```
[root@web03 ~]# for ip in 7 8 9 ;do curl 10.0.0.$ip/check.html ;done
ok
ok
ok
```

创建web监测模板

   *创建应用集*

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123170901946-1613642326.png)

   *创建Web**场景*

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123170913008-168117527.png)

   *创建图形*

[![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123170934040-1367666440.png)](http://10.0.0.61/zabbix/chart2.php?graphid=668&period=60&stime=20191122164643&updateProfile=1&profileIdx=web.screens&profileIdx2=668&width=1052&sid=8a1fe32c9614ae35&screenid=&curtime=1511340464305)[ ](http://10.0.0.61/zabbix/chart2.php?graphid=668&period=60&stime=20191122164643&updateProfile=1&profileIdx=web.screens&profileIdx2=668&width=1052&sid=8a1fe32c9614ae35&screenid=&curtime=1511340464305)

将模板关联到主机

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123170948165-1061354150.png)

监测结果

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123170954774-1374734119.png)

### 5.4.7 监控反向代理服务器

创建自定义key

```
[root@lb01 ~]# cat  /etc/zabbix/zabbix_agentd.d/userparameter_nk.conf
UserParameter=keep-ip,ip a |grep 10.0.0.3|wc -l
```

在服务端测试

```
[root@m01 ~]# zabbix_get -s 172.16.1.5  -p 10050 -k "keep-ip"
1

[root@m01 ~]# zabbix_get -s 172.16.1.6  -p 10050 -k "keep-ip"
0
```

在web界面添加模板

![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123171017774-684187486.png) 

将模板关联到主机

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123171025993-90494591.png)

### 5.4.8 监控Nginx的7种连接状态

```
nginx服务器显示status
……
    location /status {
           stub_status on;
           access_log off;
    }
……
```

 

```
[root@web01 ~]# for ip in 7 8 9 ;do curl 172.16.1.$ip/status ;done
Active connections: 1
server accepts handled requests
 73 73 69
Reading: 0 Writing: 1 Waiting: 0

Active connections: 1
server accepts handled requests
 134 134 127
Reading: 0 Writing: 1 Waiting: 0

Active connections: 1
server accepts handled requests
 7 7 7
Reading: 0 Writing: 1 Waiting: 0
```

在nginx服务器上添加key

```
cat >/etc/zabbix/zabbix_agentd.d/userparameter_nginx_status.conf <<'EOF'
UserParameter=nginx_active,curl -s  127.0.0.1/status|awk '/Active/ {print $NF}'
UserParameter=nginx_accepts,curl -s  127.0.0.1/status|awk 'NR==3 {print $1}'
UserParameter=nginx_handled,curl -s  127.0.0.1/status|awk 'NR==3 {print $2}'
UserParameter=nginx_requests,curl -s  127.0.0.1/status|awk 'NR==3 {print $3}'
UserParameter=nginx_reading,curl -s  127.0.0.1/status|awk 'NR==4 {print $2}'
UserParameter=nginx_writing,curl -s  127.0.0.1/status|awk 'NR==4 {print $4}'
UserParameter=nginx_waiting,curl -s  127.0.0.1/status|awk 'NR==4 {print $6}'
EOF
```

服务端测试

```
[root@m01 ~]# zabbix_get -s 172.16.1.7  -p 10050 -k "nginx_waiting"
0

[root@m01 ~]# zabbix_get -s 172.16.1.8  -p 10050 -k "nginx_waiting"
0

[root@m01 ~]# zabbix_get -s 172.16.1.9  -p 10050 -k "nginx_waiting"
0
```

在zabbix-web上添加

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123171149430-1273155516.png)

监控项

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123171156868-200802360.png)

添加图形

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123171204665-213131354.png)

将模板关联到主机

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123171212368-480366619.png)

查看添加的图形

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123171219024-1107722962.png)

![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123171227727-507986617.png)

# 第6章 自动发现与自动注册

## 6.1 自动注册与自动注册

### 6.1.1 简介

**自动发现：**

```
zabbix Server主动发现所有客户端，然后将客户端登记自己的小本本上，缺点zabbix server压力山大（网段大，客户端多），时间消耗多。
```

**自动注册：**

```
zabbix agent主动到zabbix Server上报到，登记；缺点agent有可能找不到Server（配置出错）
```

### 6.1.2 两种模式

```
被动模式：默认  agent被server抓取数据 （都是在agent的立场上说）
主动模式：agent主动将数据发到server端 （都是在agent的立场上说）
```

​     **注意：** **两种模式都是在agent****上进行配置**

​     **zabbix** **的使用要在hosts****文件中预先做好主机名的解析**

## 6.2 自动发现--被动模式

　第一个里程碑：完成之前的安装

```
zabbix Server安装完毕
```

   第二个里程碑：配置agent客户端

```
zabbix agent安装完毕，注意配置Server=172.16.1.61
```

   第三个里程碑：在web界面上进行配置

```
    web界面：配置 >> 自动发现 >> Local network
        使用自带的自动发现规则（进行修改）即可
```

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123171340696-1752663359.png)

```
    在ip范围内输入ip，注意格式；
    延迟在实际的生产环境中要大一些，实验环境可以小一些
```

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123171400430-1257844571.png)

   **创建发现动作**

```
    配置 >> 动作 >> Auto discovery. Linux servers.
```

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123171416243-643188941.png)

①  配置动作

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123171442665-1032645950.png)

②  在条件中添加条件，让添加更准确

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123171450352-773318655.png)

③  在操作中添加

a)  添加主机与启用主机

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123171459915-585599756.png)

  　　  然后等待者客户端自动上门就好😏

## 6.3 自动注册--主动模式

　第一个里程碑：zabbix Server安装完毕 （完成）

```
zabbix Server安装完毕
```

   第二个里程碑：zabbix agent安装完毕，需要额外增加的配置

```
vim /etc/zabbix/zabbix_agentd.conf
ServerActive=172.16.1.61
# Hostname=Zabbix server
HostnameItem=system.hostname
 
systemctl restart zabbix-agent.service
netstat -tunlp|grep zabbix
```

​    源文件与修改后对比

![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123171548352-671150030.png)![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123171553258-1045944692.png)

　   第三个里程碑：在web见面上进行配置

```
1 配置 >> 动作 >> 事件源(自动注册) >> 创建动作
```

![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123171620446-2129676737.png) 

​    创建动作，添加名称即可

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123171641633-1899137338.png)

​    条件中也无需修改

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123171650227-1035954322.png)

​    在动作中添加动作

（添加主机、添加到主机群组、链接到模板）

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123171658743-2090662666.png)

​    添加完动作后，等待就行了

​    注意：重启客户端可以加速发现。但是在生产环境中勿用。

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123171705680-1480125827.png)

# 第7章 分布式监控与SNMP监控

## 7.1 分布式监控

### 7.1.1 作用

  　　分担压力，减轻负载

  　　多机房监控

　　zabbix Server  ===》  zabbix agent （只能同一个局域网监控）

**分担压力，降低负载**

```
  zabbix Server ===》  zabbix proxy  ===》zabbix agent1 agent2 agent3 。。。
    172.16.1.61           172.16.1.21        172.16.1.0/24
                ===》  zabbix proxy  ===》zabbix agent4 agent5 agent6 。。。
```

**多机房监控**

```
    zabbix Server(北京)           ==》  zabbix proxy（每个机房搭建）  ==》 zabbix agent
    122.71.240.233/172.16.1.61          122.71.241.11/172.16.2.21     172.16.2.0/24
```

### 7.1.2 环境说明

```
    zabbix server m01
    zabbix proxy cache01
    zabbix agent  cache01
```

### 7.1.3 配置zabbix proxy

　**第一个里程碑**：配置zabbix yum源，并安装proxy

```
rpm -ivh http://repo.zabbix.com/zabbix/3.0/rhel/7/x86_64/zabbix-release-3.0-1.el7.noarch.rpm
yum install zabbix-proxy-mysql -y
```

   **第二个里程碑：安装数据库**

​    zabbix  proxy也需要数据库，这个数据库不是用于存储监控数据的 只是用于存储配置信息

   #安装数据库

```
yum -y install mariadb-server
systemctl start mariadb.service
```

   #建立数据库

```
mysql
create database zabbix_proxy character set utf8 collate utf8_bin;
grant all privileges on zabbix_proxy.* to zabbix@'localhost' identified by 'zabbix';
exit
```

   #导入数据文件

```
zcat /usr/share/doc/zabbix-proxy-mysql-3.0.13/schema.sql.gz |mysql -uzabbix -pzabbix zabbix_proxy
```

   #配置zabbix proxy 连接数据库

```
sed -i.ori '162a DBPassword=zabbix' /etc/zabbix/zabbix_proxy.conf
sed -i 's#Server=127.0.0.1#Server=172.16.1.61#' /etc/zabbix/zabbix_proxy.conf
sed -i 's#Hostname=Zabbix proxy#Hostname=cache01#' /etc/zabbix/zabbix_proxy.conf

# Hostname 作为后面添加的代理程序名称，要保持一致
```

   #启动

```
systemctl restart zabbix-proxy.service
```

   #检查端口

```
[root@cache01 ~]# netstat -lntup |grep zabbix
tcp        0      0 0.0.0.0:10050     0.0.0.0:*       LISTEN      105762/zabbix_agent
tcp        0      0 0.0.0.0:10051   0.0.0.0:*         LISTEN      85273/zabbix_proxy 
tcp6       0      0 :::10050       :::*      LISTEN      105762/zabbix_agent
tcp6       0      0 :::10051  :::*           LISTEN      85273/zabbix_proxy 
```

   **第三个里程碑：**修改agent配置指向 proxy

```
[root@cache01 ~]# grep ^Server /etc/zabbix/zabbix_agentd.conf
Server=172.16.1.61
ServerActive=172.16.1.61

[root@cache01 ~]# sed -i 's#172.16.1.61#172.16.1.21#g' /etc/zabbix/zabbix_agentd.conf

[root@cache01 ~]# grep ^Server /etc/zabbix/zabbix_agentd.conf
Server=172.16.1.21
ServerActive=172.16.1.21

[root@cache01 ~]# systemctl restart zabbix-agent.service
```

   **第四个里程碑：**web界面添加代理

​    管理 >> agent代理程序 >> 创建代理

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123171925430-1950514120.png)

   代理程序名称要填写主机名

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123171933336-673235419.png)

   稍等片刻就能在程序中出现代理

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123171940665-2068638027.png)

   在主机中能发现主机代理

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123171948649-339116378.png)

## 7.2 SNMP监控

### 7.2.1 使用范围

　　无法安装agent  很多前辈的监控软件都可以监控各种设备  都是通过snmp监控

　　snmp simple network manager protocol 简单网络管理协议

  　 简单网络管理协议（SNMP），由一组网络管理的标准组成，包含一个应用层协议（application layer protocol）、数据库模型（database schema）和一组资源对象。该协议能够支持网络管理系统，用以监测连接到网络上的设备是否有任何引起管理上关注的情况。

### 7.2.2 安装snmp程序

```
yum -y install net-snmp net-snmp-utils
```

### 7.2.3 配置snmp程序

```
sed -i.ori '57a view systemview   included  .1' /etc/snmp/snmpd.conf
systemctl start snmpd.service
```

### 7.2.4 测试snmp

```
[root@m01 ~]# snmpwalk -v 2c -c public 127.0.0.1 sysname
SNMPv2-MIB::sysName.0 = STRING: m01
```

**说明：**

 　　   # snmpwalk 类似 zabbix_get

　　　# -v 2c  指定使用snmp协议的版本  snmp分为v1 v2 v3

　　　# -c public  指定暗号

　　　# sysname  类似zabbix的key

### 7.2.5 在web界面进行配置

添加新的主机，注意使用snmp接口

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123172038696-1317400757.png)

选择模板，注意使用SNMP的模板

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123172052305-1411663771.png)

​    添加完成就能够在主机中看到snmp监控对的主机

 ![img](https://images2017.cnblogs.com/blog/1190037/201711/1190037-20171123172059024-1436589674.png)



# 第8章 监控JVM

## 8.1 zabbix-java-gateway

1. 下载zabbix-java-gateway

```
yum install -y zabbix-java-gateway
```

> 需要有java环境支持

配置文件地址: `/etc/zabbix/zabbix_java_gateway.conf`

2. 启动命令

> sudo zabbix_java_gateway start

3. spring-boot||tomcat启动配置参数

```tex
CATALINA_OPTS="$CATALINA_OPTS 
  -Dcom.sun.management.jmxremote #开启远程监控
  -Dcom.sun.management.jmxremote.port=12345 #远程监控端口
  -Dcom.sun.management.jmxremote.ssl=false #远程ssl验证为false
  -Dcom.sun.management.jmxremote.authenticate=false #关闭权限认证
  -Djava.rmi.server.hostname=172.16.2.150" #提供数据的的主机地址（由于我是用的一台机器，所以IP相同，如果是生产环境不同的机器，这个地址是部署了tomcat的主机地址）	
```



### 7.2.6 附录

```
    ##SNMP OID列表 监控需要用到的OID
    http://www.ttlsa.com/monitor/snmp-oid/
    cmdb 资源管理系统
```