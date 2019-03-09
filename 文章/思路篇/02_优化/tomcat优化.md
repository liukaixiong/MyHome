# 优化思路

- 减少配置文件中不需要的配置标签
- 基于JVM的优化

## web.xml

`DefaultServlet` 静态资源 删除

`JSPServlet` : JSP文件处理 - 删除

`mine-mapping` : 请求类型删除

`webcome-file-list` : 欢迎页指定删除

`Server.xml` : AJP Connector 

## conf/Server.xml

### connector

`protocol` : 自动选择让

