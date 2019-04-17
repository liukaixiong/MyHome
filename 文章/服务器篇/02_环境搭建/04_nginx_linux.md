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

 

### 如果访问nginx 403 

需要修改：/root/nginx/conf/nginx.conf  第一行 # user nobody

然后修改 成为 user root  （主要去掉#）

### 查看nginx已经加载了哪些模块?

nginx -V



## 反向代理

```tex
upstream weme{
	server 127.0.0.1:60006 weight=1;
}
location /web {
	proxy_set_header X-Real-IP $remote_addr;
	proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
	proxy_pass http://weme;
}
```

### 静态资源

```tex
location /assets/weme/ {
	alias /elab/nodeServer/weme-miniprogram-service/dist/static/weme/;
}
```

**注意的点**

- `alias` :  会将请求路径后面的作为最后一段，例如/assets/weme/b.html ,反向的路径 /elab/nodeServer/weme-miniprogram-service/dist/static/weme/b.html
- `root` : /assets/weme/b.html --> /elab/nodeServer/weme-miniprogram-service/dist/static/weme/**assets/weme/b.html**



## 证书授权

```tex
server { #mvp的接口地址
        listen 80;
        listen 443 ssl;
        server_name openapi.elab-plus.com;  #域名可以有多个，用空格隔开：例如 server_name www.ha97.com ha97.com;
       # ssl_certificate   cert/214404610410472.pem;
        ssl_certificate   cert/openapi/20191225/1_openapi.elab-plus.com_bundle.pem;
      #  ssl_certificate_key  cert/214404610410472.key;
        ssl_certificate_key  cert/openapi/20191225/2_openapi.elab-plus.com.key;
        ssl_session_timeout 5m;
        ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE:ECDH:AES:HIGH:!NULL:!aNULL:!MD5:!ADH:!RC4;
        ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
        ssl_prefer_server_ciphers on;
        #charset koi8-r;
        access_log  /root/nginx/logs/openapi.access.log  main;
        error_log   /root/nginx/logs/openapi.error.log;

        location / {
            proxy_pass http://openapi.elab-plus.com;
            proxy_intercept_errors on;

        #    proxy_redirect     off;
        #    proxy_set_header   Host             openapi.elab-plus.com;
            proxy_set_header   X-Real-IP        $remote_addr;
            proxy_set_header   X-Forwarded-For  $proxy_add_x_forwarded_for;
        #    proxy_pass   http://openapi.elab-plus.com;
            proxy_set_header        Host $http_host;
            proxy_connect_timeout 300s;
            proxy_send_timeout 300s;
            proxy_read_timeout 300s;
        }
    }
```

### 如何将.crt的ssl证书文件转换成.pem格式

```tex
openssl x509 -in www.xx.com.crt -out www.xx.com.pem
```

