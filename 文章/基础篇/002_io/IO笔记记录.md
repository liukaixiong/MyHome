# IO笔记记录

# BIO

- 阻塞型IO,并发的情况下效率会降低
  - 当数据没有准备好的情况下,不会立即返回结果,而是一直等待它的返回,当多个线程访问的时候会一致等待
- 读取数据的方式是从硬盘到内存中
- 通讯的时候数据传输是面向流的(Inputstream、OutputStream)
- 没有触发机制,只能通过轮训不停的接收

### 代码

```java
// 使用ServerSocket开启一个端口
ServerSocket socket = new ServerSocket("port");
// 然后通过轮训去去接收请求的到来
while(true){
  Socket client = sokcet.accept();
  // 然后通过流来获取数据
  Inputstream in = client.getInputStream();
  //缓冲区，数组而已
  byte [] buff = new byte[1024];
  int len = is.read(buff);
  //只要一直有数据写入，len就会一直大于0
  if(len > 0){
    String msg = new String(buff,0,len);
    System.out.println("收到" + msg);
  }
}
```



# NIO

- 非阻塞型IO
  - 当我们的进程访问我们的数据缓冲区的时候，如果数据没有准备好则直接返回，
    不会等待。如果数据已经准备好，也直接返回。
- IO方式:从内存到硬盘
- 数据的传输方式是面向缓冲buffer(多路复用)
- 触发机制:选择器(轮训机制)

## 代码

```java
// 开启一个管道(相当于一个服务大厅)
ServerSocketChannel server = ServerSocketChannel.open();
// 设置一个端口
server.bind(new IntetSocketAddress("端口"));
// 是否阻塞
server.configurationBlocking(false);
// 开启一个服务柜台,将所有请求进行排队
Selector selector = Selector.open();
// 将这个柜台和管道进行绑定
server.register(selector,Selector.OP_ACCEPT);


// 数据处理
//死循环，这里不会阻塞
//CPU工作频率可控了，是可控的固定值
while(true) { 
  //在轮询，我们服务大厅中，到底有多少个人正在排队
  int wait = selector.select();
  if(wait == 0) continue; //如果没有人排队，进入下一次轮询 
  //取号，默认给他分配个号码（排队号码）
  Set<SelectionKey> keys = selector.selectedKeys();  //可以通过这个方法，知道可用通道的集合
  Iterator<SelectionKey> iterator = keys.iterator();
  while(iterator.hasNext()) {
    SelectionKey key = (SelectionKey) iterator.next();
    //处理一个，号码就要被消除，打发他走人（别在服务大厅占着茅坑不拉屎了）
    //过号不候
    iterator.remove();
    //处理逻辑
    process(key);
  }
}
```



# 面向流和面向缓冲的区别

1. 面向流:
   1. 没有缓存到任何地方
   2. 无法移动流中的数据
2. 面向缓冲
   1. 将数据缓存到一个缓冲区中
   2. 可以针对缓冲区做前后的移动,灵活性高
   3. 但是需要针对数据判断是否需要,不能覆盖缓冲区中尚未处理的数据



# IO和NIO的数据处理使用场景

1. IO
   1. 数据读取的时候每次都要判断数据是否已经读取完毕
   2. 如果只需要处理少量的连接,并且每个连接占用的 宽带高数据量大,这时候IO可能更合适,因为他可以为每个连接用线程去处理
2. NIO
   1. 读取数据之前需要判断缓冲区的数据是否已经准备完毕
   2. 如果需要同时管理成千上万的连接,并且每个连接只是传输少量的数据,例如聊天服务器,这时候NIO是有优势的,因为他的selector可以同时处理多个连接的事件。





## buffer

buffer是一个容器对象,用来承装数据的数组.也可以称之为缓冲区.

NIO中封住装了7个基本类型的数组

buffer接口中又有两个关键的方法:capacity、flip

- capacity: 当前组表位置
- ​