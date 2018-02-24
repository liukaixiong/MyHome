# tomcat 性能调优

## tomcat 配置调优

1. 减配优化
   1. servlet
      1. ​
   2. value
2. 配置调整
   1. 关闭自动部署
   2. 线程池数量
3. 预编译优化
   1. jsp





### 减配优化

- 场景一 : 假设当前应用是Rest应用 

1. 分析 : 他不需要静态资源
2. 静态处理 : `defaultServlet`
3. 动态: 应用   `servlet`、`jspServlet`
4. SpringMVC : `DispatchServlet`

**优化方案:**

1. 通过移除`conf/web.xml` 
2. ​



清除掉server.xml 的日志记录 Valve 

```xml
 <Valve className="org.apache.catalina.valves.AccessLogValve" directory="logs"
               prefix="localhost_access_log." suffix=".txt"
               pattern="%h %l %u %t &quot;%r&quot; %s %b" />
```



