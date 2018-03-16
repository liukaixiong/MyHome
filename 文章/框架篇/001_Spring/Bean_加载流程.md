# Spring相关总结

### Spring的bean加载流程

1. 定位 : 获取配置文件加载的位置
2. 加载 : 解析配置文件的信息
3. 注册: 将解析的配置文件转化成BeanDefinition对象
4. 实例化 : 开始实例化bean
5. 注入: 初始化bean的属性



**Spring的Bean的生命周期**

1. 实例化一个bean,也就是new

2. 传递内置对象阶段:

   1. **BeanNameAware**:可以在此处传递Spring的beanId

   `setBeanName(String beanId)`

   2. **BeanFactoryAware**: 依次传递bean的工厂实例

   `setBeanFactory(BeanFactory beanFactory)`

   3. **ApplicationContextAware**: 可以使实现了该接口的对象持有**ApplicationContext**上下文

   `setApplicationContext(ApplicationContext applicationContext)`

3. **BeanFactoryPostProcessor**:  这个步骤会拿到`ConfigurableListableBeanFactory`这个工厂对象做处理


   `postProcessBeanFactory(ConfigurableListableBeanFactory beanFactory)`

4. **InstantiationAwareBeanPostProcessor**:会在初始化之前对bean做处理`postProcessBeforeInstantiation(Class<?> beanClass, String beanName)`

5. **InstantiationAwareBeanPostProcessor**:是否需要对bean做一些后置处理,例如代理

   `postProcessAfterInstantiation(Object bean, String beanName)`

6. 注入阶段

   1. **InstantiationAwareBeanPostProcessor**:会对bean的属性做一个传递

   `postProcessPropertyValues(PropertyValues pvs, PropertyDescriptor[] pds, Object bean, String beanName)`

7. **BeanPostProcessor**:对bean的做前置处理

   `postProcessBeforeInitialization(Object bean, String beanName)`

8. **InitializingBean**：初始化方法

   1. `xml - init-method` : 配置xml的bean的init-method方法
   2. `@PreDestroy`  : 通过注解扫描初始化该注解
   3. `afterPropertiesSet()`: 实现了**InitializingBean**接口触发的方法
   4. java-config - PreDestroy

9. **BeanPostProcessor**: 对bean做后置处理,**例如代理**

   `postProcessAfterInitialization(Object bean, String beanName)`

10. **DisposableBean**: 执行该对象的销毁方法


   `destroy`



**BeanDefinition的生命周期**

1. **BeanDefinitionRegistryPostProcessor** ： 处理beanDefinition的注册,

   `postProcessBeanDefinitionRegistry(BeanDefinitionRegistry registry)`

2. **MergedBeanDefinitionPostProcessor** : 



**关于Autowired标记重复的单个对象实例加载的顺序选择**

1. `@Qualifier`
2. `@Primary` -> 如果同类型定义了一个以上的话则会报错`NoUniqueBeanDefinitionException`
3. 字段名称 -> 你定义这个对象的时候,变量的名称

**关于Autowired标记重复的集合对象实例加载的顺序选择**

1. 根据`Ordered`接口的实现去自定义优先级加载,数值越低优先级越高



### Spring的拓展点和接口相关

***接口层面***

---



#### InstantiationAwareBeanPostProcessor

`postProcessBeforeInstantiation` 

`postProcessAfterInitialization` 

`postProcessPropertyValues` 

#### MergedBeanDefinitionPostProcessor

`postProcessMergedBeanDefinition`

#### SmartInstantiationAwareBeanPostProcessor

`predictBeanType`

`determineCandidateConstructors`

`getEarlyBeanReference`

#### BeanPostProcessor

`postProcessBeforeInitialization`

`postProcessAfterInitialization`

#### DestructionAwareBeanPostProcessor

`postProcessBeforeDestruction`



### Spring 内置的处理对象参考

![img](http://dl.iteye.com/upload/attachment/0066/9383/1590f6b2-4ba4-3d81-b103-6d20a9a04012.png)



#### ApplicationContextAwareProcessor

容器启动时会自动注册。注入那些实现

1. `ApplicationContextAware`
2. `MessageSourceAware`
3. `ResourceLoaderAware`
4. `EnvironmentAware`
5. `EmbeddedValueResolverAware`
6. `ApplicationEventPublisherAware`

标识接口的Bean需要的相应实例，会在**postProcessBeforeInitialization**完成。

#### CommonAnnotationBeanPostProcessor

**CommonAnnotationBeanPostProcessor**继承**InitDestroyAnnotationBeanPostProcessor**，当在配置文件有`<context:annotation-config>`或`<context:component-scan>`会自动注册。

支持的注解有:

1. `@javax.annotation.Resource`:触发阶段 : **postProcessPropertyValues**
2. `@javax.annotation.PostConstruct`触发阶段->**postProcessBeforeInitialization**
3. `@javax.annotation.PreDestroy`触发阶段 ->**postProcessBeforeDestruction**

#### AutowiredAnnotationBeanPostProcessor

当在配置文件有`<context:annotation-config>`或`<context:component-scan>`会自动注册。

Spring自带注解的依赖注入支持:

1. @Autowired 
   1. `determineCandidateConstructors` : 决定候选构造器；
2. @Value
   1. `postProcessPropertyValues` : 进行依赖注入

#### RequiredAnnotationBeanPostProcessor

当在配置文件有`<context:annotation-config>`或`<context:component-scan>`会自动注册。

支持的注解有:

1. @ Required
   1. `postProcessPropertyValues` : 如果检测到没有进行依赖注入时抛出BeanInitializationException异常

#### PersistenceAnnotationBeanPostProcessor

当在配置文件有`<context:annotation-config>`或`<context:component-scan>`会自动注册。

支持的注解有:

1. @javax.persistence.PersistenceUnit
2. @javax.persistence.PersistenceContext

#### AbstractAutoProxyCreator

**AspectJAwareAdvisorAutoProxyCreator**和**AnnotationAwareAspectJAutoProxyCreator**都是继承**AbstractAutoProxyCreator**，**AspectJAwareAdvisorAutoProxyCreator**提供对（`<aop:config>`）声明式AOP的支持，**AnnotationAwareAspectJAutoProxyCreator**提供对（`<aop:aspectj-autoproxy>`）注解式（@AspectJ）AOP的支持，因此只需要分析**AbstractAutoProxyCreator**即可。

当使用`<aop:config>`配置时自动注册AspectJAwareAdvisorAutoProxyCreator，而使用`<aop:aspectj-autoproxy>`时会自动注册AnnotationAwareAspectJAutoProxyCreator。







### 八、BeanPostProcessor的执行顺序

1. 如果使用BeanFactory实现，非ApplicationContext实现，BeanPostProcessor执行顺序就是添加顺序。

 

2. 如果使用的是AbstractApplicationContext（实现了ApplicationContext）的实现，则通过如下规则指定顺序。
   1. PriorityOrdered（继承了Ordered），实现了该接口的BeanPostProcessor会在第一个顺序注册，标识高优先级顺序，即比实现Ordered的具有更高的优先级；
   2. Ordered，实现了该接口的BeanPostProcessor会第二个顺序注册；

​		int HIGHEST_PRECEDENCE = Integer.MIN_VALUE;//最高优先级

​		int LOWEST_PRECEDENCE = Integer.MAX_VALUE;//最低优先级

 		**即数字越小优先级越高，数字越大优先级越低，如0（高优先级）——1000（低优先级）**

 

​	3. 无序的，没有实现Ordered/ PriorityOrdered的会在第三个顺序注册；

​	4. 内部Bean后处理器，实现了MergedBeanDefinitionPostProcessor接口的是内部Bean PostProcessor，将在最后且无序注册。

 

 

3. 接下来我们看看内置的BeanPostProcessor执行顺序

   ```java
   //1注册实现了PriorityOrdered接口的BeanPostProcessor
   //2注册实现了Ordered接口的BeanPostProcessor
   AbstractAutoProxyCreator              实现了Ordered，order = Ordered.LOWEST_PRECEDENCE
   MethodValidationPostProcessor          实现了Ordered，LOWEST_PRECEDENCE
   ScheduledAnnotationBeanPostProcessor   实现了Ordered，LOWEST_PRECEDENCE
   AsyncAnnotationBeanPostProcessor      实现了Ordered，order = Ordered.LOWEST_PRECEDENCE
   //3注册无实现任何接口的BeanPostProcessor
   BeanValidationPostProcessor            无序
   ApplicationContextAwareProcessor       无序
   ServletContextAwareProcessor          无序
   //3 注册实现了MergedBeanDefinitionPostProcessor接口的BeanPostProcessor，且按照实现了Ordered的顺序进行注册，没有实现Ordered的默认为Ordered.LOWEST_PRECEDENCE。
   PersistenceAnnotationBeanPostProcessor实现了PriorityOrdered，Ordered.LOWEST_PRECEDENCE - 4
   AutowiredAnnotationBeanPostProcessor 实现了PriorityOrdered，order = Ordered.LOWEST_PRECEDENCE-2
   RequiredAnnotationBeanPostProcessor 实现了PriorityOrdered，order = Ordered.LOWEST_PRECEDENCE - 1
   CommonAnnotationBeanPostProcessor 实现了PriorityOrdered，Ordered.LOWEST_PRECEDENCE
   ```

从上到下顺序执行，如果order相同则我们应该认为同序（谁先执行不确定，其执行顺序根据注册顺序决定）。



参考资料:

http://jinnianshilongnian.iteye.com/blog/1492424