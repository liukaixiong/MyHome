## Spring的事物是如何运作的?
> 首先带着问题看源码:
-   Spring的事物是通过哪些原理实现的?
-   Spring的事物机制是如何提交和回滚的?

> **==希望你有阅读过Spring源码的经历,不然有的东西可能理解不清楚..==**

### Spring的事物是通过哪些原理实现的?
> 首先给大家布置一个代码场景(以项目代码为例):  

spring-dataSource.xml文件
```java
     <bean id="db1" class="com.alibaba.druid.pool.DruidDataSource"     destroy-method="close">
         ....
    </bean>
    <!-- 数据源配置 -->
    <bean id="transactionManager" class="org.springframework.jdbc.datasource.DataSourceTransactionManager">
    <property name="dataSource" ref="db1"/>
    <qualifier value=""/>
</bean>

<!-- 事物管理器 -->
    <tx:annotation-driven transaction-manager="transactionManager"
    proxy-target-class="true"></tx:annotation-driven>
```
Spring-service.xml
```java
<!-- 注解扫描包 -->
 <context:component-scan base-package="com.elab.execute.services,com.elab.execute.dao,com.elab.execute.utils">
        <context:include-filter type="annotation" expression="org.springframework.stereotype.Service"/>
        <context:include-filter type="annotation" expression="org.springframework.stereotype.Repository"/>
        <context:include-filter type="annotation" expression="org.springframework.stereotype.Component"/>
        <context:exclude-filter type="annotation" expression="org.springframework.stereotype.Controller"/>
    </context:component-scan>
```


Serivce.java
```java
    //方法上只要加上@Transactional方法就行了,一个DML操作
    @Transactional
    public void testTransactional() throws Exception {
        System.out.println("=====================开始处理事物");
        TGirl girl = new TGirl();
        girl.setAge(11);
        girl.setGirl_name("hah");
        girl.setStatus(1);
        int insert = girlMapper.insert(girl);
        System.out.println("=====================结束处理事物");
        System.out.println("处理完成...");
        // 模拟程序报错
//        int i = 1 / 0;
    }
```
**==注意我们这只是模拟一个简单的事物管理配置场景,大概就是这么一些要配置的东西==**

测试类: 我没有用Junit,不过效果是差不多的
``` java
String xml[] = new String[]{"applicationContext-service.xml", "applicationContext-datasource.xml", };
        ApplicationContext app = new ClassPathXmlApplicationContext(xml);
        IDemoService demoService = (IDemoService) app.getBean("demoService");
        // DML操作
        demoService.testTransactional();
```

> 首先我们的目的是想知道Spring事物的运行流程,这时候可能就需要Debug调试,我们也就只关注事物这块初始化和执行的情况,我们可以采用**倒推**的方式  
> **先看spring事物的执行过程,再看初始化过程**


1. debug断点打在 demoService.testTransactional(); 这块,然后F5进去
  ![image](http://upload-images.jianshu.io/upload_images/6370985-7470d7262e7b3521.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
  进入到的是一个CglibAopProxy内部类**DynamicAdvisedInterceptor**的**intercept**方法,从这里看的话,其实这个类就是一个责任链类型的处理类

> 注意这一块是一个**责任链模式**,表示需要经过一系列链条之后才会到达最终的方法,**当然这三个类切入点类型的类,是通过动态代理加入到责任链中的,下面初始化的时候会讲到**
```java
      // 这一段代码表示获取到你将要执行最终方法前要经过的一系列拦截类的处理,也就是责任链类的中的核心集合
	List<Object> chain = this.advised.getInterceptorsAndDynamicInterceptionAdvice(method, targetClass);
```
![image](http://upload-images.jianshu.io/upload_images/6370985-2afc80bb6abf7b66.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

图中chain集合有三个类,表示执行到目的方法之前需要经过这几个类

我们来看到执行到目标方法的执行轨迹:  
![image](http://upload-images.jianshu.io/upload_images/6370985-e320aa216e729eef.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)  
确实是经过了三个拦截链
我们直接看事物相关的拦截链类
下面代码是不是似曾相识,这都是开启事物的操作和异常情况下,回滚和提交操作
![image](http://upload-images.jianshu.io/upload_images/6370985-13759d4bed6bddab.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)  

经过这些代理类之后到达最终的方法,这是一个大概的运行过程.异常会被事物捕获到,没有则提交... 都是通过这个TransactionAspectSupport的invokeWithinTransaction方法去做的

### 那Spring又是如何初始化这一系列的代理类操作的呢?
>   回到运行的第一步我们在那个Aop的拦截器类中(CglibApoProxy),想一想既然spring运行这个方法的时候会执行这个拦截器方法,那么初始化的时候应该也和这个类相关,然后从上面实例化的地方和可以的地方打打断点...


果然,初始化的方法断点被触发了...
![image](http://upload-images.jianshu.io/upload_images/6370985-6ff579ea38128041.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)    
这时候我们可以看断点的运行轨迹
![image](http://upload-images.jianshu.io/upload_images/6370985-9b2ca3b235415118.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240) 

我们发现,触发到这个断点的时候,会经过一系列的方法执行,这些执行的方法链都是创建bean的时候必须经过的过程,也就是说每个bean创建的时候,都会经过这一系列的链路的检查(applyBeanPostProcessorsAfterInitialization方法里面的getBeanPostProcessors()方法),才会生成最终的bean,这时候我们需要定位到执行这个CglibAopProxy初始化的方法这块,**在什么情况下**,会执行这个创建代理的类
 ![image](http://upload-images.jianshu.io/upload_images/6370985-645e4389abb11e03.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240) 

我们现在已经知道他创建了代理类的过程,现在需要知道在什么情况下会为某些bean创建代理。了解了getAdvicesAndAdvisorsForBean这个方法运行做了什么事情,就大概知道创建代理类bean的条件

> 首先我们一步步看这个方法的代码:
```java
    /**
        这是一个获取切入点和包含切入点的bean方法
    /*
    protected Object[] getAdvicesAndAdvisorsForBean(Class<?> beanClass, String beanName, TargetSource targetSource) {
        // 查询当前的bean是否包含切入点
		List<Advisor> advisors = findEligibleAdvisors(beanClass, beanName);
		if (advisors.isEmpty()) {
			return DO_NOT_PROXY;
		}
		return advisors.toArray();
	}
```
> findEligibleAdvisors方法
```java

    /**
     * 大概意思是为这个bean找到合适的自动代理类
	 * Find all eligible Advisors for auto-proxying this class.
	 * @param beanClass the clazz to find advisors for
	 * @param beanName the name of the currently proxied bean
	 * @return the empty List, not {@code null},
	 * if there are no pointcuts or interceptors
	 * @see #findCandidateAdvisors
	 * @see #sortAdvisors
	 * @see #extendAdvisors
	 */
	protected List<Advisor> findEligibleAdvisors(Class<?> beanClass, String beanName) {
        // 找到当前已经注册好的代理类bean
		List<Advisor> candidateAdvisors = findCandidateAdvisors();
        //将注册好的bean和当前bean的类型进行搜索查询,是否有合适的切入点类
		List<Advisor> eligibleAdvisors = findAdvisorsThatCanApply(candidateAdvisors, beanClass, beanName);
		extendAdvisors(eligibleAdvisors);
		if (!eligibleAdvisors.isEmpty()) {
			eligibleAdvisors = sortAdvisors(eligibleAdvisors);
		}
		return eligibleAdvisors;
	}

```

> findAdvisorsThatCanApply :

```java

       /**
       大概意思就是搜索给定的切入点集合,以用于找到可以应用到当前bean的合适的切入点集合
	 * Search the given candidate Advisors to find all Advisors that
	 * can apply to the specified bean.
	 * @param candidateAdvisors the candidate Advisors
	 * @param beanClass the target's bean class
	 * @param beanName the target's bean name
	 * @return the List of applicable Advisors
	 * @see ProxyCreationContext#getCurrentProxiedBeanName()
	 */
	protected List<Advisor> findAdvisorsThatCanApply(
			List<Advisor> candidateAdvisors, Class<?> beanClass, String beanName) {
                // 设置代理的上下文,只针当前线程
		ProxyCreationContext.setCurrentProxiedBeanName(beanName);
		try {
            // 这是一个AOP的工具类,用于
			return AopUtils.findAdvisorsThatCanApply(candidateAdvisors, beanClass);
		}
		finally {
			ProxyCreationContext.setCurrentProxiedBeanName(null);
		}
	}

```

> AopUtils.findAdvisorsThatCanApply 

```java

	/**
	 * 确定能应用到当前clazz的List<Advisor>
	 * Determine the sublist of the {@code candidateAdvisors} list
	 * that is applicable to the given class.
	 * @param candidateAdvisors the Advisors to evaluate
	 * @param clazz the target class
	 * @return sublist of Advisors that can apply to an object of the given class
	 * (may be the incoming List as-is)
	 */
	public static List<Advisor> findAdvisorsThatCanApply(List<Advisor> candidateAdvisors, Class<?> clazz) {
		if (candidateAdvisors.isEmpty()) {
			return candidateAdvisors;
		}
		List<Advisor> eligibleAdvisors = new LinkedList<Advisor>();
		for (Advisor candidate : candidateAdvisors) {
			if (candidate instanceof IntroductionAdvisor && canApply(candidate, clazz)) {
				eligibleAdvisors.add(candidate);
			}
		}
		boolean hasIntroductions = !eligibleAdvisors.isEmpty();
		for (Advisor candidate : candidateAdvisors) {
			if (candidate instanceof IntroductionAdvisor) {
				// already processed
				continue;
			}
                         // 这个方法很关键,用于判断是否能将当前Advisor应用到这个bean上
			if (canApply(candidate, clazz, hasIntroductions)) {
                // 如果验证通过,则会将当前切入点加入进来
				eligibleAdvisors.add(candidate);
			}
		}
		return eligibleAdvisors;
	}

```

> 我们来看看canApply做了些什么?
```java
// 大概就是比较了Advisor的类型
public static boolean canApply(Advisor advisor, Class<?> targetClass, boolean hasIntroductions) {
		if (advisor instanceof IntroductionAdvisor) {
			return ((IntroductionAdvisor) advisor).getClassFilter().matches(targetClass);
		}
		else if (advisor instanceof PointcutAdvisor) {
			PointcutAdvisor pca = (PointcutAdvisor) advisor;
			// 最终会执行到这个方法
			return canApply(pca.getPointcut(), targetClass, hasIntroductions);
		}
		else {
			// It doesn't have a pointcut so we assume it applies.
			return true;
		}
	}

	public static boolean canApply(Pointcut pc, Class<?> targetClass, boolean hasIntroductions) {
		Assert.notNull(pc, "Pointcut must not be null");
		if (!pc.getClassFilter().matches(targetClass)) {
			return false;
		}
                // 获取当前切入点的类型
		MethodMatcher methodMatcher = pc.getMethodMatcher();
		IntroductionAwareMethodMatcher introductionAwareMethodMatcher = null;
                //比较类型  
		if (methodMatcher instanceof IntroductionAwareMethodMatcher) {
			introductionAwareMethodMatcher = (IntroductionAwareMethodMatcher) methodMatcher;
		}
        
        
                // !!!!! 这一部分的代码很关键!!!!
                // 获取所有相关的类
		Set<Class<?>> classes = new LinkedHashSet<Class<?>>(ClassUtils.getAllInterfacesForClassAsSet(targetClass));
		classes.add(targetClass);
                // 遍历这些类
		for (Class<?> clazz : classes) {
                        // 获取类的所有方法
			Method[] methods = clazz.getMethods();
                      // 遍历这些方法
			for (Method method : methods) {
			        //methodMatcher.matches(method, targetClass) 这个方法很重要
				if ((introductionAwareMethodMatcher != null &&
						introductionAwareMethodMatcher.matches(method, targetClass, hasIntroductions)) ||
						methodMatcher.matches(method, targetClass)) {
					return true;
				}
			}
		}

		return false;
	}
```
> matches 方法
```java
     public boolean matches(Method method, Class<?> targetClass) {
		TransactionAttributeSource tas = getTransactionAttributeSource();
		// tas.getTransactionAttribute(method, targetClass)  这是个获取事物注解的方法
		return (tas == null || tas.getTransactionAttribute(method, targetClass) != null);
	}
	
	
	
	
	// 获取事务属性的方法
	public TransactionAttribute getTransactionAttribute(Method method, Class<?> targetClass) {
		// First, see if we have a cached value.
		Object cacheKey = getCacheKey(method, targetClass);
		Object cached = this.attributeCache.get(cacheKey);
		if (cached != null) {
			// Value will either be canonical value indicating there is no transaction attribute,
			// or an actual transaction attribute.
			if (cached == NULL_TRANSACTION_ATTRIBUTE) {
				return null;
			}
			else {
				return (TransactionAttribute) cached;
			}
		}
		else {
			// We need to work it out.
			// 获取事物属性的方法
			TransactionAttribute txAtt = computeTransactionAttribute(method, targetClass);
			// Put it in the cache.
			if (txAtt == null) {
				this.attributeCache.put(cacheKey, NULL_TRANSACTION_ATTRIBUTE);
			}
			else {
				if (logger.isDebugEnabled()) {
					Class<?> classToLog = (targetClass != null ? targetClass : method.getDeclaringClass());
					logger.debug("Adding transactional method '" + classToLog.getSimpleName() + "." +
							method.getName() + "' with attribute: " + txAtt);
				}
				this.attributeCache.put(cacheKey, txAtt);
			}
			return txAtt;
		}
	}
	
	private TransactionAttribute computeTransactionAttribute(Method method, Class<?> targetClass) {
		// Don't allow no-public methods as required.
		if (allowPublicMethodsOnly() && !Modifier.isPublic(method.getModifiers())) {
			return null;
		}

		// Ignore CGLIB subclasses - introspect the actual user class.
		Class<?> userClass = ClassUtils.getUserClass(targetClass);
		// The method may be on an interface, but we need attributes from the target class.
		// If the target class is null, the method will be unchanged.
		Method specificMethod = ClassUtils.getMostSpecificMethod(method, userClass);
		// If we are dealing with method with generic parameters, find the original method.
		specificMethod = BridgeMethodResolver.findBridgedMethod(specificMethod);

		// First try is the method in the target class.
		// 查找该方法的事物属性
		TransactionAttribute txAtt = findTransactionAttribute(specificMethod);
		if (txAtt != null) {
			return txAtt;
		}

		// Second try is the transaction attribute on the target class.
		txAtt = findTransactionAttribute(specificMethod.getDeclaringClass());
		if (txAtt != null) {
			return txAtt;
		}

		if (specificMethod != method) {
			// Fallback is to look at the original method.
			txAtt = findTransactionAttribute(method);
			if (txAtt != null) {
				return txAtt;
			}
			// Last fallback is the class of the original method.
			return findTransactionAttribute(method.getDeclaringClass());
		}
		return null;
	}
```
> 详细看下findTransactionAttribute方法,由于比较深我就直接贴最终执行的方法了
```java
public TransactionAttribute parseTransactionAnnotation(AnnotatedElement ae) {
        // 查看是否方法上面有@Transactional注解
		AnnotationAttributes ann = AnnotatedElementUtils.getAnnotationAttributes(ae, Transactional.class.getName());
		if (ann != null) {
			return parseTransactionAnnotation(ann);
		}
		else {
			return null;
		}
	}
	// 处理这个注解所包含的属性如传播途径和隔离级别
	protected TransactionAttribute parseTransactionAnnotation(AnnotationAttributes attributes) {
		RuleBasedTransactionAttribute rbta = new RuleBasedTransactionAttribute();
		Propagation propagation = attributes.getEnum("propagation");
		rbta.setPropagationBehavior(propagation.value());
		Isolation isolation = attributes.getEnum("isolation");
		rbta.setIsolationLevel(isolation.value());
		rbta.setTimeout(attributes.getNumber("timeout").intValue());
		rbta.setReadOnly(attributes.getBoolean("readOnly"));
		rbta.setQualifier(attributes.getString("value"));
		ArrayList<RollbackRuleAttribute> rollBackRules = new ArrayList<RollbackRuleAttribute>();
		Class<?>[] rbf = attributes.getClassArray("rollbackFor");
		for (Class<?> rbRule : rbf) {
			RollbackRuleAttribute rule = new RollbackRuleAttribute(rbRule);
			rollBackRules.add(rule);
		}
		String[] rbfc = attributes.getStringArray("rollbackForClassName");
		for (String rbRule : rbfc) {
			RollbackRuleAttribute rule = new RollbackRuleAttribute(rbRule);
			rollBackRules.add(rule);
		}
		Class<?>[] nrbf = attributes.getClassArray("noRollbackFor");
		for (Class<?> rbRule : nrbf) {
			NoRollbackRuleAttribute rule = new NoRollbackRuleAttribute(rbRule);
			rollBackRules.add(rule);
		}
		String[] nrbfc = attributes.getStringArray("noRollbackForClassName");
		for (String rbRule : nrbfc) {
			NoRollbackRuleAttribute rule = new NoRollbackRuleAttribute(rbRule);
			rollBackRules.add(rule);
		}
		rbta.getRollbackRules().addAll(rollBackRules);
		return rbta;
	}
```

> 这时候我们就可以大概的清楚知道哪些bean需要被事物代理的原因了
> 这时候我们在回过头来看spring是如何构建代理类的,这里我就不在详细各种贴流程代码了,只贴关键的

	DefaultAopProxyFactory 默认的AOP代理工厂
```java
// 创建一个AopProxy的代理类,它这里提供了两种代理方式,一种是JDK代理,一种是CGlib代理
public AopProxy createAopProxy(AdvisedSupport config) throws AopConfigException {
			if (config.isOptimize() || config.isProxyTargetClass() ||  
			hasNoUserSuppliedProxyInterfaces(config)) {
			Class<?> targetClass = config.getTargetClass();
			if (targetClass == null) {
				throw new AopConfigException("TargetSource cannot determine target class: " +
						"Either an interface or a target is required for proxy creation.");
			}
			// 如果需要代理的类是接口的时候采用JDK
			if (targetClass.isInterface()) {
				return new JdkDynamicAopProxy(config);
			}
			// 普通类用CGlib代理
			return new ObjenesisCglibAopProxy(config);
		}
		else {
			return new JdkDynamicAopProxy(config);
		}
	}
```
>  ObjenesisCglibAopProxy 的 父类是 CglibAopProxy 所以初始化ObjenesisCglibAopProxy 的构造方法时会调用super(config);

```java
	/**
	* 实例化Cglib对象时,会初始化他的父类方法,并且把拦截器传递给父类,告诉他的需要加上代理的拦截器,也就是我们的TransactionInterceptor,如果有多个的话可能就会代理多个,这里我们只看事物的
	*
	*/
	public ObjenesisCglibAopProxy(AdvisedSupport config) {
		super(config);
		this.objenesis = new ObjenesisStd(true);
	}
```
> 初始化完成之后会调用它的ObjenesisCglibAopProxy的getProxy()方法,这个方法是它的父类实现的,这里面才是真正实现了真正代理的对象,原理是构成一个责任链,将代理一个个链接起来
```java
public Object getProxy(ClassLoader classLoader) {
		if (logger.isDebugEnabled()) {
			logger.debug("Creating CGLIB proxy: target source is " + this.advised.getTargetSource());
		} 
		try {
			Class<?> rootClass = this.advised.getTargetClass();
			Assert.state(rootClass != null, "Target class must be available for creating a CGLIB proxy"); 
			Class<?> proxySuperClass = rootClass;
			if (ClassUtils.isCglibProxyClass(rootClass)) {
				proxySuperClass = rootClass.getSuperclass();
				Class<?>[] additionalInterfaces = rootClass.getInterfaces();
				for (Class<?> additionalInterface : additionalInterfaces) {
					this.advised.addInterface(additionalInterface);
				}
			} 
			// Validate the class, writing log messages as necessary.
			validateClassIfNecessary(proxySuperClass, classLoader); 
			// Configure CGLIB Enhancer...
			// 这一部分是创建一个Enhancer 对象
			Enhancer enhancer = createEnhancer();
			if (classLoader != null) {
				enhancer.setClassLoader(classLoader);
				if (classLoader instanceof SmartClassLoader &&
						((SmartClassLoader) classLoader).isClassReloadable(proxySuperClass)) {
					enhancer.setUseCache(false);
				}
			}
			enhancer.setSuperclass(proxySuperClass);
			enhancer.setInterfaces(AopProxyUtils.completeProxiedInterfaces(this.advised));
			enhancer.setNamingPolicy(SpringNamingPolicy.INSTANCE);
			enhancer.setStrategy(new UndeclaredThrowableStrategy(UndeclaredThrowableException.class));
			
			// 这部分代码非常关键,里面会创建一个DynamicAdvisedInterceptor对象,这个就是责任链的头端,所有的切入点都需要经过这个拦截器一步步执行到最终的方法
			Callback[] callbacks = getCallbacks(rootClass);
			Class<?>[] types = new Class<?>[callbacks.length];
			for (int x = 0; x < types.length; x++) {
				types[x] = callbacks[x].getClass();
			}
			// fixedInterceptorMap only populated at this point, after getCallbacks call above
			enhancer.setCallbackFilter(new ProxyCallbackFilter(
					this.advised.getConfigurationOnlyCopy(), this.fixedInterceptorMap, this.fixedInterceptorOffset));
			enhancer.setCallbackTypes(types);

			// Generate the proxy class and create a proxy instance.
			// 生成代理类并且创建实例,里面做的应该就是把DynamicAdvisedInterceptor对象和serviceImpl对象做了一个代理绑定,先进入DynamicAdvisedInterceptor,经过责任链模式一步步到达最终方法
			return createProxyClassAndInstance(enhancer, callbacks);
		}
		catch (CodeGenerationException ex) {
			throw new AopConfigException("Could not generate CGLIB subclass of class [" +
					this.advised.getTargetClass() + "]: " +
					"Common causes of this problem include using a final class or a non-visible class",
					ex);
		}
		catch (IllegalArgumentException ex) {
			throw new AopConfigException("Could not generate CGLIB subclass of class [" +
					this.advised.getTargetClass() + "]: " +
					"Common causes of this problem include using a final class or a non-visible class",
					ex);
		}
		catch (Exception ex) {
			// TargetSource.getTarget() failed
			throw new AopConfigException("Unexpected AOP exception", ex);
		}
	}

private Callback[] getCallbacks(Class<?> rootClass) throws Exception {
		// Parameters used for optimisation choices...
		boolean exposeProxy = this.advised.isExposeProxy();
		boolean isFrozen = this.advised.isFrozen();
		boolean isStatic = this.advised.getTargetSource().isStatic();

		// Choose an "aop" interceptor (used for AOP calls).
		// 创建一个拦截器对象,所有被代理的类都走这个对象,最终返回的bean执行的起始方法
		Callback aopInterceptor = new DynamicAdvisedInterceptor(this.advised);

		// Choose a "straight to target" interceptor. (used for calls that are
		// unadvised but can return this). May be required to expose the proxy.
		Callback targetInterceptor;
		if (exposeProxy) {
			targetInterceptor = isStatic ?
					new StaticUnadvisedExposedInterceptor(this.advised.getTargetSource().getTarget()) :
					new DynamicUnadvisedExposedInterceptor(this.advised.getTargetSource());
		}
		else {
			targetInterceptor = isStatic ?
					new StaticUnadvisedInterceptor(this.advised.getTargetSource().getTarget()) :
					new DynamicUnadvisedInterceptor(this.advised.getTargetSource());
		}

		// Choose a "direct to target" dispatcher (used for
		// unadvised calls to static targets that cannot return this).
		Callback targetDispatcher = isStatic ?
				new StaticDispatcher(this.advised.getTargetSource().getTarget()) : new SerializableNoOp();

		Callback[] mainCallbacks = new Callback[]{
			aopInterceptor, // for normal advice
			targetInterceptor, // invoke target without considering advice, if optimized
			new SerializableNoOp(), // no override for methods mapped to this
			targetDispatcher, this.advisedDispatcher,
			new EqualsInterceptor(this.advised),
			new HashCodeInterceptor(this.advised)
		};

		Callback[] callbacks;

		// If the target is a static one and the advice chain is frozen,
		// then we can make some optimisations by sending the AOP calls
		// direct to the target using the fixed chain for that method.
		if (isStatic && isFrozen) {
			Method[] methods = rootClass.getMethods();
			Callback[] fixedCallbacks = new Callback[methods.length];
			this.fixedInterceptorMap = new HashMap<String, Integer>(methods.length);

			// TODO: small memory optimisation here (can skip creation for methods with no advice)
			for (int x = 0; x < methods.length; x++) {
				List<Object> chain = this.advised.getInterceptorsAndDynamicInterceptionAdvice(methods[x], rootClass);
				fixedCallbacks[x] = new FixedChainStaticTargetInterceptor(
						chain, this.advised.getTargetSource().getTarget(), this.advised.getTargetClass());
				this.fixedInterceptorMap.put(methods[x].toString(), x);
			}

			// Now copy both the callbacks from mainCallbacks
			// and fixedCallbacks into the callbacks array.
			callbacks = new Callback[mainCallbacks.length + fixedCallbacks.length];
			System.arraycopy(mainCallbacks, 0, callbacks, 0, mainCallbacks.length);
			System.arraycopy(fixedCallbacks, 0, callbacks, mainCallbacks.length, fixedCallbacks.length);
			this.fixedInterceptorOffset = mainCallbacks.length;
		}
		else {
			callbacks = mainCallbacks;
		}
		return callbacks;
	}
```
	 最终生成了代理对象,将这个对象放入ioc容器当中,当调用这个对象时,ioc会直接取出代理对象,也就是先进入DynamicAdvisedInterceptor的intercept方法。


> 大概梳理一下事物的流程
> 一. 初始化流程    


	1.首先开始初始化配置文件

	2.然后执行到<context:component-scan base-package="com.service"></context:component-scan>这里时,会开始扫描注解

	3.当循环扫描到ServiceImpl的时候,会扫描每个方法,经过getAdvicesAndAdvisorsForBean这个方法时会判断每个方法是否触发代理的条件, 怎么触发代理条件, 这里以事物为例:
	<!--
	这里注册了一个事物管理器,也就是说每个类都会经过这个事物管理器判断,是否有@Transactional方法;
	需要注意的是,这个驱动相当于新加了一个方法环绕类型的切入点.
	-->
		<tx:annotation-driven transaction-manager="transactionManager"
	proxy-target-class="true"></tx:annotation-driven>   
	
	  getAdvicesAndAdvisorsForBean如果返回有值时,则表示需要生成代理类
	
	因为我们service中已经定义好了@Transactional方法了,所以触发了执行生成代理类的条件.
	
	4. 生成代理类时,他主要做了两个步骤: 实现一个责任链的类[DynamicAdvisedInterceptor],然后将这个责任链类和service的实现类做绑定生成一个代理,然后返回这个代理对象到IOC容器中,初始化完成

> 二. 调用service的过程

	1. 当调用service这个实现类的时候,会从ioc容器里面去查找,找到了这个bean类则直接返回,注意这里的bean是一个代理类
	2. 直接进入代理类DynamicAdvisedInterceptor的intercept方法里面;
	3.  开始执行责任链机制,查找与这个类绑定的切入点
``` 
// 这里是直接查找与这个类相关的切入点,然后一个个执行完之后到达最终的service方法
List<Object> chain = this.advised.getInterceptorsAndDynamicInterceptionAdvice(method, targetClass);
```
	4. 需要注意的是这个责任链中有一个TransactionAspectSupport类,这是一个事物的切入点类,这个类中的invokeWithinTransaction方法,它里面详细包含了事物的一系列操作,包括事物开启、提交、回滚等等一系列操作
	5.  执行切入点后,直接到达目标方法,也就是service层的方法,service层的方法处理完毕,在回到invokeWithinTransaction判断是否报错,没有报错则事物提交,报错则进入到它的try/catch方法中进行回滚,最终执行完成;

最终我们总结上面的问题:
#### Spring的事物是通过哪些原理实现的?  
>  动态代理 以及 切入点配合责任链组成的拦截器机制 

####   Spring的事物机制是如何提交和回滚的?
> Spring提供了一个事物管理器,这个事物管理器专门扫描所有方法的@Transactional注解,一旦扫描到了,则会为这个方法的类设置代理,这个事物管理器可以理解为一个环绕类型的切入点,配合责任链模式,当方法执行的时候,会被拦截到TransactionAspectSupport的invokeWithinTransaction方法中,这个里面包含了事物的一系列操作。

### 编后语
由于spring里面代码层次划分很细,导致贴出来的代码特别多,可能会影响你们阅读,不过Spring里面的很多东西封装的都是很完善的,几乎全部都是组件化,导致很多方法很深,不过我们只要了解它大概的原理就行了,至少能够在我们遇到问题时能够推断出从哪个步骤进行下手.可能这篇文章代码和图片比较凌乱,最好是大家有spring的一些基本原理基础,比如bean的实例化啊等等,不然有的地方会看不懂,好了就说这么多了... 希望对大家有帮助.. 也非常欢迎大家提意见!!! 谢谢

> 相关代码 -> https://github.com/liukaixiong/ssm/tree/master