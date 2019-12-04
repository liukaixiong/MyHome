# Selector

## 创建

```java
// 1
Selector selector = Selector.open();
// 2
public static Selector open() throws IOException {
    return SelectorProvider.provider().openSelector();
}

// 3 
public static SelectorProvider provider() {
    synchronized (lock) {
        // 首先判断provider是否已经产生
        if (provider != null)
            return provider;
        return AccessController.doPrivileged(
            new PrivilegedAction<SelectorProvider>() {
                public SelectorProvider run() {
                    if (loadProviderFromProperty())
                        return provider;
                    if (loadProviderAsService())
                        return provider;
                    provider = sun.nio.ch.DefaultSelectorProvider.create();
                    return provider;
                }
            });
    }
}

// loadProviderFromProperty  根据系统属性，使用Classoader类加载；
 private static boolean loadProviderFromProperty() {
     String cn = System.getProperty("java.nio.channels.spi.SelectorProvider");
     if (cn == null)
         return false;
     Class<?> c = Class.forName(cn, true,
                                ClassLoader.getSystemClassLoader());
     provider = (SelectorProvider)c.newInstance();
     return true;
 }

// loadProviderAsService 通过SPI的方式加载
private static boolean loadProviderAsService() {
    ServiceLoader<SelectorProvider> sl =
        ServiceLoader.load(SelectorProvider.class,
                           ClassLoader.getSystemClassLoader());
    Iterator<SelectorProvider> i = sl.iterator();
    for (;;) {
        try {
            if (!i.hasNext())
                return false;
            provider = i.next();
            return true;
        } catch (ServiceConfigurationError sce) {
            if (sce.getCause() instanceof SecurityException) {
                // Ignore the security exception, try the next provider
                continue;
            }
            throw sce;
        }
    }
}
```

**loadProviderFromProperty**

根据系统属性，使用Classoader类加载；

系统参数为: `java.nio.channels.spi.SelectorProvider`

**loadProviderAsService**

通过SPI的方式加载， 该方法调用ServiceLoader的load加载在"META-INF/services/"路径下指明的SelectorProvider.class的实现类（其实是懒加载，在迭代时才真正加载）得到ServiceLoader对象，通过该对象的带迭代器，遍历这个迭代器；可以看到若是迭代器不为空，则直接返回迭代器保存的第一个元素，即第一个被加载的类的对象，并赋值给provider，返回true；否则返回false； 

**sun.nio.ch.DefaultSelectorProvider.create()**

默认采用的是**WindowsSelectorProvider**方式，最终的实现是**WindowsSelectorImpl**方法

