### 1、JDK内存优化

- 建议设置堆的最大值设为可用内存的80%
- 设置的文件是`catalina.sh`
  - -Xms初始化内存大小
  - -Xmx可以使用的最大内存
  - -XX:PermSize 内存永久保留区域
  - -XX:MaxPermSize 内存最大永久区保留大小
  - -Xmn JVM最小内存

### 2、线程优化

**server.xml:**

- **maxThreads**: tomcat使用线程来处理每个请求。这个值表示tomcat可创建最大的线程数
- **acceptCount**:当所有指定的线程数都已经被使用的情况下,可以放到处理队列中的请求数，超过这个数的请求将不予处理。
- **minSpareThreads** : tomcat初始化的时候创建的线程数
- **maxSpareThreads**:一旦创建的线程超过这个值,tomcat就会关闭不在需要的的socket线程
- **enableLookups**:是否反查域名,默认值为true,为了提高处理能力应该设置为false
- **connnectionTimeout**: 网络连接超时数
- **maxKeepAliveRequests**:保持请求数量，默认值100。 bufferSize： 输入流缓冲大小，默认值2048 bytes。
- **compression**: 压缩传输

**32G内存配置:**

```xml
<Connector port="8080" protocol="HTTP/1.1"  connectionTimeout="20000" maxThreads="1000" minSpareThreads="60" maxSpareThreads="600"  acceptCount="120"   redirectPort="8443" URIEncoding="utf-8"/>
```

