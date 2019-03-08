最近在做针对框架的后台管理系统，涉及到一些技术点做记录。

项目框架 ： SpringBoot、Thymeleaf
页面框架：x-admin

布局框架: thymeleaf-layout-dialect



### SpringBoot

### pom.xml

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-thymeleaf</artifactId>
</dependency>
<dependency>
    <groupId>nz.net.ultraq.thymeleaf</groupId>
    <artifactId>thymeleaf-layout-dialect</artifactId>
    <version>2.3.0</version>
</dependency>
```

### dev-yml

```yml
spring:
  thymeleaf:
    cache: false
    prefix: classpath:/templates
    suffix: .html
    mode: LEGACYHTML5
    enabled: true
    check-template: false
```

### controller

```java
final static private String page = "/route/";
@RequestMapping(value = "/list.html", method = RequestMethod.GET)
public String list() throws Exception {
    return page + "routeList";
}
```

## Thymeleaf

由于x-admin是采用iframe布局，所以大体页面不用关注。

但是中间部分是动态的跳转的，可能涉及到公共的JS以及CSS。所以这一部分可能需要独立出来

**路径: /base/main.html**

```html
<html class="no-js" xmlns:th="http://www.thymeleaf.org"
      xmlns:layout="http://www.ultraq.net.nz/web/thymeleaf/layout">
<head>
    <meta charset="UTF-8">
    <title></title>
    <meta name="renderer" content="webkit">
    <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
    <meta name="viewport"
          content="width=device-width,user-scalable=yes, minimum-scale=0.4, initial-scale=0.8,target-densitydpi=low-dpi"/>
    <meta name="renderer" content="webkit"/>
 	<!-- js/css 部分 -->
</head>
<header>
    <h1>我是头部</h1>
</header>
<div layout:fragment="content"></div>
<footer>
    <p>我是尾部</p>
    <p layout:fragment="custom-footer">自定义尾部 ....</p>
</footer>
</html>
```

引入公共页面 list.html

```html
<html xmlns:th="http://www.thymeleaf.org" lang="en"
      xmlns:layout="http://www.ultraq.net.nz/web/thymeleaf/layout"
      layout:decorate="~{/base/main}">
    <head>
        <meta charset="UTF-8"/>
        <title>路由列表</title>
    </head>

    <body>
        <div>
            <div layout:fragment="content">
                <p>我是中间部分 ...</p>
            </div>
        </div>
    </body>
</html>
```

## 注意这里有个问题

从页面效果演示来看

![image.png](https://upload-images.jianshu.io/upload_images/6370985-dd86907c80b53756.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

**红色部分居然没有被合并掉，这是bug吗？**

### 坑爹了。

## 坑爹了

# 坑爹了

找了非常多的资料，都没有解答。[眼泪都快流出来了。]

没办法了，看看源码吧，简单的看一下解析流程，猜测它的问题可能在替换内容的时候，出现了问题。

正常的话应该是该页面的content替换布局页面的content

```html
 <body>
     <div>这里就是布局页面的部分</div>
     <div>
         <!-- 下面这一部分需要替换布局部分的content，替换成功了，但是下面这一部分没有删除，导致页面还是展现出来了 --> 
         <div layout:fragment="content">
             <p>我是中间部分 ...</p>
         </div>
     </div>
    </body>
```

然后自己灵光一闪，找了个退而求其次的方法。

```html
<div style="display: none">
    <div layout:fragment="content">
        <p>我是中间部分 ...</p>
    </div>
</div>
```

在这个外面包一层，div，然后是隐藏的，因为模版替换的时候，这里面的`<div layout:fragment="content">`会和布局页面部分做替换，替换完成了，上层不让他显示。也就只显示一个。

![image.png](https://upload-images.jianshu.io/upload_images/6370985-50e0d3d3e957002c.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)



如果有更好的方案，可以分享出来，节省更多人的**辛酸泪**。