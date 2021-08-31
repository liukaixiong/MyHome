**# 代码流程**









[avue-cli 源码地址](https://gitee.com/smallweigit/avue-cli)

1. 首先需要熟悉一下VUE应用程序的各个目录的作用

\> https://www.jianshu.com/p/0ae3e3bb3082



2. 启动程序文件流转过程

\- src/main.js : 开始注册所有的组件包括路由

> VUE是单页面流转，应用启动的时候，只需要一个入口，根据这个入口加载特定的组件、理由流转，初始化整个应用程序浏览器访问某个地址会从路由中获取对应的组件也就是compont的路径，看下来这些路径都定义在了`mock\menu.js`中了。
>
> 从里面就能找到要渲染的VUE文件，而VUE文件内部就包含了所有渲染的逻辑

3. 所有拦截器都会被src/mock拦截下来，然后去对比路径，符合的直接mock成模拟数据。







# 遇到问题

#### 1、 Error: Rule can only have one resource source (provided resource and test + include + exclude) in { ...

## 解决方案：

1. 先删掉 package-lock.json
2. 手动在 package.json 的 devDependencies 里添加 “webpack”: “^4.23.0”,
3. 重新安装全部依赖： npm install
4. 重新运行，发现问题解决



