# Conditional



SpringBoot中的autoconfigure包中衍生的注册条件注解。可以根据情况来决定某些Bean是否具有加载的条件，非常灵活的让使用者根据业务来过滤不需要的Bean。

### @ConditionalOnBean

触发阶段：注册

作用: 只有当指定的bean类和/或名称已包含在BeanFactory中时才匹配。 

实现类:OnBeanCondition

### @ConditionalOnClass

作用：条件，仅当指定的类在类路径上时才匹配。

### @ConditionalOnCloudPlatform

在指定的云平台处于活动状态时匹配的条件。

### @ConditionalOnExpression

条件元素的配置注释取决于SpEL表达式的值。

### @ConditionalOnJava

条件匹配基于运行应用程序的JVM版本。

### @ConditionalOnJndi

条件匹配基于JNDI InitialContext的可用性和查找特定位置的能力。

### @ConditionalOnMissingBean

条件，只有在BeanFactory中尚未包含指定的bean类和/或名称时才匹配。 

### @ConditionalOnMissingClass

条件，仅当指定的类不在类路径上时才匹配。

### @ConditionalOnNotWebApplication

条件，仅在应用程序上下文不是Web应用程序上下文时匹配。

### @ConditionalOnProperty

条件，检查指定的属性是否具有特定值。

### @ConditionalOnResource

条件，仅在指定资源位于类路径上时匹配。

### @ConditionalOnSingleCandidate

条件，只有在指定的bean类已经包含在BeanFactory中并且可以确定单个候选者时才匹配。

### @ConditionalOnWebApplication

当应用程序是Web应用程序时匹配的条件。