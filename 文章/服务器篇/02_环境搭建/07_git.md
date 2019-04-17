# 下载最新的git

[Git-github地址](https://github.com/git/git/)

[v2.20.2 目前较新的版本](https://github.com/git/git/archive/v2.20.1.tar.gz)

开始下载
```shell
wget https://github.com/git/git/archive/v2.20.1.tar.gz
```

下载完成之后解压。

```shell
tar -zxvf v2.20.1.tar.gz
```

## 编译安装git

### 依赖环境

```shell
yum install curl-devel expat-devel gettext-devel openssl-devel zlib-devel gcc perl-ExtUtils-MakeMaker
```

耐心等待安装，出现提示输入y即可；

> 如果安装依赖时自动装了git，可以采用yum remove git卸载。

### 编译git

进入git目录

```shell
make prefix=/usr/local/git all
# 安装Git至/usr/local/git路径
make prefix=/usr/local/git install
```

### 配置环境变量

```shell
vim /etc/profile
```

在底部加上Git相关配置信息:

```shell
PATH=$PATH:/usr/local/git/bin 
export PATH
```

这里配置完成之后，需要让配置文件生效。

```shell
source /etc/profile
```

### 验证

```shell
git --version
```

## 查看git安装位置

```shell
which git
```