# [部署Percona监控和管理--- PMM Server](https://www.cnblogs.com/yancun8141/articles/10837638.html)

## 安装docker

[新手安装docker](https://www.runoob.com/docker/centos-docker-install.html)

1. 安装驱动包

```shell
yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2
```

2. 设置仓库(本身就是阿里云的可以不用设置)

```shell
yum-config-manager \
    --add-repo \
    http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
```

3. 安装

```shell
yum install docker-ce docker-ce-cli containerd.io
```

4. 启动

```shell
systemctl start docker
```

5. 测试运行

```shell
docker run hello-world  # 注意的是这里需要等一会,因为本地镜像没有,需要从远端下载
```

[阿里云提供加速](https://cr.console.aliyun.com/cn-hangzhou/instances/mirrors)

6. 开机启动

```shell
systemctl start docker
systemctl enable docker
```

验证docker版本

```shell
docker version
```

## 安装PMM服务器

1. 提取docker镜像( 如果您是第一次运行PMM Server，则不需要此步骤。但是，它可以确保如果在`2.8.0`本地有标记为可用图像的较旧版本 ，则将其替换为实际的最新版本。 )

```shell
docker pull percona / pmm-server：2
```

2. 创建PMM数据容器

```shell
docker create -v /opt/prometheus/data -v /opt/consul-data -v /var/lib/mysql -v /var/lib/grafana --name pmm-data percona/pmm-server:2 /bin/true
```

3. 启动

```shell
docker run -d -p 88:88  --volumes-from pmm-data --name pmm-server --restart always percona/pmm-server:2
```

4. 查看docker运行状态

```shell
docker ps
```

## 安装PMM客户端

1. 下载命令

```shell
# 下载源
yum install https://repo.percona.com/yum/percona-release-latest.noarch.rpm
# 开启源
percona-release disable all
percona-release enable original release
```



2. 连接PMM server

```shell
#注意，如果以上步骤docker run映射的端口不是80，比如为88，此时应该pmm-admin config --server ip地址:81
pmm-admin config --server-insecure-tls --server-url=https://admin:admin@<IP Address>:443
```



## 更新

## 使用Docker更新PMM服务器

1. 检查PMM服务器的安装版本。有两种方法。

   1. 用途：`docker ps`

      ```
      docker ps
      ```

      这将显示版本标签附加到图像名称（例如`percona/pmm-server:2`）。

   2. 用途：`docker exec`

      ```
      docker exec -it pmm-server curl -u admin:admin http://localhost/v1/version
      ```

      这将打印一个包含版本字段的JSON字符串。

2. 检查是否有PMM服务器的较新版本。

   访问https://hub.docker.com/r/percona/pmm-server/tags/。

3. 停止容器并创建备份。

   备份当前容器及其数据，以便您可以恢复使用它们，并作为安全措施，以防更新过程失败。

   ```
   docker stop pmm-server
   docker rename pmm-server pmm-server-backup
   docker cp pmm-data pmm-data-backup
   ```

4. 拉出新的PMM服务器映像。

   您可以指定确切的版本号或最新版本。

   要提取特定版本（本示例中为2.9.1）：

   ```
   docker pull percona/pmm-server:2.9.1
   ```

   要获取最新版本的PMM 2：

   ```
   docker pull percona/pmm-server:2
   ```

5. 运行图像。

   ```
   docker run -d -p 80:80 -p 443:443 --volumes-from pmm-data --name pmm-server --restart always percona/pmm-server:2.9.1
   ```

   （`pmm-data`是您现有的数据图像。）

6. 检查新版本。

   重复步骤1。您还可以检查PMM Server Web界面。



## Mysql授权

```
grant all privileges on *.* to 'pmm'@'172.19.189.160' identified by 'elab@123';
flush privileges;
```

官网推荐

```sql
GRANT SELECT, PROCESS, SUPER, REPLICATION CLIENT, RELOAD ON *.* TO 'pmm'@' localhost' IDENTIFIED BY 'pass' WITH MAX_USER_CONNECTIONS 10;
GRANT SELECT, UPDATE, DELETE, DROP ON performance_schema.* TO 'pmm'@'localhost';
```

阿里云

```sql
CREATE USER 'aliyun'@'%' IDENTIFIED BY PASSWORD '*6898950482C0553930FEA33664F18143369FB1FD';
GRANT SHOW DATABASES, PROCESS, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'aliyun'@'%';
GRANT SELECT ON *.*  TO 'aliyun'@'%';
```



[参考1](https://mritd.me/2020/01/21/set-up-percona-server/)

[docker安装 官网](https://www.percona.com/doc/percona-monitoring-and-management/2.x/install/docker.html)

