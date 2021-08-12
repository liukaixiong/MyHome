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

### 3. 获取继承注解内容

`AnnotatedElementUtils` 

如果B注解想要继承A注解的内容，可以使用

```java
@AliasFor(annotation = Author.class, attribute = "nickname")
String[] nickname() default {};
```

代表当前注解继承了Author的nickname的值

```java
Method test1 = TestAnnotation.class.getDeclaredMethod("test1", null);
ExceptionHandle mergedAnnotation = AnnotatedElementUtils.findMergedAnnotation(test1, ExceptionHandle.class);
```

### 4. 遍历某个对象的所有字段值

遍历某个对象的所有字段值，可以根据字段名查找对应的注解

```java
ReflectionUtils.doWithLocalFields(targetClass, new ReflectionUtils.FieldCallback() {
    @Override
    public void doWith(Field field) throws IllegalArgumentException, IllegalAccessException {
        AnnotationAttributes ann = findAutowiredAnnotation(field, annoList);
        if (ann != null) {
            // 如果是静态方法
            if (Modifier.isStatic(field.getModifiers())) {
                if (logger.isWarnEnabled()) {
                    logger.warn("Autowired annotation is not supported on static fields: " + field);
                }
                return;
            }

        }  
    private void addAnnoList(Map<Class, Set<String>> annotationValueList, Class anno, String value) {
        Set<String> annoList = annotationValueList.get(anno);
        if (annoList == null) {
            annoList = new HashSet<>();
            annotationValueList.put(anno, annoList);
        }
        annoList.add(value);
    }
});
```

### 5. 加载文件的方式

Spring 提供了一个 ResourceUtils 工具类，它支持“**classpath**:”和**“**file:”的地址前缀 ，它能够从指定的地址加载文件资源。

```java
File clsFile = ResourceUtils.getFile("classpath:application.yml");
System.out.println(clsFile);

// 可以根据通配符加载文件
PathMatchingResourcePatternResolver resourcePatternResolver = new PathMatchingResourcePatternResolver();
Resource[] resources = resourcePatternResolver.getResources("classpath:*.yml");
```

### 6. 加载特定的类

加载class下面适配的类的定义

```java
// true：默认TypeFilter生效，这种模式会查询出许多不符合你要求的class名
// false：关闭默认TypeFilter
ClassPathScanningCandidateComponentProvider provider = new ClassPathScanningCandidateComponentProvider(
    false);

// 扫描带有自定义注解的类
provider.addIncludeFilter(new AnnotationTypeFilter(SpringBootTest.class));

// 接口不会被扫描，其子类会被扫描出来
provider.addIncludeFilter(new AssignableTypeFilter(SourceModel.class));

// Spring会将 .换成/  ("."-based package path to a "/"-based)
// Spring拼接的扫描地址：classpath*:xxx/xxx/xxx/**/*.class
// Set<BeanDefinition> scanList = provider.findCandidateComponents("com.p7.demo.scanclass");
Set<BeanDefinition> scanList = provider.findCandidateComponents("com.elab.spring.*");

for (BeanDefinition beanDefinition : scanList) {
    System.out.println(beanDefinition.getBeanClassName());
}
```

### 7. 正则通配符

```java
// 路径匹配
AntPathMatcher antPathMatcher = new AntPathMatcher();
System.out.println(sourceUrl + " : " + path + "  > " + antPathMatcher.match(sourceUrl, path));

// 获取通配符匹配的值
System.out.println(antPathMatcher.extractPathWithinPattern("/api/*/*.html", "/api/a.html"));

// 获取{}号的值,并且返回给Map
Map<String, String> stringStringMap =
            antPathMatcher.extractUriTemplateVariables("/api/{a}/{b}/{c}", "/api/1/2/3");
        System.out.println(stringStringMap);


PatternMatchUtils.simpleMatch("liu*", "liukaix")
    
    
```

