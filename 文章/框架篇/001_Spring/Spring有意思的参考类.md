# 查看Spring有意思的实现

## 1. BeanDefinitionRegistryPostProcessor

- ConfigurationClassPostProcessor

从当前项目包路径下找到Configuration对象，并构建成BeanDefinition对象

- RefreshAutoConfiguration.RefreshScopeConfiguration

刷新工厂中标记位@RefreshScope方法，进而重新开始初始化。

- ConfigurationWarningsApplicationContextInitializer.ComponentScanPackageCheck

检查带有`@ComponentScan`注解的类是否填写`value`、`basePackages`、`basePackageClasses`其中一个的值。

如果都没有则打印`logger.warn`警告日志

- ImportsCleanupPostProcessor

清空带有@Import指定的class

## 2. BeanPostProcessor

###  MetricsInterceptorConfiguration.MetricsInterceptorPostProcessor

针对RestTemplate调用加上默认Netflix的拦截器`MetricsClientHttpRequestInterceptor`，方便每次调用时做指标汇总。

其中汇总的数据包含在了`ServoMonitorCache`中。


