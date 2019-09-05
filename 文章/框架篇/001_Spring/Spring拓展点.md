# Spring相关的拓展点

## BeanDefinition

### BeanDefinitionParser

BeanDefinitionParser是BeanDefinition解析器，它是Spring提供为扩展解析XML配置的Bean而设计。它不仅能够解析XML向上下文中注册更多BeanDefiniion，同时还支持自定义XML Tag。

> 其实就是解析XML文件而生的，常用的框架有Mybatis的自定义配置解析参考:MapperScannerBeanDefinitionParser。

### BeanDefinitionRegistryPostProcessor

当BeanDefinition全部注册后执行的处理器，它本身是BeanFactoryPostProcessor的扩展，允许在BeanFactoryPostProcessor处理前向上下文中注册更多的BeanDefinition。

> Mybatis的mapper注册就是在这个阶段，参考`MapperScannerConfigurer`。
>
> 利用ClassPathMapperScanner进行包扫描，扫描之后，重组Beandifination然后注册。

**触发时机:**

- bstractApplicationContext - refresh() 
  - invokeBeanFactoryPostProcessors();
    - PostProcessorRegistrationDelegate.invokeBeanFactoryPostProcessors()

### ImportBeanDefinitionRegistrar



和上面BeanDefinitionRegistryPostProcessor类似，不过根据它的注释表述：

BeanDefinitionRegistryPostProcessor更适合xml解析的方式

ImportBeanDefinitionRegistrar: 更适合java注解式解析

> 在Mybatis中通过@MapperScan扫描的处理类。也是重组Beandifination，指定代理工厂。
>
> 在Feign中也是如此，参考FeignClientsRegistrar。实现方式和Mybatis类似，重组自己的类结构成Beandefintion。

**处理时机**:

bstractApplicationContext - refresh() 

- invokeBeanFactoryPostProcessors();
  - PostProcessorRegistrationDelegate.invokeBeanFactoryPostProcessors()
  - ....
  - ConfigurationClassParser.processImports (扫描每个bean的元数据的时候，判断是否有@Import注解）

## Bean

## BeanPostProcessor

- postProcessBeforeInitialization : bean在实例化之前被触发。可以理解为刚刚new完。
- postProcessAfterInitialization : bean在实例化之后被触发。这个时候已经赋值完成了,初始化方法已经调用过了，也被代理完成了。

## InstantiationAwareBeanPostProcessor

- postProcessBeforeInstantiation :  处理正在处理class阶段的bean
- postProcessAfterInstantiation : 是否能被实例化
- postProcessPropertyValues : 属性注入阶段

## SmartInstantiationAwareBeanPostProcessor

- predictBeanType : 确定bean的类型
- determineCandidateConstructors : 确定构造函数
- getEarlyBeanReference : 获取bean的引用，为了解决循环依赖，所以提前缓存bean的引用。

## MergedBeanDefinitionPostProcessor

- postProcessMergedBeanDefinition: 合并类