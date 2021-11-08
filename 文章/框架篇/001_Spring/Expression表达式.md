

# Expression表达式

Spring的一种表达式。用来动态的获取，值、对象等。

对此我们可以通过这一表达式来完成我们复杂的判断和值的获取。

## 案例

假设模版是`${}`代表一组模版表达式

```
// 验证帐号密码是否一致
${username == 'admin' && password == '123456'}; // 返回true or false

// 包含关系
${status == 1 || status == 2}
```

| 运算类型   | 操作符                                       |
| ---------- | -------------------------------------------- |
| 算数运行   | +, -, *, /, %, ^, div, mod                   |
| 关系运算   | <, >, ==, !=, <=, >=, lt, gt, eq, ne, le, ge |
| 逻辑运算   | and, or, not, &&, \|\|, !                    |
| 条件运算   | ?:                                           |
| 正则表达式 | matches                                      |

具体的表达式使用参考:

[Spring Expression Language（SpEL）速查指南](https://cloud.tencent.com/developer/article/1362825)

[英文官方文档](https://docs.spring.io/spring-framework/docs/4.2.x/spring-framework-reference/html/expressions.html)

## 具体的场景

1. 告警规则的定义: 比如哪些参数组合得到的警告需要告警
2. 二值比较

1. 值的格式转换



通过该表达式来进行参数逻辑运算得到结果，结合一些策略模式会变得更灵活。

## 使用



通过一个测试用例来看最基本的使用

```java
StandardEvaluationContext ctx = new StandardEvaluationContext();

List<PropertyAccessor> propertyAccessors = new ArrayList<>();
propertyAccessors.add(new ReflectivePropertyAccessor());
propertyAccessors.add(new MapAccessor());
ctx.setPropertyAccessors(propertyAccessors);

Map<String, Object> variableMap = new HashMap<>();

LoginRequest loginRequest = new LoginRequest();
loginRequest.setUsername("lkx");
loginRequest.setPassword("123456");

variableMap.put("name", "某某某");
variableMap.put("sex", "男");
variableMap.put("like", "jay");

Map<String, Object> vMap = new HashMap<>();
vMap.put("obj", variableMap);
vMap.put("login", loginRequest); 

ExpressionParser parser = new SpelExpressionParser(); 

Expression expression =
    parser.parseExpression("${login.username == 'lkx' && login.password == '123456'}", templateParserContext);

String content = expression.getValue(ctx,vMap, String.class);

System.out.println(content);
```

- 设置好上下文的解析器
- 加载可见参数

- 通过表达式直接使用



## 流程介绍

>  可变参数 : 就是代表表达式中的变量的值，比如#{username} , 对应的可能就是你的Model或者Map中的属性，可能是对象，也可能是属性值。

### 1. EvaluationContext

可以理解为解析器的上下文，通过上下文的定义让解析器根据上下文的定义能够识别解析的内容。

标准的解析器 : `StandardEvaluationContext `

他是构建解析器的载体

- *PropertyAccessor* : 属性访问解析器，加入你的对象是Map请加入`MapAccessor`解析,如果是普通实体对象请加入`ReflectivePropertyAccessor`，不过这个是默认值。
- *ConstructorResolver*  : 构造器访问解析器

- *MethodResolver* : 方法解析器
- *BeanResolver*  : 解析器

等等；



### 2. SpelExpressionParser

具体的解析器，负责将表达式解析成Expression对象。

可以理解成比如`${obj.name}` 将这个表达式拆解成

- ${
- name
- }

这三个属性每个属性会对应着一个解析对象，name为关键字，会拿该值去可见参数中获取。



核心关键源码: 

- Expression expression = parser.parseExpression(expressionStr, templateParserContext);
  - org.springframework.expression.spel.standard.InternalSpelExpressionParser#doParseExpression

```java
protected SpelExpression doParseExpression(String expressionString, @Nullable ParserContext context)
    throws ParseException {

    try {
        // 1. 保存原始字符串
        this.expressionString = expressionString;
        // 2. 将字符串进行拆分
        Tokenizer tokenizer = new Tokenizer(expressionString);
        // 3. 对每一个字符进行拆解，与TokenKind中的枚举进行匹配
        this.tokenStream = tokenizer.process();
        this.tokenStreamLength = this.tokenStream.size();
        this.tokenStreamPointer = 0;
        this.constructedNodes.clear();
        // 4. 第三步已经为每个字符打了标记，这个时候需要根据标记绑定对应的SpelNodeImpl解析器
        SpelNodeImpl ast = eatExpression();
        Assert.state(ast != null, "No node");
        Token t = peekToken();
        if (t != null) {
            throw new SpelParseException(t.startPos, SpelMessage.MORE_INPUT, toString(nextToken()));
        }
        Assert.isTrue(this.constructedNodes.isEmpty(), "At least one node expected");
        return new SpelExpression(expressionString, ast, this.configuration);
    }
    catch (InternalParseException ex) {
        throw ex.getCause();
    }
}
```

最终这里会返回一个`SpelExpression`对象，这个对象实现了Expression接口，也就相当于返回Expression对象。



如果该对象的解析器不只一个，那么会将这些解析器组合成`CompositeStringExpression`，最终通过Expression的`getValue`方法，依次遍历解析器进行计算之后得到最终的值。



需要注意的是顺序问题，由于解析器默认就已经将优先级最高的处理在最前面了。所以不会出现类似于加法计算