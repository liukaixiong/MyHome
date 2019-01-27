# [Linux安装nginx](https://www.cnblogs.com/tangqiu/p/9812078.html)

1:安装工具包 wget、vim和gcc
yum install -y wget  
yum install -y vim-enhanced  
yum install -y make cmake gcc gcc-c++  
2:下载nginx安装包
wget 或者Windows下载安装包nginx-1.15.5.tar.gz
3:安装依赖包
yum install -y pcre pcre-devel
yum install -y zlib zlib-devel
yum install -y openssl openssl-devel
4:解压nginx-1.15.5.tar.gz到
tar -zxvf nginx-1.15.5tar.gz 
5:进行configure配置
进入nginx-1.15.5目录然后在执行./configure命令
 ./configure --prefix=/root/nginx --with-http_stub_status_module --with-http_ssl_module
6:编译安装

 make

make install

7:启动Nginx，启动完之后检查nginx是否已经正常启动，看到如下信息说明正常启动

/root/nginx/sbin/nginx
ps -ef | grep nginx
root     24956     1  0 19:41 ?        00:00:00 nginx: master process /usr/local/nginx/sbin/nginx
nobody   24957 24956  0 19:41 ?        00:00:00 nginx: worker process
root     24959 10533  0 19:41 pts/0    00:00:00 grep --color=auto nginx
如果要关闭nginx，我们可以使用如下命令：
 /root/nginx/sbin/nginx -s stop
如果想要重新热启动nginx，则使用如下命令：
/root/nginx/sbin/nginx -s reload

 

如果访问nginx 403 需要修改：/root/nginx/conf/nginx.conf  第一行 # user nobody

然后修改 成为 user root  （主要去掉#）



查看nginx已经加载了哪些模块?

nginx -V
