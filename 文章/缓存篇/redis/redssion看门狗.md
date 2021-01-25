

最近需要了解一些关于redisson相关的功能，比较出名的就是锁的封装，如果使用的是java语言的话，比较推荐redisson。

[相关的目录介绍](https://github.com/redisson/redisson/wiki/%E7%9B%AE%E5%BD%95)

github上的点赞数已经超过1W5了，所以还是比较靠谱的。

## 防重复提交

由于线上都是多机部署,不存在单点，所以本地锁是肯定解决不了资源竞争的问题，如果是mysql的话，麻烦而且耗性能。

基于redisson去实现一个防重复提交的功能.

基于上述场景我们要实现的方式:

1. 业务不需要过多编码,直接一个注解指定key的规则.
2. 单个资源控制,还要拥有读写锁的相关的功能.

### 实现思路:

1. 自定义一套规则注解，基于该注解去实现对应的功能。
2. 利用Spring的拦截器的机制,将上面的功能注册到Spring中.
3. 参考@EnableCaching 注解的实现









### 编码实现

注意编码仅仅只是思路，你如果直接抄过去不一定能跑起来。因为有很多内部封装的类.不过你可以根据自己的理解去做自己的改造.

#### 一. 定义注解

```java
import java.lang.annotation.*;

@Target({ElementType.METHOD, ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
@Inherited
@Documented
public @interface CacheLoopSubmit {

    /**
     * 缓存的key，不填写的话按照方法名的全称
     *
     * @return
     */
    String cacheName() default "";

    /**
     * 重复提交的标识key.
     * ALL如果是实体对象那么，对比所有属性。
     * 建议使用者重写实体的equals方法。
     * 如果是原始数据类型，包含String等等，则填写需要对比的对象下标 {0},{1}
     *
     * @return
     */
    String[] unionKey() default {};

    /**
     * 锁超时时间(ms)
     *
     * @return
     */
    long timeOut() default 5000;

    /**
     * 是否等待完成
     *
     * @return true 尝试抢锁,未抢到等待timeOut的超时时间，超过到则释放， false:没抢到锁直接跳过
     */
    boolean isWaitComplete() default false;

    /**
     * 错误提示
     *
     * @return
     */
    String errorMsg() default "系统认定为重复请求";

}
```

#### 二. 实现注解相关的规则逻辑

这里有一些相关框架的封装，有一些类没有写出来。

```java
import com.elab.core.utils.StringUtils;
import com.elab.redis.annotation.CacheLoopSubmit;
import com.elab.redis.exceptions.ReSubmitException;
import com.elab.redis.interceptor.ICacheProcessService;
import com.elab.redis.utils.CacheParseUtil;
import com.elab.redis.utils.RedisLockUtils;
import org.redisson.api.RLock;
import org.redisson.api.RedissonClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.aop.framework.ReflectiveMethodInvocation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.annotation.AnnotationUtils;
import org.springframework.stereotype.Component;

import java.lang.reflect.Method;
import java.util.concurrent.TimeUnit;

/**
 * 防重复提交
 *
 * @author ： liukx
 * @time ： 2020/7/10 - 10:58
 */
@Component
public class CacheLoopProcessImpl implements ICacheProcessService {

    private String prefix = "loopSubmit";

    @Autowired
    private RedissonClient client;

    private Logger logger = LoggerFactory.getLogger(CacheLoopProcessImpl.class);

    @Override
    public boolean subscribe(Method method) {
        return CacheParseUtil.isContainAnnotation(method, CacheLoopSubmit.class);
    }

    @Override
    public Object invokeWithinTransaction(ReflectiveMethodInvocation invocation) throws Throwable {
        Method method = invocation.getMethod();
        CacheLoopSubmit cacheLoopSubmit = AnnotationUtils.getAnnotation(method, CacheLoopSubmit.class);
        String[] unionKey = cacheLoopSubmit.unionKey();
        String clazzName = method.getDeclaringClass().getName();
        Object[] arguments = invocation.getArguments();

        String cacheKey = CacheParseUtil.generateUnionKey(unionKey, arguments);

        String cacheName = cacheLoopSubmit.cacheName();

        if (StringUtils.isEmpty(cacheKey)) {
            cacheName = prefix + ":" + clazzName + ":-+" + method.getName();
        }

        cacheName = cacheName + ":" + cacheKey;

        RLock lockObject = client.getLock(cacheName);

        String errorMsg = cacheLoopSubmit.errorMsg();

        try {
            if (tryLock(lockObject, cacheLoopSubmit)) {
                Object proceed = invocation.proceed();
                return proceed;
            } else {
                throw new ReSubmitException(errorMsg);
            }
        } catch (InterruptedException e) {
            logger.warn("尝试获取锁超时", e);
        } finally {
            RedisLockUtils.releaseLock(lockObject);
        }
        return null;
    }

    /**
     * 尝试获取锁
     *
     * @param lock            锁对象
     * @param cacheLoopSubmit 注解
     * @return
     */
    private boolean tryLock(RLock lock, CacheLoopSubmit cacheLoopSubmit) {
        try {
            if (cacheLoopSubmit.isWaitComplete()) {
                return lock.tryLock(cacheLoopSubmit.timeOut(), TimeUnit.MILLISECONDS);
            } else {
                return lock.tryLock();
            }
        } catch (Exception e) {
            logger.warn("获取锁异常:" + e.getMessage());
            return false;
        }
    }

}
```

```java
/**
 * 定义缓存处理的业务规则
 *
 * @author : liukx
 * @date : 2020/7/10 - 10:50
 */
public interface ICacheProcessService {
    /**
     * 是否关注指定方法
     *
     * @param method
     * @return
     */
    public boolean subscribe(Method method);

    /**
     * 关注之后，处理的业务逻辑
     *
     * @param invocation
     * @return
     * @throws Throwable
     */
    public Object invokeWithinTransaction(ReflectiveMethodInvocation invocation) throws Throwable;
 
}
```

```java
import org.aopalliance.intercept.MethodInterceptor;
import org.aopalliance.intercept.MethodInvocation;
import org.springframework.aop.framework.ReflectiveMethodInvocation;
import org.springframework.beans.factory.annotation.Autowired;

import java.io.Serializable;
import java.lang.reflect.Method;
import java.util.List;

/**
 * 实现缓存的拦截器
 * @author ： liukx
 * @time ： 2020/7/9 - 20:08
 */
public class CacheInterceptor implements MethodInterceptor, Serializable {
    
    @Autowired
    private List<ICacheProcessService> cacheProcessServices;

    @Override
    public Object invoke(MethodInvocation invocation) throws Throwable {
        Object proceed = null;
        if (invocation instanceof ReflectiveMethodInvocation) {
            ReflectiveMethodInvocation methodInvocation = (ReflectiveMethodInvocation) invocation;
            Method method = invocation.getMethod();
            for (int i = 0; i < cacheProcessServices.size(); i++) {
                ICacheProcessService cache = cacheProcessServices.get(i);
                if (cache.subscribe(method)) {
                    proceed = cache.invokeWithinTransaction(methodInvocation);
                }
            }
            return proceed;
        }
        return null;
    }
}
```

```java
import com.elab.core.exception.BusinessException;

/**
 * @Module 异常管理
 * @Description 重复提交异常
 * @Author liukaixiong
 * @Date 2021/1/4 17:23
 */
public class ReSubmitException extends BusinessException {

    public ReSubmitException(String message) {
        super(message);
    }

    public ReSubmitException(String errorCode, String message) {
        super(errorCode, message);
    }
}
```

#### 三. 将注解和规则实现注册到Spring中，让Bean去构建的时候，去发现对应的注解，并且为其代理。

开始构建Spring所识别类的相关对象

1. 构建advisor

```java
import org.springframework.aop.Pointcut;
import org.springframework.aop.support.AbstractBeanFactoryPointcutAdvisor;

/**
 * 重复提交
 *
 * @author ： liukx
 * @time ： 2020/7/9 - 19:55
 */
public class BeanFactoryCacheAttributeSourceAdvisor extends AbstractBeanFactoryPointcutAdvisor {

    private CacheAttributeSourcePointcut pointcut;

    public void setPointcut(CacheAttributeSourcePointcut pointcut) {
        this.pointcut = pointcut;
    }

    @Override
    public Pointcut getPointcut() {
        return pointcut;
    }
}
```

2. 构建pointcut

```java
import com.elab.redis.utils.CacheParseUtil;
import org.springframework.aop.support.StaticMethodMatcherPointcut;

import java.io.Serializable;
import java.lang.annotation.Annotation;
import java.lang.reflect.Method;
import java.util.LinkedHashSet;
import java.util.Set;

/**
 * @author ： liukx
 * @time ： 2020/7/9 - 20:02
 */
public class CacheAttributeSourcePointcut extends StaticMethodMatcherPointcut implements Serializable {

    private Set<Class<? extends Annotation>> CACHE_OPERATION_ANNOTATIONS = new LinkedHashSet<>(8);

    public void addAnnotations(Class<? extends Annotation> annotation) {
        CACHE_OPERATION_ANNOTATIONS.add(annotation);
    }

    @Override
    public boolean matches(Method method, Class<?> targetClass) {
        if (CacheParseUtil.isContainAnnotations(CACHE_OPERATION_ANNOTATIONS, method)) {
            return true;
        }
        return false;
    }
}
```

#### 构建配置类

```
package com.elab.redis.config;

import com.alibaba.fastjson.support.spring.GenericFastJsonRedisSerializer;
import com.elab.redis.CacheTemplate;
import com.elab.redis.annotation.CacheLoopSubmit;
import com.elab.redis.annotation.CacheReadLock;
import com.elab.redis.annotation.CacheWriteLock;
import com.elab.redis.interceptor.BeanFactoryCacheAttributeSourceAdvisor;
import com.elab.redis.interceptor.CacheAttributeSourcePointcut;
import com.elab.redis.interceptor.CacheInterceptor;
import com.elab.redis.redisson.DefaultRedissonSpringCacheManager;
import com.elab.redis.spring.data.RedisTemplateDecorator;
import org.redisson.api.RedissonClient;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.config.BeanDefinition;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.boot.autoconfigure.data.redis.RedisProperties;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.cache.CacheManager;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Role;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.serializer.StringRedisSerializer;

/**
 * 缓存自动配置
 *
 * @author ： liukx
 * @time ： 2020/7/8 - 19:12
 */
@Configuration
@EnableConfigurationProperties({RedisProperties.class, ElabRedisProperties.class})
@ComponentScan(value = {"com.elab.redis.interceptor.impl"})
public class CacheAutoConfiguration { 

    @Bean
    @Role(BeanDefinition.ROLE_INFRASTRUCTURE)
    public BeanFactoryCacheAttributeSourceAdvisor transactionAdvisor() {
        BeanFactoryCacheAttributeSourceAdvisor advisor = new BeanFactoryCacheAttributeSourceAdvisor();
        advisor.setAdvice(redisCacheInterceptor());
        advisor.setPointcut(cacheAttributeSourcePointcut());
        return advisor;
    }

    @Bean
    @Role(BeanDefinition.ROLE_INFRASTRUCTURE)
    public CacheAttributeSourcePointcut cacheAttributeSourcePointcut() {
        CacheAttributeSourcePointcut cacheAttributeSourcePointcut = new CacheAttributeSourcePointcut();
        cacheAttributeSourcePointcut.addAnnotations(CacheLoopSubmit.class);
     //   cacheAttributeSourcePointcut.addAnnotations(CacheReadLock.class);
     //   cacheAttributeSourcePointcut.addAnnotations(CacheWriteLock.class);
        return cacheAttributeSourcePointcut;
    }

    @Bean
    @Role(BeanDefinition.ROLE_INFRASTRUCTURE)
    public CacheInterceptor redisCacheInterceptor() {
        CacheInterceptor interceptor = new CacheInterceptor();
        return interceptor;
    } 
}
```