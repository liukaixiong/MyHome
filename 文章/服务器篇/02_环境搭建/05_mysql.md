# 安装



1. 首先打开编辑器

yum install mysql-community-server

2.在打开的vi 编辑器中输入：

```html
# Enable to use MySQL 5.6
[mysql56-community]
name=MySQL 5.6 Community Server
baseurl=http://repo.mysql.com/yum/mysql-5.6-community/el/6/$basearch/
enabled=1
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-mysql3
```

3.保存后输入：

yum repolist enabled | grep mysql

> 查看是否版本是5.6的

4. 安装服务

yum install mysql-community-server

5. 启动服务

service mysqld start 

service mysqld restart

6. Linux下设置Mysql表名不区分大小写

用root账号登录后vi /etc/my.cnf 在[mysqld]下面加lower_case_table_names=1

7. 设置允许远程登录

mysql> use mysql;

查看用户

select host,user,password from user;

修改用户

update user set password=password('123456') where user='root';

刷新权限

flush privileges;



# 卸载Mysql

1： 检查是否安装了MySQL组件。

[root@DB-Server init.d]# rpm -qa | grep -i mysql
	mysql-community-client-5.7.19-1.el7.x86_64
	mysql-community-common-5.7.19-1.el7.x86_64
	mysql-community-libs-compat-5.7.19-1.el7.x86_64
	mysql-community-libs-5.7.19-1.el7.x86_64
	qt-mysql-4.8.5-13.el7.x86_64
	mysql57-community-release-el7-11.noarch
	mysql-community-server-5.7.19-1.el7.x86_64
	perl-DBD-MySQL-4.023-5.el7.x86_64
2： 卸载前关闭MySQL服务

systemctl stop mysqld

yum -y remove mysql-community-client-5.7.19-1.el7.x86_64
yum -y remove mysql-community-common-5.7.19-1.el7.x86_64
yum -y remove mysql-community-libs-compat-5.7.19-1.el7.x86_64
yum -y remove mysql57-community-release-el7-11.noarch
yum -y remove mysql-community-server-5.7.19-1.el7.x86_64

3：删除MySQL对应的文件夹

```shell
[root@DB-Server init.d]# whereis mysql
mysql:
[root@DB-Server init.d]# find / -name mysql
/var/lib/mysql
/var/lib/mysql/mysql
/usr/lib64/mysql
[root@DB-Server init.d]# rm -rf /var/lib/mysql
[root@DB-Server init.d]# rm -rf /var/lib/mysql/mysql
[root@DB-Server init.d]# rm -rf /usr/lib64/mysql
```



4：确认MySQL是否卸载删除

[root@DB-Server init.d]# rpm -qa | grep -i mysql

5：重新安装MySQL5.6版本，主要参考 （略写，主要参考以下链接）

 http://blog.csdn.net/huhuhuemail/article/details/77498891

> 这里主要是因为上次已经将服务删除了,需要重新更新一下才能通过yum继续下载

shell> wget https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm
shell> yum mysql57-community-release-el7-11.noarch.rpm 
这步如果报错：已加载插件：fastestmirror, langpacks
没有该命令：mysql57-community-release-el7-11.noarch.rpm。请使用 /usr/bin/yum --help
改用以下命令：
yum localinstall mysql57-community-release-el7-11.noarch.rpm  
shell> yum repolist enabled | grep "mysql.*-community.*"

**这里是重新安装，如果你需要安装的是5.6的可以从头开始看** 

shell> yum install mysql-community-server
修改mysql配置文件

启动MySQL服务
--------------------- 




# 修改数据库表情字符集



/etc/my.conf

```shell
[client]
default-character-set = utf8mb4


[mysql]
default-character-set = utf8mb4


[mysqld]
character-set-client-handshake=false
character-set-server=utf8mb4
init_connect='SET NAMES utf8mb4'

```

查看结果 : 

SHOW VARIABLES WHERE Variable_name LIKE 'character\_set\_%' OR Variable_name LIKE 'collation%'

