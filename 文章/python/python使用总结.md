## 替换下载源

首先在 windows 当前用户家的目录下，创建一个 pip 文件夹，然后创建一个pip.ini文件，修改文件内容为如下；

```shell
[global] 
index-url = http://mirrors.aliyun.com/pypi/simple/ 
[install] 
trusted-host=mirrors.aliyun.com 
```

