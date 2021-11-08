# 实战Spring之注解处理器

## 需求场景

有时候我们希望定义一个特定的注解，被注解打标过的方法能够被代理，完成一些特定的操作。

当然我们可以通过Spring的切面去完成比如:

```java
@Around(value = "execution(* com.xxx.xxx.xxx.dao..*(..))")
```

但这种方式感觉还是太麻烦了，我们希望像事务注解`@Transaction` 一样，打上标记就会被代理，不需要定义各种表达式切面。

**另外简单点、通用点、好理解一点。。。**

**另外简单点、通用点、好理解一点。。。**

**另外简单点、通用点、好理解一点。。。**

## 实现思路

其实本质的做法也是通过切面去完成，不过`@Around` 是基于表达式去处理，而我们希望能通过注解方式，来决定是否需要代理。(PS: 表达式也能实现注解拦截)

这里涉及到切面的两个点:

- `Advice` : 你可以理解为拦截器
- `Pointcut`:  你可以理解规则匹配器

当我们梳理思路的时候只需要思考：

1. Spring在bean处理的时候，会遍历每个类和方法。
2. 这个时候在遍历时,去判断每个方法是否符合`pointcut`规则，满足的话则进行代理
3. 那么一旦代理的话，肯定是需要有具体的代理业务拦截逻辑的，`advice`就是逻辑处理拦截器。
4. 我们只需要将两者结合形成一个工厂类每次去找被代理后的逻辑就行了。

好，那么我们看如何去实现？

## 实现代码

### 1. Pointcut

我们先来定义规则，我们希望特定的注解打在方法上，这些方法能够被代理，然后查看`Pointcut` 的实现类有一个

`StaticMethodMatcherPointcut`

```java
/**
 * 特定注解拦截器
 *
 * @author ： liukx
 * @time ： 2020/7/9 - 20:02
 */
public class AnnotationAttributeSourcePointcut extends StaticMethodMatcherPointcut implements Serializable {

    /**
     * 需要被拦截代理的注解列表
     */
    private Set<Class<? extends Annotation>> annotationsOperation = new LinkedHashSet<>(8);

    public void addAnnotations(Class<? extends Annotation> annotation) {
        annotationsOperation.add(annotation);
    }

    /**
     * 符合该注解的通通被代理起来
     *
     * @param method
     * @param targetClass
     * @return
     */
    @Override
    public boolean matches(Method method, Class<?> targetClass) {
        if (CacheParseUtil.isContainAnnotations(annotationsOperation, method)) {
            return true;
        }
        return false;
    }

    /**
     * 遍历该方法是否包含特定的注解
     *
     * @param annotations
     * @param element
     * @return
     */
    public boolean isContainAnnotations(Set<Class<? extends Annotation>> annotations, AnnotatedElement element) {
        boolean isContain = false;
        for (Class<? extends Annotation> annotation : annotations) {
            if (AnnotatedElementUtils.hasAnnotation(element, annotation)) {
                isContain = true;
                break;
            }
        }
        return isContain;
    }
}
```

### 2. Advice

我们在第一步定义了匹配规则，一旦被规则match匹配上，那么对应的逻辑希望交给advice。

```java
import org.aopalliance.intercept.MethodInterceptor;
import org.aopalliance.intercept.MethodInvocation;
import org.springframework.aop.framework.ReflectiveMethodInvocation;
import org.springframework.beans.factory.annotation.Autowired;

import java.io.Serializable;
import java.lang.annotation.Annotation;
import java.lang.reflect.Method;
import java.util.List;

/**
 * 实现缓存的拦截器
 *
 * @author ： liukx
 * @time ： 2020/7/9 - 20:08
 */
public class AnnotationInterceptor implements MethodInterceptor, Serializable {

    @Autowired(required = false)
    private List<AnnotationProcessService> cacheProcessServices;

    @Override
    public Object invoke(MethodInvocation invocation) throws Throwable {
        Object proceed = null;
        if (cacheProcessServices != null && invocation instanceof ReflectiveMethodInvocation) {
            ReflectiveMethodInvocation methodInvocation = (ReflectiveMethodInvocation)invocation;
            Method method = invocation.getMethod();
            Annotation[] annotations = method.getAnnotations();
            for (int i = 0; i < annotations.length; i++) {
                Annotation annotation = annotations[i];
                for (int j = 0; j < cacheProcessServices.size(); j++) {
                    AnnotationProcessService cache = cacheProcessServices.get(i);
                    if (annotation.annotationType() == cache.annotation()) {
                        proceed = cache.invokeWithinTransaction(methodInvocation);
                    }
                }
            }
            return proceed;
        }
        return invocation.proceed();
    }
}
```

#### AnnotationProcessService

定义一个这样的接口是希望，后续如果还有其他注解需要处理时，只需要实现该接口准备好注解类和逻辑方法，我们可以直接回调它处理，这样会更为通用。

```java
import org.springframework.aop.framework.ReflectiveMethodInvocation;
import org.springframework.core.Ordered;

import java.lang.annotation.Annotation;

/**
 * 注解的执行器
 *
 * @author liukaixiong
 * @Email liukx@elab-plus.com
 * @date 2021/9/27 - 10:49
 */
public interface AnnotationProcessService extends Ordered {

    @Override
    default int getOrder() {
        return LOWEST_PRECEDENCE;
    }

    /**
     * 具体的注解
     *
     * @return
     */
    public Class<? extends Annotation> annotation();

    /**
     * 上面匹配到的注解会被触发，尽量不要对结果做改变。
     *
     * @param invocation
     * @return
     * @throws Throwable
     */
    public Object invokeWithinTransaction(ReflectiveMethodInvocation invocation) throws Throwable;
}
```

被代理的类，先走这个接口类进行注解`annotation`匹配，然后在流转到`invokeWithinTransaction` 方法。这样更为通用。

### 3. DefaultBeanFactoryPointcutAdvisor

`org.springframework.aop.support.DefaultBeanFactoryPointcutAdvisor` 这个是Spring内部提供的类，用于组合`Pointcut`和`Advisor`的。

我们只需要在配置文件进行组合

```java
@Configuration
public class AopConfig {

    @Bean
    @Role(BeanDefinition.ROLE_INFRASTRUCTURE)
    @ConditionalOnBean(AnnotationProcessService.class)
    public DefaultBeanFactoryPointcutAdvisor transactionAdvisor(
        AnnotationAttributeSourcePointcut annotationAttributeSourcePointcut) {
        DefaultBeanFactoryPointcutAdvisor advisor = new DefaultBeanFactoryPointcutAdvisor();
        // 具体的拦截器
        advisor.setAdvice(annotationInterceptor());
        // 需要被拦截方法的规则判断器，一旦符合，才会被代理给拦截器处理
        advisor.setPointcut(annotationAttributeSourcePointcut);
        return advisor;
    }

    @Bean
    @Role(BeanDefinition.ROLE_INFRASTRUCTURE)
    @ConditionalOnBean(AnnotationProcessService.class)
    public AnnotationAttributeSourcePointcut annotationAttributeSourcePointcut(
        List<AnnotationProcessService> annotationProcessServiceList) {
        // 该类是用作比对方法的注解是否符合代理的条件
        AnnotationAttributeSourcePointcut cacheAttributeSourcePointcut = new AnnotationAttributeSourcePointcut();
        annotationProcessServiceList.forEach((annotation) -> {
            cacheAttributeSourcePointcut.addAnnotations(annotation.annotation());
        });
        return cacheAttributeSourcePointcut;
    }

    @Bean
    @Role(BeanDefinition.ROLE_INFRASTRUCTURE)
    @ConditionalOnBean(AnnotationProcessService.class)
    public AnnotationInterceptor annotationInterceptor() {
        AnnotationInterceptor interceptor = new AnnotationInterceptor();
        return interceptor;
    }
}
```



后续你需要定义各种自定义的注解只需要实现`AnnotationProcessService` 接口就行了，简单方便好拓展。

## 测试用例

我们来定义一个`@AuthorDescription`注解处理器，

```java
/**
 * 对于功能定义的一些拦截描述
 *
 * @author liukaixiong
 * @Email liukx@elab-plus.com
 * @date 2021/9/27 - 11:10
 */
public class AuthorDescriptionAnnotationProcess implements AnnotationProcessService {
    private Logger logger = LoggerFactory.getLogger(getClass());
     
    /**
     * 表示只处理@AuthorDescription注解内容 
     */ 
    @Override
    public Class<? extends Annotation> annotation() {
        return AuthorDescription.class;
    }

    @Override
    public Object invokeWithinTransaction(ReflectiveMethodInvocation invocation) throws Throwable {
        Method method = invocation.getMethod();
        AuthorDescription authorDescription = AnnotationUtils.getAnnotation(method, AuthorDescription.class);
        String clazzName = method.getDeclaringClass().getSimpleName();
        String name = method.getName();
        String methodName = clazzName + "." + name;
        Object[] arguments = invocation.getArguments();  
        // 业务逻辑处理
        return invocation.proceed();
    }
}
```

随便定义的测试方法

```java
public class TestAuthorAnnotation {

    @AuthorDescription(modulesName = "user", describe = "这是一个测试", nickname = {"liukx",
        "jay"}, searchKey = "${request[0].id}-${request[1].username}")
    public String test(Map<String, String> request, UserModel userModel) {
        return "OK";
    }

}
```

测试类

```java
@RunWith(SpringRunner.class)
//@EnableCaching
// 这个是开启切面，必要的。
@EnableAspectJAutoProxy
@SpringBootTest(classes = {AopConfig.class,AuthorDescriptionAnnotationProcess.class,
    TestAuthorAnnotation.class})
public class AuthorDescriptionAnnotationProcessTest {

    @Autowired
    private TestAuthorAnnotation testAnnotation;

    @Test
    public void testInvokeWithinTransaction() {
        Map<String, String> request = new HashMap<>();
        request.put("id", "1314");
        request.put("username", "jayzhou");
        request.put("sex", "MAN");
        request.put("age", "13");

        UserModel userModel = new UserModel();
        userModel.setUserId("5555");
        userModel.setUsername("liukx");

        String test = testAnnotation.test(request, userModel);
        System.out.println(test);
    }

}
```



为了观看体验，有的无关紧要的代码我就不贴了，希望大家更关注核心逻辑流转。



希望对你有帮助... 



> 如果你有疑问，欢迎留言交流，我看到了会第一时间答复你。

