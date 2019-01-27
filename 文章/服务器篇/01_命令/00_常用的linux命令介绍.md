# 常用的linux配置

## linux查看history历史记录显示执行时间

```shell
# linux查看history历史记录显示执行时间

vim /etc/profile

#末尾添加

export HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S "

# 保存退出
# 执行以下命令即时生效
  
source /etc/profile
```

