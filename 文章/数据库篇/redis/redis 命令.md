



### 查看redis连接数

CONFIG GET maxclients

CLIENT LIST			获取客户端列表
CLIENT SETNAME    	设置当前连接点redis的名称
CLIENT GETNAME    	查看当前连接的名称
CLIENT KILL ip:port    	杀死指定连接