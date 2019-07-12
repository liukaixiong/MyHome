# Spring

## Spring和SpringMvc分为父子容器，子容器可以访问父容器，那么既然子容器可以做到父容器能够做到的事情那为什么还要区分开？

**职责范围不同:**

Spring处理业务相关的bean，例如数据源、业务bean，以及事物管控等等。

SpingMVC:处理控制器、视图解析器、请求参数解析器等等。

往大了说:

Spring处理业务相关、SpringMVC处理servlet相关.同时依赖web容器。

## Spring事务失效的几种场景

1. Mysql的存储结构非Innodb。而是MyISAM..
2. Spring和SpringMVC父子容器重复扫描。
3. 非public方法。

# SpringMVC





# SpringBoot