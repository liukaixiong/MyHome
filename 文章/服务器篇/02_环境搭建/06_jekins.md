



# Jenkins 环境搭建

## 下载war包

[war包加载地址](http://mirrors.jenkins-ci.org/war/)

下载tomcat ， 将war包丢入tomcat中运行起来

访问路径 : http://localhost:8080/jenkins

## 配置步骤 windos

### 一. 密码

根据指定路径获取password填入。

### 二. 选择社区插件

直接安装

### 三. 修改更新站点

系统管理 - 插件管理 - 高级

**升级站点**

```
1 http://mirror.xmission.com/jenkins/updates/update-center.json   # 推荐
2 http://mirrors.shu.edu.cn/jenkins/updates/current/update-center.json
3 https://mirrors.tuna.tsinghua.edu.cn/jenkins/updates/update-center.json
```

**离线下载** :<http://updates.jenkins-ci.org/download/plugins/>

### 四. 更新插件

Local : 本地语言设置 -> 系统 -> local : zh_CN

[Publish Over FTP](https://plugins.jenkins.io/publish-over-ftp) : 上传文件到服务器

[Git Parameter](https://plugins.jenkins.io/git-parameter) : 参数化构建引入git参数获取分支等等[
List Git Branches Parameter](https://wiki.jenkins.io/display/JENKINS/List+Git+Branches+Parameter+Plugin): 多个git仓库一起构建

 [Mask Passwords](https://plugins.jenkins.io/mask-passwords) : 入参密码屏蔽 不是特别好

Environment Injector : 注入环境变量

[Multijob](https://plugins.jenkins.io/jenkins-multijob-plugin) : 构建多个job

[Managed Scripts](https://wiki.jenkins-ci.org/display/JENKINS/Managed+Script+Plugin) : 管理shell脚本

Join : 构建完成之后出发其他job的执行

rebuild : 根据上一次的参数重新编译

Hidden Parameter : 隐藏参数

# 异常记录

### 1. Last unit does not have enough valid bits

查看 系统管理 -> 系统设置 -> **Mask Passwords - Enable Globally**、Enable Mask Passwords for ALL BUILDS 是否勾上，如果有 去掉。





## SpringBoot 发布远程

### 脚本

#### 涉及插件、命令

- sshpass 通过用户名和密码连接远程账户做操作
- spawn 构建一个守护线程接收远端发送过来的日志
- expect 并且进行匹配



# Jenkins远程发布

一. 安装 [Build Authorization Token Root Plugin](https://wiki.jenkins-ci.org/display/JENKINS/Build+Token+Root+Plugin) 插件

二. 为用户配置生成的token

三. 在job任务中选中触发远程构建，token填用户配置生成的token



四.通过http去触发构建

http://localhost:8080/jenkins/job/test/buildWithParameters?token=115d31f7d9e41dfa893e17b576268cd744



http://localhost:8080/jenkins/job/test2/buildWithParameters?token=asd



如果有参数则往后面累加。

## jenkins 密码保护

插件 : Environment Injector

**配置步骤** : 

系统设置 -> **Global Passwords** -> Global Passwords

**配置**

 构建环境 -> Inject passwords to the build as environment variables -> Global passwords [引入全局配置]

## 全局环境变量设置

系统设置 - **全局属性** - 环境变量

这里设置变量全局通用。