一、先去官网下载nodejs安装包

nodejs官网下载 
或者

wget https://nodejs.org/dist/v8.11.3/node-v8.11.3-linux-x64.tar.xz
1
二、下载后解压到你指定的软件安装目录进行安装
tar xf node-v8.11.3-linux-x64.tar.xz
1

##输入下面命令

```shell
ln -s /home/lst/Destop/node-v8.11.3-linux-x64/bin/node /usr/local/bin/node
ln -s /home/lst/Destop/node-v8.11.3-linux-x64/bin/npm /usr/local/bin/npm
```

## 测试

```tex
#node -v
v8.11.3

#npm -v
5.6.0
```

