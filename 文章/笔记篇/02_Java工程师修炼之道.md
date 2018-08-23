​                 





# Git

## GitFlow

### 主分支

Master分支:存放的是生产环境中部署的代码。每次更新都将添加对应的版本号标签。

develop分支: 保存当前最新开发成果的分支。再开发完成之后通过测试，便可以将该分支合并到master分支上

### 辅助分支

**feature分支**: 用于开发新功能时所使用的分支。从develop分支发起的feature分支。并且最终可以合向develop分支上。

**release分支:** 辅助版本发布的分支。次分支是发布新的产品而设计的。

**hotfix:** 修复bug分支。



### 提交日志的规范

模版

```xml
<type>(<scope>):<subject>
    //空一行
<body>
    // 空一行
<footer>
```

**type**:

- feat : 新功能(feature);
- fix : 修复bug
- docs : 文档(documentation)
- style : 格式(不影响代码运行的变动)
- refactor : 重构(既不是新功能,也不是修改bug的代码变动)
- test : 增加测试
- chore : 构建过程或辅助工具的变动

**scope** : 用于说明commit影响的范围，比如数据层、控制层、视图层等，视项目不同而不同。

**subject** : 是commit目的的简短描述，不超过50个字符

**body**部分是对本次的commit的详细描述，可以分成多行。

**footer**: 用于两种情况: 不兼容变动时，以BREAKING CHANGE开头,后面是对变动的描述以及变动理由的迁移方法；如果当前commit针对某个issue，那么可以在footer部分关闭这个issue。



