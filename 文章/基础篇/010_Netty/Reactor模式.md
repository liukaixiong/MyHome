# Reactor模式

**为什么会有这种模式?**

首先它主要是为了解决高性能并发。

传统的网络编程的是通过:

```java
while(true){
    Socket socket = accept();
    // 请求转发
}
```

缺点: 效率太低。无法应对高并发。

升级版(多线程):

```java
while(true){
    Socket socket = accept();
    
    new Thread(socket)
}
```

