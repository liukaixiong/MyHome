# 记录Thymeleaf使用

## 操作类型

### 页面操作

#### for循环

```html
<div th:each="column,columnStat:${columns}">
     
</div>
```

```
columnStat称作状态变量，属性有：
    index:当前迭代对象的index（从0开始计算）
    count: 当前迭代对象的index(从1开始计算)
    size:被迭代对象的大小
    current:当前迭代变量
    even/odd:布尔值，当前循环是否是偶数/奇数（从0开始计算）
    first:布尔值，当前循环是否是第一个
    last:布尔值，当前循环是否是最后一个
```

#### Map循环

```html
<li>Map循环：  
    <div th:each="mapS:${map}">  
        <div th:text="${mapS}"></div>  
    </div>
</li>  
```

#### List<Map>循环

```html
<span th:each="keysMap:${obj}">
    <tr th:each="indexNo,key : ${keysMap}">
        <td th:text="${key.current.value.nameValue}"></td>
        <td th:text="${key.current.value.textValue}"></td>
        <td th:text="${key.current.value.xpath}"></td>
        <td th:text="${key.current.value.regexText}"></td>
    </tr>
    <tr>
        <th lay-data="{align:'center'}" colspan="4">============</th>
    </tr>
</span>
```

### JS操作

[参考官方文档](https://www.thymeleaf.org/doc/tutorials/3.0/usingthymeleaf.html#javascript-inlining)

**获取后端传递进来的参数值**

**必须使用`th:inline="javascript"`以下方式显式启用此模式： <script th:inline="javascript">**

获取String类型的值

```
var columnString = [(${columnString})];
```

获取转义的值

```
/* <![CDATA[ */
var columnString = [[${columnString}]];
/* ]]> */
var columnList = JSON.parse(columnString);
```

> 千万要注意加上/* <![CDATA[ */ /* ]]> */  真的是坑。

**页面onclick使用方法**

```html
th:onclick="|javascript:insertFilterColumn('#column_div-'+${rowStat.index})|"
```

