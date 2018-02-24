> 主要想了解一下Spring中如何通过切面去动态在方法前后切入多个切入点去实现的。

需要关注的几个点：
    1. 切入点和通知是如何去注册的？(后续补充)
    2. 代理过程中是如何植入这些拦截的？

# 布置场景
log 日志切入点实现类
```java
/**
 * 日志切面
 *
 * @author Liukx
 * @create 2017-12-14 11:21
 * @email liukx@elab-plus.com
 **/
public class LogAspect {

    public LogAspect(){
        System.out.println("加载==============logAspect");
    }

    Logger logger = LoggerFactory.getLogger(LogAspect.class);

    public void before(JoinPoint point) {
        logger.info("=============before==================");
        System.out.println("---------------before---------------");
    }

    public void after(JoinPoint point, Object retValue) {
        logger.info("=============after==================");
        System.out.println("---------------after---------------");
    }

}
```
配置文件: spring-service.xml
这里只列举相关的关键配置,其他注解扫描的就没加了
```java
<!-- log 切面类 -->
    <bean id="logAspect" class="com.aop.LogAspect" />
    <!-- log 的Aop配置 -->
    <aop:config proxy-target-class="true">
        <aop:aspect ref="logAspect">
            <aop:before method="before" pointcut="execution(* com.service..*.*(..))"></aop:before>
            <aop:after-returning pointcut="execution(* com.service..*.*(..))" arg-names="point,retValue" returning="retValue"  method="after"/>
        </aop:aspect>
    </aop:config>
```

测试用例:
```java

    @Autowired
    @Qualifier("transactionalService")
    private ITransactionalService transactionalService;

    /**
     * 用于测试事物是否提交
     *
     * @throws Exception
     */
    @Test
    public void testTransactionalCommit() throws Exception {
        transactionalService.testQuery();
        logger.debug("test---------");
    }
```

> 上面的配置就是说 通知com.service包下面的类将会被LogAspect切入,before方法表示方法执行之前切入,after方法在方法之后之后切入

### 处理流程
我们先看下代理中做了些啥事?
1. 直接debug打到transactionalService.testQuery();看处理的代理是个什么样子的类
  **CglibAopProxy.class** :  这是一个Cglib代理的类,具体看他的拦截方法
```java
@Override
		public Object intercept(Object proxy, Method method, Object[] args, MethodProxy methodProxy) throws Throwable {
			Object oldProxy = null;
			boolean setProxyContext = false;
			Class<?> targetClass = null;
			Object target = null;
			try {
				if (this.advised.exposeProxy) {
					// Make invocation available if necessary.
					oldProxy = AopContext.setCurrentProxy(proxy);
					setProxyContext = true;
				}
				// May be null. Get as late as possible to minimize the time we
				// "own" the target, in case it comes from a pool...
                // 这里是获取要执行的目标对象,就是我们的ITransactionalService实现类
				target = getTarget();
				if (target != null) {
					targetClass = target.getClass();
				}
                 // 这里会获得一个拦截链,也就是一系列的advised对象,相当于设计模式中的责任链模式
				List<Object> chain = this.advised.getInterceptorsAndDynamicInterceptionAdvice(method, targetClass);
				Object retVal;
				// Check whether we only have one InvokerInterceptor: that is,
				// no real advice, but just reflective invocation of the target.
				if (chain.isEmpty() && Modifier.isPublic(method.getModifiers())) {
					// We can skip creating a MethodInvocation: just invoke the target directly.
					// Note that the final invoker must be an InvokerInterceptor, so we know
					// it does nothing but a reflective operation on the target, and no hot
					// swapping or fancy proxying.
					retVal = methodProxy.invoke(target, args);
				}
				else {
					// We need to create a method invocation...
                      // 创造一个方法调用,也就是具体责任链的执行类
                      // 这个方法里面非常关键,这里执行chain里面的所有代理方法
					retVal = new CglibMethodInvocation(proxy, target, method, args, targetClass, chain, methodProxy).proceed();
				}
				retVal = processReturnType(proxy, target, method, retVal);
				return retVal;
			}
			finally {
				if (target != null) {
					releaseTarget(target);
				}
				if (setProxyContext) {
					// Restore old proxy.
					AopContext.setCurrentProxy(oldProxy);
				}
			}
		}
```
CglibMethodInvocation类的结构
![CglibMethodInvocation类结构](http://upload-images.jianshu.io/upload_images/6370985-69a005b4b9b4b745.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

```
 new CglibMethodInvocation(proxy, target, method, args, targetClass, chain, methodProxy).proceed();
```
CglibMethodInvocation的process()方法其实是委托父类去执行的 也就是ReflectiveMethodInvocation



ReflectiveMethodInvocation类
// 这里只列举关键方法,因为上面已经拿到了代理的chain
```java
public class ReflectiveMethodInvocation implements ProxyMethodInvocation, Cloneable {
         // 拦截器列表 里面包装的都是advised
	protected final List<?> interceptorsAndDynamicMethodMatchers;
        // 计数器 
       private int currentInterceptorIndex = -1;
      @Override
	public Object proceed() throws Throwable {
		//	We start with an index of -1 and increment early.
        // 从这里如果大小相等,表示interceptorsAndDynamicMethodMatchers里面的advised已经执行完了.. 就开始执行最终的目标方法
		if (this.currentInterceptorIndex == this.interceptorsAndDynamicMethodMatchers.size() - 1) {                
        // 执行目标方法
			return invokeJoinpoint();
		}

          // 拿到下一个advised
		Object interceptorOrInterceptionAdvice = this.interceptorsAndDynamicMethodMatchers.get(++this.currentInterceptorIndex);
                // 判断是否是InterceptorAndDynamicMethodMatcher这个类型的,这里不用关注
		if (interceptorOrInterceptionAdvice instanceof InterceptorAndDynamicMethodMatcher) {
			// Evaluate dynamic method matcher here: static part will already have
			// been evaluated and found to match.
			InterceptorAndDynamicMethodMatcher dm =
					(InterceptorAndDynamicMethodMatcher) interceptorOrInterceptionAdvice;
			if (dm.methodMatcher.matches(this.method, this.targetClass, this.arguments)) {
				return dm.interceptor.invoke(this);
			}
			else {
				// Dynamic matching failed.
				// Skip this interceptor and invoke the next in the chain.
				return proceed();
			}
		}
		else {
			// It's an interceptor, so we just invoke it: The pointcut will have
			// been evaluated statically before this object was constructed.
            // 执行这个advised,这里可能是AfterReturningAdviceInterceptor可能是MethodBeforeAdviceInterceptor 
			return ((MethodInterceptor) interceptorOrInterceptionAdvice).invoke(this);
		}
	}
}


         /**
	 * Implementation of AOP Alliance MethodInvocation used by this AOP proxy.
	 */
        // 这个类的目的就是为了执行最终的方法而设定的,具体的拦截链路交给了父类的proceed方法处理,只有当父类的proceed方法执行完毕之后,才会回调这个类的invokeJoinpoint方法
	private static class CglibMethodInvocation extends ReflectiveMethodInvocation {

		private final MethodProxy methodProxy;

		private final boolean publicMethod;

		public CglibMethodInvocation(Object proxy, Object target, Method method, Object[] arguments,
				Class<?> targetClass, List<Object> interceptorsAndDynamicMethodMatchers, MethodProxy methodProxy) {
			super(proxy, target, method, arguments, targetClass, interceptorsAndDynamicMethodMatchers);
			this.methodProxy = methodProxy;
			this.publicMethod = Modifier.isPublic(method.getModifiers());
		}

		/**
		 * Gives a marginal performance improvement versus using reflection to
		 * invoke the target when invoking public methods.
		 */
		@Override
                // 最终的执行目标方法
		protected Object invokeJoinpoint() throws Throwable {
                        // 如果执行的目标类的方法是public的,则直接反射调用
			if (this.publicMethod) {
				return this.methodProxy.invoke(this.target, this.arguments);
			}
			else {
                                // 如果执行的目标方法非public的则会交给父类处理
                                // 父类会调用AopUtils.invokeJoinpointUsingReflection方法
                                // 其实反射的时候设置了method.setAccessible(true);
				return super.invokeJoinpoint();
			}
		}
	}
```
我们看下具体的advised对象

- AfterReturningAdviceInterceptor - 目标方法之后执行
- MethodBeforeAdviceInterceptor - 目标方法执行
  其实这两个方法实现方式是差不多的,都实现了MethodInterceptor接口,只是切入点执行的顺序上做了调整而已
```java
public class AfterReturningAdviceInterceptor implements MethodInterceptor, AfterAdvice, Serializable {

	private final AfterReturningAdvice advice;


	/**
	 * Create a new AfterReturningAdviceInterceptor for the given advice.
	 * @param advice the AfterReturningAdvice to wrap
	 */
	public AfterReturningAdviceInterceptor(AfterReturningAdvice advice) {
		Assert.notNull(advice, "Advice must not be null");
		this.advice = advice;
	}

	@Override
	public Object invoke(MethodInvocation mi) throws Throwable {
        // 目标方法,也可以说是责任链对象 因为上面是通过this传递进来的,相当于又执行上面的ReflectiveMethodInvocation的process()方法.去找下一个拦截器这样一个循环
		Object retVal = mi.proceed();
       // 后置切入点
		this.advice.afterReturning(retVal, mi.getMethod(), mi.getArguments(), mi.getThis());
		return retVal;
	}
}

public class MethodBeforeAdviceInterceptor implements MethodInterceptor, Serializable {

	private MethodBeforeAdvice advice; 
	/**
	 * Create a new MethodBeforeAdviceInterceptor for the given advice.
	 * @param advice the MethodBeforeAdvice to wrap
	 */
	public MethodBeforeAdviceInterceptor(MethodBeforeAdvice advice) {
		Assert.notNull(advice, "Advice must not be null");
		this.advice = advice;
	}
	@Override
	public Object invoke(MethodInvocation mi) throws Throwable {
         // 前置切入点执行
		this.advice.before(mi.getMethod(), mi.getArguments(), mi.getThis() );
         // 目标方法执行
		return mi.proceed();
	}

}
```

**梳理一下:**
    1. 通过Cglib代理拿到具体的代理的对象(**CglibAopProxy**)
    2. 在Cglib中的拦截(intercept)处理中,先获取所有切入点的对象(chain)并且构建了一个责任链类(**CglibMethodInvocation**),这个责任链类(**实际执行过程类:ReflectiveMethodInvocation**)包含了所有拦截链(advised集合)对象
    3. 通过这个责任链类开始递归下面所有的拦截类去执行每个advised方法
    4. 执行完所有advised链条方法之后,会到达这个最终的目标方法**CglibMethodInvocation.invokeJoinpoint()**.调用方法这部分都是通过反射去执行的。
    5. 如果被代理的方法不是public类型的则会在反射的时候设置setAccessible为true,破坏了对象封装属性强制调用!

