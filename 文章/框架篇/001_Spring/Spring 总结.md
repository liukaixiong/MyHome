## 注解区分

 1. @Service用于标注业务层组件
 2. @Controller用于标注控制层组件（如struts中的action）
 3. @Repository用于标注数据访问组件，即DAO组件
 4. @Component泛指组件，当组件不好归类的时候，我们可以使用这个注解进行标注。
 5. @PreDestroy	表示初始化方法
 6. @PreDestroy	表示销毁方法
 7. @Qualifier 当一个接口有多个实现类的时候,可以用该方法进行指定
 8. @Scope 作用域 scope="prototype" 表示非单例模式,如果有并发情况,可以建议使用

## 2.配置文件重复加载bean
1. springmvc层最好扫描包的时候指定好controller层
2. spring扫描包的时候可以指定Service、Repository、Component，因为一旦spring容器初始化的时候，需要加载到Repository、Component注解标记的类的时候，会重新加载进来，然后springmvc如果指定扫描的也是这两种注解的话，可能造成重复实例化



## ListableBeanFactory 
- 可列表化的bean工厂

## HierarchicalBeanFactory
- 层级化的bean工厂 - 

## AutowreCapableBeanFactory
- 隐士加载的类 ， 注入

## BeanDefinition
- bean对象的描述




## Spring 默认注册对象
- AnnotationAwareOrderComparator
- ConfigurationClassPostProcessor 
    - [org.springframework.context.annotation.internalConfigurationAnnotationProcessor]
- AutowiredAnnotationBeanPostProcessor
    - [org.springframework.context.annotation.internalAutowiredAnnotationProcessor]
- RequiredAnnotationBeanPostProcessor
    - [org.springframework.context.annotation.internalRequiredAnnotationProcessor]
- AnnotationAwareAspectJAutoProxyCreator
    - org.springframework.aop.config.internalAutoProxyCreator
- TransactionInterceptor
    - 阿萨德
- BeanFactoryTransactionAttributeSourceAdvisor


0. 九大内置对象
2.  {ApplicationContextAwareProcessor@2952} 
1. {PostProcessorRegistrationDelegate$BeanPostProcessorChecker@1. } 
1. {ConfigurationClassPostProcessor$ImportAwareBeanPostProcesso1. 94} 
1. {ConfigurationClassPostProcessor$EnhancedConfigurationBeanPo1. ocessor@2678} 
1. {AnnotationAwareAspectJAutoProxyCreator@2036} 1. xyTargetClass=true; optimize=false; opaque=false; 1. seProxy=false; frozen=false"
1. {CommonAnnotationBeanPostProcessor@2676} 
1. {AutowiredAnnotationBeanPostProcessor@2689} 
1. {RequiredAnnotationBeanPostProcessor@2686} 
1. {PostProcessorRegistrationDelegate$ApplicationListenerDetector@2954} 

#### 切入点解析
工厂类 : ConfigBeanDefinitionParser



### mybatis工厂
org.mybatis.spring.mapper.MapperScannerConfigurer#0 实现了自己的工厂



### Cglib 
1. cglib无法代理用final修饰的方法
2. 

## 构建一个IOC容器
实现思路：
1. 定位
    - 获得需要加载的配置文件信息位置
2. 加载
    - 将定位到的配置文件进行解析到内存中
3. 注册
    - 获取配置信息中需要扫描的包类型
    - 并且将符合的类加载到缓存中去
4. 初始化
    - 将上面的注册的类进行初始化
5. 注入
    - 将类中的属性进行赋值

**小提示： AOP的实现是在注入这个过程完成完成之后，才对这个类进行代理的。**

**IOC在初始化的时候，Spring默认的支持类会被初始化，这9个类都默认实现了BeanPostProcessor，也就是说，只要实现了这个类，在你类在放入IOC容器中，开始和结束的方法都会被调用**

[张开涛的总结，非常棒](http://jinnianshilongnian.iteye.com/blog/1492424)



```
// 对实现了ApplicationContextAware接口的类进行判断,如果符合则传递上下文给它
-------------------------------------------------------
// 容器启动时会自动注册。注入那些实现
// [EnvironmentAware || EmbeddedValueResolverAware ||ResourceLoaderAware || ApplicationEventPublisherAware || MessageSourceAware || ApplicationContextAware]
-------------------------------------------------------
0 = {ApplicationContextAwareProcessor@3013}   


1 = {PostProcessorRegistrationDelegate$BeanPostProcessorChecker@3021}   




// 是否实现了ImportAware接口，如果实现了，则调用setImportMetadata方法注入AnnotationMetadata对象
2 = {ConfigurationClassPostProcessor$ImportAwareBeanPostProcessor@3035}   
// 是否实现了EnhancedConfiguration接口,如果实现了则调用setBeanFactory方法
3 = {ConfigurationClassPostProcessor$EnhancedConfigurationBeanPostProcessor@3036}   
// 对切面@Aspect进行处理 .. AOP关键
/**
何时注册 ？ 当使用<aop:config>配置时自动注册AspectJAwareAdvisorAutoProxyCreator，而使用<aop:aspectj-autoproxy>时会自动注册AnnotationAwareAspectJAutoProxyCreator。  
*/
4 = {AnnotationAwareAspectJAutoProxyCreator@3037} "proxyTargetClass=true; optimize=false; opaque=false;   exposeProxy=false; frozen=false"  ----》 aop AbstractAutoProxyCreator
// 执行@Resource、@PostConstruct、@PreDestroy等注解的注入
5 = {CommonAnnotationBeanPostProcessor@3038}  
--------------------------------------------------------
CommonAnnotationBeanPostProcessor继承InitDestroyAnnotationBeanPostProcessor，当在配置文件有<context:annotation-config>或<context:component-scan>会自动注册。
 
提供对JSR-250规范注解的支持@javax.annotation.Resource、@javax.annotation.PostConstruct和@javax.annotation.PreDestroy等的支持。
5.1 、通过@Resource注解进行依赖注入：
    postProcessPropertyValues：通过此回调进行@Resource注解的依赖注入；（9.3处实施；
5.2 、用于执行@PostConstruct 和@PreDestroy 注解的初始化和销毁方法的扩展点：
    postProcessBeforeInitialization()将会调用bean的@PostConstruct方法；（10.2处实施；
    postProcessBeforeDestruction()将会调用单例 Bean的@PreDestroy方法（此回调方法会在容器销毁时调用），
-----------------------------------------------------------
/**
作用: 执行@Autowired注解注入
何时被注册 :  当在配置文件有<context:annotation-config>或<context:component-scan>会自动注册。
做了哪些处理 :  
    1. determineCandidateConstructors -> @Autowired和@Value ：决定候选构造器 
    postProcessPropertyValues ：进行依赖注入
*/
  
6 = {AutowiredAnnotationBeanPostProcessor@3039}   
// 执行@Required注解注入  postProcessPropertyValues：如果检测到没有进行依赖注入时抛出BeanInitializationException异常；
7 = {RequiredAnnotationBeanPostProcessor@3040}     
8 = {PostProcessorRegistrationDelegate$ApplicationListenerDetector@3041} 

9 = SmartInstantiationAwareBeanPostProcessor：智能实例化Bean后置处理器（继承InstantiationAwareBeanPostProcessor）

predictBeanType：预测Bean的类型，返回第一个预测成功的Class类型，如果不能预测返回null；当你调用BeanFactory.getType(name)时当通过Bean定义无法得到Bean类型信息时就调用该回调方法来决定类型信息；BeanFactory.isTypeMatch(name, targetType)用于检测给定名字的Bean是否匹配目标类型（如在依赖注入时需要使用）；

determineCandidateConstructors：检测Bean的构造器，可以检测出多个候选构造器，再有相应的策略决定使用哪一个，如AutowiredAnnotationBeanPostProcessor实现将自动扫描通过@Autowired/@Value注解的构造器从而可以完成构造器注入， 

getEarlyBeanReference：当正在创建A时，A依赖B，此时通过（8将A作为ObjectFactory放入单例工厂中进行early expose，此处B需要引用A，但A正在创建，从单例工厂拿到ObjectFactory（其通过getEarlyBeanReference获取及早暴露Bean），从而允许循环依赖，此时AspectJAwareAdvisorAutoProxyCreator（完成xml风格的AOP配置(<aop:config>)将目标对象（A）包装到AOP代理对象）或AnnotationAwareAspectJAutoProxyCreator（完成@Aspectj注解风格（<aop:aspectj-autoproxy> @Aspect）将目标对象（A）包装到AOP代理对象），其返回值将替代原始的Bean对象，即此时通过early reference能得到正确的代理对象，（8.1处实施；如果此处执行了，（10.3.3处的AspectJAwareAdvisorAutoProxyCreator或AnnotationAwareAspectJAutoProxyCreator的postProcessAfterInitialization将不执行，即这两个回调方法是二选一的；
```


### Spring是如何处理循环依赖的现象的?
#### 模拟场景:
```

// 这两个service都是经过代理的,Spring的运行流程:
/**
1. 先实例化,拿到实例对象
2. 通过实例对象进行反射,为对象的属性进行赋值注入
3. 然后在根据一些方法上的判断,比如@Transaction,来确定这个类是否要被代理

------------------------------------------

这时候按照下面的流程:
1. 实例化IAservice
2. 为serviceB属性赋值
    2.1. IBService初始化
    2.2. 为serviceA,属性赋值,这时候其实A是还没有被代理成功的,也没用拿到代理对象的


*/
IAservice {
    IBService serviceB;
}

IBservice {
    IAService serviceA;
}
```

关键类: DefaultSingletonBeanRegistry - getSingleton

earlyProxyReferences会承装这个代理类,下次调用AbstractAutoProxyCreator.postProcessAfterInitialization准备进行代理的时候,会先判断代理类是否已经生成了.如果已经生成了,则返回该实例去替换掉对应的bean

创建bean的过程:  
AbstractAutowireCapableBeanFactory.class
```
 protected Object doCreateBean(final String beanName, final RootBeanDefinition mbd, Object[] args) {
        BeanWrapper instanceWrapper = null;
        if (mbd.isSingleton()) {
            instanceWrapper = (BeanWrapper)this.factoryBeanInstanceCache.remove(beanName);
        }
        // 1. 先创建实例化对象
        if (instanceWrapper == null) {
            instanceWrapper = this.createBeanInstance(beanName, mbd, args);
        }

        final Object bean = instanceWrapper != null ? instanceWrapper.getWrappedInstance() : null;
        Class<?> beanType = instanceWrapper != null ? instanceWrapper.getWrappedClass() : null;
        Object var7 = mbd.postProcessingLock;
        synchronized(mbd.postProcessingLock) {
            if (!mbd.postProcessed) {
                // 调用IOC中实现了MergedBeanDefinitionPostProcessor接口的postProcessMergedBeanDefinition方法
                this.applyMergedBeanDefinitionPostProcessors(mbd, beanType, beanName);
                mbd.postProcessed = true;
            }
        }

// -------------------------先添加一个单例工厂-----------------------
        boolean earlySingletonExposure = mbd.isSingleton() && this.allowCircularReferences && this.isSingletonCurrentlyInCreation(beanName);
        if (earlySingletonExposure) {
            if (this.logger.isDebugEnabled()) {
                this.logger.debug("Eagerly caching bean '" + beanName + "' to allow for resolving potential circular references");
            }
            // addSingletonFactory这里是具体放入的方法
            // 这里会先把这个类先放入到这个对象工厂中
            this.addSingletonFactory(beanName, new ObjectFactory<Object>() {
                public Object getObject() throws BeansException {
                    // 这里方法实现的目的的出现循环调用的时候会被回调
                    return AbstractAutowireCapableBeanFactory.this.getEarlyBeanReference(beanName, mbd, bean);
                }
            });
        }

        Object exposedObject = bean;
// --------------------------为类的属性进行注入--------------------------
        try {
            this.populateBean(beanName, mbd, instanceWrapper);
// ------------------------为类的前后处理包括init方法做处理处理(代理)----
            if (exposedObject != null) {
                exposedObject = this.initializeBean(beanName, exposedObject, mbd);
            }
        } catch (Throwable var17) {
            if (var17 instanceof BeanCreationException && beanName.equals(((BeanCreationException)var17).getBeanName())) {
                throw (BeanCreationException)var17;
            }

            throw new BeanCreationException(mbd.getResourceDescription(), beanName, "Initialization of bean failed", var17);
        }
// ---------这里是为了如果单例工厂中已经完整存在对象---------
// 主要就是为了上面添加单例工厂做准备
        if (earlySingletonExposure) {
            Object earlySingletonReference = this.getSingleton(beanName, false);
            if (earlySingletonReference != null) {
                if (exposedObject == bean) {
                    exposedObject = earlySingletonReference;
                } else if (!this.allowRawInjectionDespiteWrapping && this.hasDependentBean(beanName)) {
                    String[] dependentBeans = this.getDependentBeans(beanName);
                    Set<String> actualDependentBeans = new LinkedHashSet(dependentBeans.length);
                    String[] var12 = dependentBeans;
                    int var13 = dependentBeans.length;

                    for(int var14 = 0; var14 < var13; ++var14) {
                        String dependentBean = var12[var14];
                        if (!this.removeSingletonIfCreatedForTypeCheckOnly(dependentBean)) {
                            actualDependentBeans.add(dependentBean);
                        }
                    }

                    if (!actualDependentBeans.isEmpty()) {
                        throw new BeanCurrentlyInCreationException(beanName, "Bean with name '" + beanName + "' has been injected into other beans [" + StringUtils.collectionToCommaDelimitedString(actualDependentBeans) + "] in its raw version as part of a circular reference, but has eventually been " + "wrapped. This means that said other beans do not use the final version of the " + "bean. This is often the result of over-eager type matching - consider using " + "'getBeanNamesOfType' with the 'allowEagerInit' flag turned off, for example.");
                    }
                }
            }
        }

        try {
            this.registerDisposableBeanIfNecessary(beanName, bean, mbd);
            return exposedObject;
        } catch (BeanDefinitionValidationException var16) {
            throw new BeanCreationException(mbd.getResourceDescription(), beanName, "Invalid destruction signature", var16);
        }
    }
```

AbstractAutoProxyCreator  
- getEarlyBeanReference：当正在创建A时，A依赖B，此时通过（8将A作为ObjectFactory放入单例工厂中进行early expose，此处B需要引用A，但A正在创建，从单例工厂拿到ObjectFactory（其通过getEarlyBeanReference获取及早暴露Bean），从而允许循环依赖，此时AspectJAwareAdvisorAutoProxyCreator（完成xml风格的AOP配置(<aop:config>)将目标对象（A）包装到AOP代理对象）或AnnotationAwareAspectJAutoProxyCreator（完成@Aspectj注解风格（<aop:aspectj-autoproxy> @Aspect）将目标对象（A）包装到AOP代理对象），其返回值将替代原始的Bean对象，即此时通过early reference能得到正确的代理对象，

实际调用思路:
1. 创建实例化A的时候会先拿到一个实例
2. 将A的BeanDefinition对象和名称放入一个单例工厂
3. 为A的B属性进行注入,开始上面过程
4. 为B的属性进行注入,这时候如果还依赖A,则会触发第二步的的工厂回调,会优先对A进行包装处理(代理),并且缓存这个代理对象到代理工厂中并且返回一个代理对象,B通过反射将拿到的A代理对象属性初始化
5. A的B属性注入完成,开始进行beanPostProcess的前后处理,经过代理bean的时候,会去查找工厂中是否已经存在了这个 bean,如果存在,则不会进行代理,直接返回

**补充** 

**三级缓存**

`DefaultSingletonBeanRegistry`

当前实例对象的属性对象标记  singletonsCurrentlyInCreation
- singletonFactories : 当前正在初始化的工厂对象
- earlySingletonObjects : 存在依赖的单例对象,提前依赖的缓存对象
- singletonObjects : 所有已经初始化的单例对象


1. 在创建A的同时，会先将该类放入一个Set集合当中。  
方法轨迹： 
- AbstractBeanFactory.java -> doGetBean -> getSingleton
- DefaultSingletonBeanRegistry -> getSingleton -> beforeSingletonCreation(beanName) -> 属性 singletonsCurrentlyInCreation

至此A的创建流程上下文中就拥有一个`singletonsCurrentlyInCreation`集合来保存当前初始化对象的登记


2. 在创建bean的同时，会事先调用getSingle方法，判断是否存在循环依赖，如果拿到了表示有依赖。
```java


protected <T> T doGetBean(
			final String name, final Class<T> requiredType, final Object[] args, boolean typeCheckOnly)
			throws BeansException {

		final String beanName = transformedBeanName(name);
		Object bean;
        // 这个方法会检查是否包含循环依赖
		// Eagerly check singleton cache for manually registered singletons.
		Object sharedInstance = getSingleton(beanName);
		if (sharedInstance != null && args == null) {
			if (logger.isDebugEnabled()) {
				if (isSingletonCurrentlyInCreation(beanName)) {
					logger.debug("Returning eagerly cached instance of singleton bean '" + beanName +
							"' that is not fully initialized yet - a consequence of a circular reference");
				}
				else {
					logger.debug("Returning cached instance of singleton bean '" + beanName + "'");
				}
			}
			bean = getObjectForBeanInstance(sharedInstance, name, beanName, null);
		}else{
            // 如果上面没有依赖才会执行这个
    		// Create bean instance.
    		if (mbd.isSingleton()) {
    			sharedInstance = getSingleton(beanName, new ObjectFactory<Object>() {
    				@Override
    				public Object getObject() throws BeansException {
    					try {
    						return createBean(beanName, mbd, args);
    					}
    					catch (BeansException ex) {
    						// Explicitly remove instance from singleton cache: It might have been put there
    						// eagerly by the creation process, to allow for circular reference resolution.
    						// Also remove any beans that received a temporary reference to the bean.
    						destroySingleton(beanName);
    						throw ex;
    					}
    				}
    			});
    			bean = getObjectForBeanInstance(sharedInstance, name, beanName, mbd);
    		}
		}
		}
		return (T) bean;
	}



```
3. 有依赖直接返回
4. 返回完了之后B就拿到了A的引用
5. 注意，这时候B的属性A对象是完全没有初始化成功的,只是实例化完成了.但是B持有了A的引用，当A初始化完成了之后，B的引用A也初始化完成了

下面是获取单例的时机 : 

DefaultSingletonBeanRegistry:
```java
protected Object getSingleton(String beanName, boolean allowEarlyReference) {
    // 先从已经完成的单例对象中获取
	Object singletonObject = this.singletonObjects.get(beanName);
	if (singletonObject == null &&
	    // 这里开始判断当前正在初始化的对象是否包含循环依赖，也就是上面说的登记
	    isSingletonCurrentlyInCreation(beanName)) {
	    // 存在依赖
		synchronized (this.singletonObjects) {
		    // 查看提前依赖的缓存中是否存在
			singletonObject = this.earlySingletonObjects.get(beanName);
			if (singletonObject == null && allowEarlyReference) {
			    // 从当前实例对象的工厂中获取对象做提前初始化
				ObjectFactory<?> singletonFactory = this.singletonFactories.get(beanName);
				if (singletonFactory != null) {
				    // 开启提前实例化 也就是addSingletonFactory方法中的
					singletonObject = singletonFactory.getObject();
					this.earlySingletonObjects.put(beanName, singletonObject);
					this.singletonFactories.remove(beanName);
				}
			}
		}
	}
	return (singletonObject != NULL_OBJECT ? singletonObject : null);
}
```




疑问: 代理A类在包装的时候,是没有得到B的属性的,没被代理的A是得到了B的属性的,代理A是如何知道B的属性的?
- 在第二步的时候,实际上单例工厂传递的就是未被代理A对象的引用,所以只要A的实例获取到了B的属性,那么代理A也就获取到了A的实例,因为代理A的实例就是引用的A
```
AbstractAutowireCapableBeanFactory

this.addSingletonFactory(beanName, new ObjectFactory<Object>() {
    // singletonFactory.getObject();触发
    public Object getObject() throws BeansException {
        // 这里方法实现的目的的出现循环调用的时候会被回调,
        // 注意这里传递的参数是对象的引用
        return AbstractAutowireCapableBeanFactory.this.getEarlyBeanReference(beanName, mbd, bean);
    }
});

 if (earlySingletonExposure) {
    // 获取单例对象的时候,直接从单例工厂里面获取
    Object earlySingletonReference = this.getSingleton(beanName, false);
    // 如果获取到了
    if (earlySingletonReference != null) {
        // 判断他们的引用是否是同一个对象
        if (exposedObject == bean) {
            // 如果一样则替换,也就是解答了上面的[疑问]
            exposedObject = earlySingletonReference;
        } 
    }
}
// 
    
AbstractAutoProxyCreator.java

// 这里会先将这个对象进行缓存,下次就不用再包装了,直接返回
public Object getEarlyBeanReference(Object bean, String beanName) throws     BeansException {
        Object cacheKey = this.getCacheKey(bean.getClass(), beanName);
        if (!this.earlyProxyReferences.contains(cacheKey)) {
        // 这里会先将这个对象进行缓存,下次就不用再包装了,直接返回,和下面的postProcessAfterInitialization方法进行配套
            this.earlyProxyReferences.add(cacheKey);
        }

        return this.wrapIfNecessary(bean, beanName, cacheKey);
    }
    

// 具体包装的对象
protected Object wrapIfNecessary(Object bean, String beanName, Object cacheKey) {
        // 如果存在则返回,也就是说代理已经形成了,下次遇到该Bean的情况直接返回,不用再代理了
		if (beanName != null && this.targetSourcedBeans.contains(beanName)) {
			return bean;
		}
		if (Boolean.FALSE.equals(this.advisedBeans.get(cacheKey))) {
			return bean;
		}
	
		if (isInfrastructureClass(bean.getClass()) || shouldSkip(bean.getClass(), beanName)) {
			this.advisedBeans.put(cacheKey, Boolean.FALSE);
			return bean;
		}
        // 创建代理的过程
		// Create proxy if we have advice.
		Object[] specificInterceptors = getAdvicesAndAdvisorsForBean(bean.getClass(), beanName, null);
		if (specificInterceptors != DO_NOT_PROXY) {
			this.advisedBeans.put(cacheKey, Boolean.TRUE);
			Object proxy = createProxy(bean.getClass(), beanName, specificInterceptors, new SingletonTargetSource(bean));
			this.proxyTypes.put(cacheKey, proxy.getClass());
			return proxy;
		}

		this.advisedBeans.put(cacheKey, Boolean.FALSE);
		return bean;
	}
```
## Spring的生命周期
> 对应的代码 AbstractBeanFactory - doGetBean 方法
> AbstractAutowireCapableBeanFactory doCreateBean

1. 实例化一个Bean，也就是我们通常说的new
```
	instanceWrapper = createBeanInstance(beanName, mbd, args);
```


2. 按照Spring上下文对实例化的Bean进行配置，也就是IOC注入
```
    // 注入属性
    populateBean(beanName, mbd, instanceWrapper);
    
    // AutowiredAnnotationBeanPostProcessor实际注入的类
    for (BeanPostProcessor bp : getBeanPostProcessors()) {
		if (bp instanceof InstantiationAwareBeanPostProcessor) {
			InstantiationAwareBeanPostProcessor ibp = (InstantiationAwareBeanPostProcessor) bp;
			pvs = ibp.postProcessPropertyValues(pvs, filteredPds, bw.getWrappedInstance(), beanName);
			if (pvs == null) {
				return;
			}
		}
	}
    
```

3. 如果这个Bean实现了BeanNameAware接口，会调用它实现的setBeanName(String beanId)方法，此处传递的是Spring配置文件中Bean的ID
```
    initializeBean -> invokeAwareMethods
    private void invokeAwareMethods(final String beanName, final Object bean) {
		if (bean instanceof Aware) {
			if (bean instanceof BeanNameAware) {
				((BeanNameAware) bean).setBeanName(beanName);
			}
			if (bean instanceof BeanClassLoaderAware) {
				((BeanClassLoaderAware) bean).setBeanClassLoader(getBeanClassLoader());
			}
			if (bean instanceof BeanFactoryAware) {
				((BeanFactoryAware) bean).setBeanFactory(AbstractAutowireCapableBeanFactory.this);
			}
		}
	}
```
4. 如果这个Bean实现了BeanFactoryAware接口，会调用它实现的setBeanFactory()，传递的是Spring工厂本身（可以用这个方法获取到其他Bean）

5. 如果这个Bean实现了ApplicationContextAware接口，会调用setApplicationContext(ApplicationContext)方法，传入Spring上下文，该方式同样可以实现步骤4，但比4更好，以为ApplicationContext是BeanFactory的子接口，有更多的实现方法

```
    1. initializeBean  
    2. applyBeanPostProcessorsBeforeInitialization
    3. ApplicationContextAwareProcess - postProcessBeforeInitialization
    3. invokeAwareInterfaces
    private void invokeAwareInterfaces(Object bean) {
		if (bean instanceof Aware) {
			if (bean instanceof ApplicationContextAware) {
				((ApplicationContextAware) bean).setApplicationContext(this.applicationContext);
			}
		}
	}
```

6. 如果这个Bean关联了BeanPostProcessor接口，将会调用postProcessBeforeInitialization(Object obj, String s)方法，BeanPostProcessor经常被用作是Bean内容的更改，并且由于这个是在Bean初始化结束时调用After方法，也可用于内存或缓存技术
```
    1. initializeBean  
    2. applyBeanPostProcessorsBeforeInitialization
```
7. 如果这个bean实现了InitializingBean接口,则会调用afterPropertiesSet方法,,如果这个Bean在Spring配置文件中配置了init-method属性会自动调用其配置的初始化方法
```
    1. initializeBean  
    2. applyBeanPostProcessorsBeforeInitialization
    3. invokeInitMethods 
```

8. 如果这个Bean关联了BeanPostProcessor接口，将会调用postAfterInitialization(Object obj, String s)方法
```
    1. initializeBean  
    2. applyBeanPostProcessorsAfterInitialization
```


注意：以上工作完成以后就可以用这个Bean了，那这个Bean是一个single的，所以一般情况下我们调用同一个ID的Bean会是在内容地址相同的实例

9. 当Bean不再需要时，会经过清理阶段，如果Bean实现了DisposableBean接口，会调用其实现的destroy方法[默认会调CommonAnnotationBeanPostProcessor方法,去处理如果类上存在@PreDestroy注解的类]
```
1. registerDisposableBeanIfNecessary
2. filterPostProcessors
```

10. 最后，如果这个Bean的Spring配置中配置了destroy-method属性，会自动调用其配置的销毁方法
```
1. registerDisposableBeanIfNecessary
2. filterPostProcessors
```
## 总结
一共分为以下步骤:
1. 初始化这个类
2. 注入这个类的属性
3. 接口类型判断,然后为对应的接口类型执行相应的set方法:
    1. 如果实现了BeanNameAware接口,则将调用它的setBeanName方法
    2. 如果实现了BeanFactoryAware接口,则调用它的setBeanFactory方法
    3. 如果实现了ApplicationContextAware接口,则调用它的setApplication接口
4. bean的关联,该bean是否关联了BeanPostProcess相关接口的类
    1. 循环处理postProcessBeforeInitialization的方法
    2. 如果这个bean实现了InitializingBean接口,则会调用afterPropertiesSet方法,如果这个bean声明了init-method这个方法则进行调用初始化
    3. 调用处理postProcessAfterInitialization的方法
    4. 和第2步差不多,如果这个bean实现了DisposableBean接口,destroy方法,如果这个bean声明了destroy-method这个方法则进行调用初始化
> 上面的InitializingBean和DisposableBean接口都是针对注解实现的,具体实现类 : CommonAnnotationBeanPostProcessor 这个类会在你配置文件中定义<context:annotation-config>、<context:component-scan>标签的时候,被spring注册进去
