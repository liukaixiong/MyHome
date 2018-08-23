# SpringBootApplication

spring-boot启动的类的标识注解，具体是如何运作的？

首先看看这个注解里面到底包含什么内容?

```java
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Inherited
@SpringBootConfiguration	
@EnableAutoConfiguration	// 开启自动化配置
@ComponentScan(excludeFilters = {
		@Filter(type = FilterType.CUSTOM, classes = TypeExcludeFilter.class),
		@Filter(type = FilterType.CUSTOM, classes = AutoConfigurationExcludeFilter.class) })
public @interface SpringBootApplication {

	/**
	 * 排除特定的自动配置类，以便永远不会应用它们。
	 * @return the classes to exclude
	 */
	@AliasFor(annotation = EnableAutoConfiguration.class, attribute = "exclude")
	Class<?>[] exclude() default {};

	/**
	 * 排除特定的自动配置类名称，使它们永远不会出现 
	 * @return the class names to exclude
	 * @since 1.3.0
	 */
	@AliasFor(annotation = EnableAutoConfiguration.class, attribute = "excludeName")
	String[] excludeName() default {};

	/**
	 * 用于扫描带注释组件的基础包。, 使用{@link #scanBasePackageClasses} 
	 * 作为基于字符串的包名称的类型安全替代。
	 * @return base packages to scan
	 * @since 1.3.0
	 */
	@AliasFor(annotation = ComponentScan.class, attribute = "basePackages")
	String[] scanBasePackages() default {};

	/**
	 * Type-safe alternative to {@link #scanBasePackages} for specifying the packages to
	 * scan for annotated components. The package of each class specified will be scanned.
	 * <p>
	 * Consider creating a special no-op marker class or interface in each package that
	 * serves no purpose other than being referenced by this attribute.
	 * @return base packages to scan
	 * @since 1.3.0
	 */
	@AliasFor(annotation = ComponentScan.class, attribute = "basePackageClasses")
	Class<?>[] scanBasePackageClasses() default {};

}
```



上面是整个注解的内容，下面拆解每个类上的关键注解的定义

## @SpringBootConfiguration

### @Configuration  

这个类，在spring中也是代表一个标记，而这个标记的作用就是说明被标记的类是一个配置类，配置类里面可以自由定义Bean。而被标记的类会被自动扫描到并且加载到IOC容器中。

## @ComponentScan

该注解的作用是扫描指定包下面的符合条件的类，并且加载到IOC容器中。如果不指定的话，则会在所在类的package进行扫描。

> 注：所以SpringBoot的启动类最好是放在root package下，因为默认不指定basePackages。 

## @EnableAutoConfiguration

该类就是开启自动配置的类，这个类中其实就是借助了@Import的支持，收集和注册特定场景相关的bean的定义。

### @AutoConfigurationPackage

而这个类则是借助AutoConfigurationPackages.Registrar完成IOC容器的注册

#### @Import(AutoConfigurationPackages.Registrar.class)

### @Import(EnableAutoConfigurationImportSelector.class)

这一部分十分关键，借助这个类SpringBoot应用将所有符合条件的@Configuration配置都加载到当前SpringBoot创建并使用IOC。

借助于Spring框架原有的一个工具类：`SpringFactoriesLoader`的支持，@EnableAutoConfiguration可以智能的自动配置功效才得以大功告成！ 





# Main方法启动流程

```java
public static void main(String[] args) {
    SpringApplication.run(GatewayServerApplication.class, args);
}
```



## run()

1. 构建一个SpringApplication实例

   1.1 触发initialize()方法

   ​	1.1.1 通过 SpringFactoriesLoader工具类在spring.factories文件中查找**ApplicationContextInitializer**类

   ​	1.1.2 通过 SpringFactoriesLoader工具类在spring.factories文件中查找**ApplicationListener**类

2. 启动一个run方法

   1. 设定一个启动实例,记录开始时间，是否启动。
   2. 遍历调用所有SpringApplicationRunListener的environmentPrepared()的方法，告诉他们：“当前SpringBoot应用使用的Environment准备好了咯！”。 
   3. 获取上下文传递进来的变量，例如“spring.profiles.active”

   ```ymal
   spring:
     config:
       name:
       location:
     cloud:
       bootstrap:
         sources:
   spring.application.name
   ```

   

 

## 启动加载的接口类型



启动时通过SpringFactoriesLoader.loadFactoryNames的方法加载对应的接口类型类。

```
org.springframework.boot.SpringApplicationRunListener
	org.springframework.boot.context.event.EventPublishingRunListener
org.springframework.cloud.bootstrap.BootstrapConfiguration
	
org.springframework.context.ApplicationContextInitializer # 应用上下文处理器

org.springframework.context.ApplicationListener
org.springframework.boot.env.EnvironmentPostProcessor
org.springframework.boot.env.PropertySourceLoader
org.springframework.beans.BeanInfoFactory
org.springframework.boot.diagnostics.FailureAnalyzer
org.springframework.boot.autoconfigure.EnableAutoConfiguration
org.springframework.cloud.client.circuitbreaker.EnableCircuitBreaker
org.springframework.boot.autoconfigure.AutoConfigurationImportFilter
org.springframework.boot.autoconfigure.template.TemplateAvailabilityProvider
org.springframework.boot.actuate.autoconfigure.ManagementContextConfiguration

```



