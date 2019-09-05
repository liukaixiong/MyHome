# 注册中心

nameServer一直被用来当作RocketMQ的注册中心，Broker、producer、consumer都会将自己的心跳情况发送到NameServer来进行通信，一旦宕机将会从注册中心进行摘除，方便协调双方之间的有效性。

## NamesrvStartup

NameServer的启动类，里面有一个Main方法可以直接在IDEA中进行启动。

但启动的时候会报一个异常:`Please set the ROCKETMQ_HOME variable in your environment to match the location of the RocketMQ installation。`

这个是需要你自己设置环境变量，如果windows环境不想从环境变量中设置，那么可以通过



```java
public static void main(String[] args) {
    // 手动设置
    System.setProperty(MixAll.ROCKETMQ_HOME_PROPERTY, "D:\\idea_work\\github_project\\rocketmq\\distribution");
    main0(args);
    }
```

来进行启动。

启动成功会提示:

**The Name Server boot success. serializeType=JSON**

### main

```java
public static NamesrvController main0(String[] args) {
    try {
        // 构建对象，并且根据命令参数为其赋值。
        NamesrvController controller = createNamesrvController(args);
        // 根据上面的赋值方法,进行初始化之后,调用satrt方法进行启动.
        start(controller);
        String tip = "The Name Server boot success. serializeType=" + RemotingCommand.getSerializeTypeConfigInThisServer();
        log.info(tip);
        System.out.printf("%s%n", tip);
        return controller;
    } catch (Throwable e) {
        e.printStackTrace();
        System.exit(-1);
    }
    return null;
    }
```

上述流程步骤:

- 创建一个`NamesrvController`对象
- 启动`NamesrvController`的start方法来完成初始化。

我们这时候需要关注`NamesrvController`到底是个什么对象?结构如何?起到怎么样的作用。

#### NamesrvController

##### 属性介绍

```java
// 注册中心的配置文件对象，包含里面需要存储到的RMQ环境地址,数据配置KV地址
// [rocketmqHome、kvConfigPath、configStorePath]
private final NamesrvConfig namesrvConfig;
// Netty服务配置对象 主要是给下面的remotingServer使用的
private final NettyServerConfig nettyServerConfig;
// 调度线程，负责定时轮训查看数据是否有效。查看broker是否存活
private final ScheduledExecutorService scheduledExecutorService = Executors.newSingleThreadScheduledExecutor(new ThreadFactoryImpl(
    "NSScheduledThread"));
// 具体的配置文件管理对象，数据承载者 [kvConfigPath中读取的配置文件解析对象]
private final KVConfigManager kvConfigManager;
// 路由注册数据承装载体[topic、brokerName、brokerAddr、clusterName]
private final RouteInfoManager routeInfoManager;
// 远程通信服务
private RemotingServer remotingServer;
// broker管理业务类，对Broker各个事件进行监听回调个体RouteInfoManager
private BrokerHousekeepingService brokerHousekeepingService;
// 远程轮训线程执行器
private ExecutorService remotingExecutor;

// 文件配置对象
private Configuration configuration;

// 文件监听服务，随时监听文件的变化
private FileWatchService fileWatchService;
```

以上属性总结:

- 注册中心的属性配置对象
  - 包括rocketmqHome、kvConfigPath、configStorePath
- Netty服务的配置对象
  - 负责接收由客户端发过来的心跳信息
  - 并且负责处理请求发送的命令
- 调度线程池
  - 查看Broker是否存活，并更新到路由数据管理对象中
  - 查看配置文件KV管理是否发生变化
- 路由数据管理对象
  - 专门用于存储BrokerName、topic、brokerAddr等等

##### 方法介绍

**initialize**

初始化方法

```java
public boolean initialize() {
	// 加载本地配置文件，其实也就是相当于初始化KVConfigManager的属性
    this.kvConfigManager.load();
	// 构建一个Netty服务
    this.remotingServer = new NettyRemotingServer(this.nettyServerConfig, this.brokerHousekeepingService);

    this.remotingExecutor =
        Executors.newFixedThreadPool(nettyServerConfig.getServerWorkerThreads(), new ThreadFactoryImpl("RemotingExecutorThread_"));

    this.registerProcessor();

    this.scheduledExecutorService.scheduleAtFixedRate(new Runnable() {

        @Override
        public void run() {
            NamesrvController.this.routeInfoManager.scanNotActiveBroker();
        }
    }, 5, 10, TimeUnit.SECONDS);

    this.scheduledExecutorService.scheduleAtFixedRate(new Runnable() {

        @Override
        public void run() {
            NamesrvController.this.kvConfigManager.printAllPeriodically();
        }
    }, 1, 10, TimeUnit.MINUTES);

    if (TlsSystemConfig.tlsMode != TlsMode.DISABLED) {
        // Register a listener to reload SslContext
        try {
            fileWatchService = new FileWatchService(
                new String[] {
                    TlsSystemConfig.tlsServerCertPath,
                    TlsSystemConfig.tlsServerKeyPath,
                    TlsSystemConfig.tlsServerTrustCertPath
                },
                new FileWatchService.Listener() {
                    boolean certChanged, keyChanged = false;
                    @Override
                    public void onChanged(String path) {
                        if (path.equals(TlsSystemConfig.tlsServerTrustCertPath)) {
                            log.info("The trust certificate changed, reload the ssl context");
                            reloadServerSslContext();
                        }
                        if (path.equals(TlsSystemConfig.tlsServerCertPath)) {
                            certChanged = true;
                        }
                        if (path.equals(TlsSystemConfig.tlsServerKeyPath)) {
                            keyChanged = true;
                        }
                        if (certChanged && keyChanged) {
                            log.info("The certificate and private key changed, reload the ssl context");
                            certChanged = keyChanged = false;
                            reloadServerSslContext();
                        }
                    }
                    private void reloadServerSslContext() {
                        ((NettyRemotingServer) remotingServer).loadSslContext();
                    }
                });
        } catch (Exception e) {
            log.warn("FileWatchService created error, can't load the certificate dynamically");
        }
    }

    return true;
}
```



**registerProcessor**

**start**