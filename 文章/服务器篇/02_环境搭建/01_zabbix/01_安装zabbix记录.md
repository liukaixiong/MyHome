Zabbix是当前主流开源的企业级分布式监控系统。Zabbix特点是：安装部署较简单，且默认自带了多种监控告警模板。也具备较强的仪表盘展示功能；提供API接口，支持脚本调用；支持自定义编写插件以及监控模板。

## 一、安装zabbix软件包 

环境说明：

```shell
# 查看系统版本号
> cat /etc/redhat-release
CentOS Linux release 7.7.1908 (Core)

uname -a

Linux monitor01 3.10.0-1062.18.1.el7.x86_64 #1 SMP Tue Mar 17 23:49:17 UTC 2020 x86_64 x86_64 x86_64 GNU/Linux

# 确保防火墙、selinux已经关闭
> systemctl stop Firewalld
> systemctl disable Firewalld
> sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
> setenforce 0

# 修改用户资源限制
> vim /etc/security/limits.conf
root soft nofile 65535
root hard nofile 65535
* soft nproc 65535
* hard nproc 65535
* soft nofile 65535
* hard nofile 65535
* hard core unlimited
* soft core unlimited

# 安装zabbix yum源
>  rpm -Uvh https://repo.zabbix.com/zabbix/4.4/rhel/7/x86_64/zabbix-release-4.4-1.el7.noarch.rpm
# 安装epel源，用于支持nginx
> yum install epel-release
# 查看zabbix相关软件包
> yum search zabbix  
# 安装zabbix相关软件包（注意可能会有些包会下载失败，多执行下面几次命令就行了。）
> yum -y install zabbix-*
# 或者只安装以下组件 和上面的二选一
> for pkgs in  zabbix-server-mysql zabbix-web-mysql zabbix-web-mysql zabbix-agent zabbix-get zabbix-web zabbix-sender zabbix-nginx-conf ;do yum -y install $pkgs;done
```

## 二、安装mariadb并初始化导入zabbix表结构数据**

```shell
# 安装mariadb数据库并启动
> yum -y install mariadb-*
# 设置开机启动
> systemctl enable mariadb
> systemctl start mariadb
# 创建zabbix数据库
> create database zabbix character set utf8 collate utf8_bin;
> grant all privileges on zabbix.* to 'zabbix'@'localhost' identified by 'zabbix@123';
> flush privileges;
> quit;
#导入数据
> zcat /usr/share/doc/zabbix-server-mysql-*/create.sql.gz |mysql -uzabbix -p'zabbix@123' -b zabbix
```

## 三、修改zabbix_server.conf并启动zabbix_server**

```shell
# cat /etc/zabbix/zabbix_server.conf |grep -v "^#" |grep -v "^$" |grep -v grep  
# 先备份老的zabbix配置文件
> mv /etc/zabbix/zabbix_server.conf /etc/zabbix/zabbix_server.conf.bak
# 构建新的配置文件并添加内容
> vim /etc/zabbix/zabbix_server.conf
```

LogFile=/var/log/zabbix/zabbix_server.log

LogFileSize=0

DebugLevel=3

PidFile=/var/run/zabbix/zabbix_server.pid

SocketDir=/var/run/zabbix

DBName=zabbix

DBUser=zabbix

DBPassword=zabbix@123

StartPollers=16

StartPollersUnreachable=4

StartTrappers=10

StartPingers=8

SNMPTrapperFile=/var/log/snmptrap/snmptrap.log

CacheSize=1024M

StartDBSyncers=8

HistoryCacheSize=1024M

HistoryIndexCacheSize=256M

TrendCacheSize=1024M

Timeout=4

AlertScriptsPath=/usr/lib/zabbix/alertscripts

ExternalScripts=/usr/lib/zabbix/externalscripts

LogSlowQueries=3000

StatsAllowedIP=127.0.0.1

```shell
# 设置开机启动
> systemctl enable zabbix-server
> systemctl start zabbix-server
```

## 四、修改nginx/php-fpm配置

**将server端口配置为8080，端口配置没有特殊要求，只要未被占用都可配置。若想使用80端口，则需要注释或修改nginx.conf的server {}段配置**

```shell
# 修改zabbix的nginx配置
> vi /etc/nginx/conf.d/zabbix.conf
```

 listen      8080;

 server_name   monitor.com;

```shell
# 修改php时区
> vi /etc/php-fpm.d/zabbix.conf
```

php_value[date.timezone] = Asia/Shanghai

```shell
# 设置zabbix客户端开机启动
> systemctl enable php-fpm
> systemctl restart php-fpm
# 设置nginx启动
> systemctl enable nginx
> systemctl start nginx
# 服务端的agent也需要启动!!!!  
> systemctl enable zabbix-agent
> systemctl restart zabbix-agent
```

## 五、设置并登录zabbix系统

访问[http://IP:port/setup.php](https://links.jianshu.com/go?to=http%3A%2F%2Fip%3Aport%2Fsetup.php)



![img](https:////upload-images.jianshu.io/upload_images/23250218-eea4aaaa5eb20baa.png?imageMogr2/auto-orient/strip|imageView2/2/w/855/format/webp)



![img](https:////upload-images.jianshu.io/upload_images/23250218-06f61f318eebc50e.png?imageMogr2/auto-orient/strip|imageView2/2/w/855/format/webp)



![img](https:////upload-images.jianshu.io/upload_images/23250218-8caffe9f5690e253.png?imageMogr2/auto-orient/strip|imageView2/2/w/864/format/webp)





Zabbix 服务名是可选设置

![img](https:////upload-images.jianshu.io/upload_images/23250218-67bc175d849e8ec3.png?imageMogr2/auto-orient/strip|imageView2/2/w/861/format/webp)



![img](https:////upload-images.jianshu.io/upload_images/23250218-194b5d3476b547c5.png?imageMogr2/auto-orient/strip|imageView2/2/w/856/format/webp)



![img](https:////upload-images.jianshu.io/upload_images/23250218-fcd042a340ca6b82.png?imageMogr2/auto-orient/strip|imageView2/2/w/853/format/webp)





![img](https:////upload-images.jianshu.io/upload_images/23250218-b6c812838ffc6d71.png?imageMogr2/auto-orient/strip|imageView2/2/w/539/format/webp)





![img](https:////upload-images.jianshu.io/upload_images/23250218-87c5a82690f57fbd?imageMogr2/auto-orient/strip|imageView2/2/w/1200/format/webp)

![img](https:////upload-images.jianshu.io/upload_images/23250218-e03b16e91066d924?imageMogr2/auto-orient/strip|imageView2/2/w/1200/format/webp)

配置action，实现使安装有Zabbix Agent的Linux自动注册到Zabbix Server端。

步骤：configuration>>action>>Event source（选择Auto registration）>>Create Action，我们按如下步骤来定义个action

![img](https:////upload-images.jianshu.io/upload_images/23250218-95f8eb30365d7eff?imageMogr2/auto-orient/strip|imageView2/2/w/1200/format/webp)



![img](https:////upload-images.jianshu.io/upload_images/23250218-738898761ac29ead.png?imageMogr2/auto-orient/strip|imageView2/2/w/878/format/webp)



![img](https:////upload-images.jianshu.io/upload_images/23250218-dc487a009dbe5710.png?imageMogr2/auto-orient/strip|imageView2/2/w/893/format/webp)



![img](https:////upload-images.jianshu.io/upload_images/23250218-b1c28932b0a683f1?imageMogr2/auto-orient/strip|imageView2/2/w/1200/format/webp)



## 六、安装zabbix-agent

```shell
# 另一台安装代理
> rpm -Uvh https://repo.zabbix.com/zabbix/4.4/rhel/7/x86_64/zabbix-release-4.4-1.el7.noarch.rpm
> yum -y install zabbix-agent
# 修改zabbix-agent配置，
# monitor01为Zabbix Server主机的hostname，(也就是server的hostName)
> sed -i "s/Server=127.0.0.1/Server=monitor01/g" /etc/zabbix/zabbix_agentd.conf
# ServerActive 这里要注意的是server的ip ， 这里最好写上server的内网IP
> sed -i "s/ServerActive=127.0.0.1/ServerActive=monitor01/g" /etc/zabbix/zabbix_agentd.conf
# 所有Zabbix agent主机上都要添加Zabbix Server主机的hostname。
> sed -i "s#Hostname=Zabbix server#Hostname=$(hostname)#g" /etc/zabbix/zabbix_agentd.conf

> sed -i "s#\# HostMetadataItem=#HostMetadataItem=system.uname#g" /etc/zabbix/zabbix_agentd.conf  
```

启动zabbix-agent

```shell
systemctl enable zabbix-agent
systemctl restart zabbix-agent
```

如果有几十上百个节点，我们就需要借助Ansible或SaltStack等批量部署工具来快速部署了。

安装Zabbix Agent后的主机会自动注册到Zabbix Server上，并且Availability状态显示为绿色

![img](https:////upload-images.jianshu.io/upload_images/23250218-15b9149ff133a633.png?imageMogr2/auto-orient/strip|imageView2/2/w/40/format/webp)

就表示添加成功了。

![img](https:////upload-images.jianshu.io/upload_images/23250218-1bdb543ed95723af?imageMogr2/auto-orient/strip|imageView2/2/w/1200/format/webp)



由于本系列教程讲述的重点是Grafana的使用，Zabbix仅是为Grafana提供要展示数据的接口，所以不再重点讲述，后续在讲解Grafana使用时会再穿插讲解一些Zabbix使用技巧。

总结：对Linux较熟悉的同学部署上述环境应该so easy。当然部署方法多种多样，想挑战又有时间可以全部用源码来编译安装，能更体验过程；想更简单一点的话，可以尝试用zabbix官方提供的docker镜像，但前提得会用docker。

写给自己：世上无难事，只怕有心人。



 