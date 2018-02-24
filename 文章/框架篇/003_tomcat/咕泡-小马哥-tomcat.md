## web技术栈

### servlet技术栈

### web Flux(Netty)

1. ## 目录结构

   BIO
2. NIO



### web 自动装配

#### API角度分析

Servlet 3.0 + API 实现Web自动装配 `ServletContainerInitializer`

例如@WebServlet等等



### 容器角度分析

传统的web应用,将webapp部署到Servlet容器中。

嵌入式web应用,灵活部署,任意指定位置(或者通过复杂的条件判断)

tomcat 7 是 Servlet 3.0的实现,所以你应该自然而然的联想到`ServletContainerInitializer` 去实现的

tomcat 8 是 Servlet 3.1的实现，NIO `HttpServletRequest`、 `HttpServletResponse`


### lib 目录
