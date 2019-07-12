

# WebSocket使用介绍

[测试环境demo](http://101.132.138.87:5556/index.html)

## 地址

**最终调用的路由举例**:ws://localhost:5556/gs-guide-websocket/449/dm5mdsvo/websocket

449 : 数字随机数

dm5mdsvo : 英文随机数

> 上面这两个参数可以根据业务情况填写，例如数字随机数可以填写用户编号，英文随机数填写用户名

| IP       | 服务器IP                      |
| -------- | ----------------------------- |
| 端口     | 5556                          |
| 路由地址 | /gs-guide-websocket/websocket |

## 类型

### CONNECT

在ws需要连接的时候发送的第一个连接类型的消息，也可以理解为登陆，需要带着标识这个用户的信息向服务器进行注册。

**这里列举一些必要参数**

| 字段名|描述 |
| ------------ | :--------------------------------------------------------- |
| username        | 用户名                                                     |
| password     | 密码，如果是小程序登录可以不填。                           |
| id           | 编号，可以用UUID，可以不填                                 |
| userId       | 用户编号。必填                                               |
| source       | 来源。例如小程序、APP。                                  |
| houseId      | 房源编号  必填                                           |
| channelGroup | 管道组，因为后期业务拓展后台服务需要根据各类事件进行区分。 |
| propertyMap  | 拓展字段，必须传递JSON字符串类型,可为空                    |
| token        | 已经登录过的用户，会生成一个token，如果有则带              |
| openId       | 微信授权之后的openid                                       |
| sendToUser | 上线下线通知某个用户 |
| sendToAllUser | 上线下线通知某个订阅组 |

**找到这个用户的方式是: houseId_userId ，例如私聊！**

**参考文本**

```json
["CONNECT\nusername:mylogin4B\npassword:mypasscode\nid:4B\nuserId:457\nsource:test\nhouseId:457\nchannelGroup:ws-test\npropertyMap:{\"testData\":\"测试数据啊\"}\naccept-version:1.1,1.0\nheart-beat:10000,10000\n\n\u0000"]
```

\n是分隔符。

### subscribe

订阅类型。这个类型表示这个用户需要订阅哪些操作，例如私密聊天，群聊等路由，后期好根据这些路由做特殊推送。由服务端推送给指定的订阅用户

#### /topic/userList

用户列表

```java
["SUBSCRIBE\nid:sub-0\ndestination:/topic/userList\n\n\u0000"]
```

#### /topic/allUser

群聊消息

["SUBSCRIBE\nid:sub-1\ndestination:/topic/allUser\n\n\u0000"]

#### /user/topic/allUser

单聊消息

["SUBSCRIBE\nid:sub-2\ndestination:/user/topic/allUser\n\n\u0000"]

### send

发送事件，主动向服务端推送一条消息，这条消息可以是推送给订阅用户的消息(需要用户先订阅指定路由,然后发送给指定路由,有服务端主动推送给订阅用户)，也可以是调用服务端接口的消息。

#### /ws/remote/invoke

向服务端发送一条调用接口的消息

这里涉及到的参数:

| project | 项目名称       |
| ------- | -------------- |
| method  | 方法类型       |
| path    | 路由地址       |
| body    | 请求参数[JSON] |

参考:

```java
["SEND\nproject:elab-marketing-user\nmethod:POST\npath:/enum/queryEnumList\nbody:{     \"houseId\":0,     \"name\":\"\",     \"type\":\"\" }\ndestination:/ws/remote/invoke\ncontent-length:61\n\n\"{     \\\"houseId\\\":0,     \\\"name\\\":\\\"\\\",     \\\"type\\\":\\\"\\\" }\"\u0000"]
```

## 接入介绍

## 后端

### 路由层   

websocket 会根据事件回调这里面的路由地址。

```java

import com.ecloud.common.dto.response.ResponseCommonModel;
import com.elab.marketing.commons.model.WSRequest;
import com.elab.marketing.commons.service.IWsService;
import com.elab.marketing.commons.utils.ResponseUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.List;

/**
 * 长连接回调的触发接口请求类
 *
 * @author : liukx
 * @create : 2018/12/20 10:49
 * @email : liukx@elab-plus.com
 */
@RestController
@RequestMapping("/ws")
public class WsServiceImpl {

    @Autowired(required = false)
    private List<IWsService> wsServices = new ArrayList<>();

    /**
     * 回调的连接事件
     *
     * @param request
     * @return
     */
    @RequestMapping(value = "/connect", method = RequestMethod.POST, produces = "application/json;charset=UTF-8")
    @ResponseBody
    public ResponseCommonModel connect(@RequestBody WSRequest request) {
        for (int i = 0; i < wsServices.size(); i++) {
            IWsService wsService = wsServices.get(i);
            if (wsService.isSubscription(request.getSubscription())) {
                ResponseCommonModel connect = wsService.connect(request);
                return connect;
            }
        }
        return ResponseUtils.trues();
    }

    /**
     * 回调的断开事件
     *
     * @param request
     * @return
     */
    @RequestMapping(value = "/disconnect", method = RequestMethod.POST, produces = "application/json;charset=UTF-8")
    @ResponseBody
    public ResponseCommonModel disconnect(@RequestBody WSRequest request) {
        for (int i = 0; i < wsServices.size(); i++) {
            IWsService wsService = wsServices.get(i);
            if (wsService.isSubscription(request.getSubscription())) {
                ResponseCommonModel connect = wsService.disconnect(request);
                return connect;
            }
        }
        return ResponseUtils.trues();
    }

    /**
     * 回调的消息事件
     *
     * @param request
     * @return
     */
    @RequestMapping(value = "/message", method = RequestMethod.POST, produces = "application/json;charset=UTF-8")
    @ResponseBody
    public ResponseCommonModel message(@RequestBody WSRequest request) {
        for (int i = 0; i < wsServices.size(); i++) {
            IWsService wsService = wsServices.get(i);
            if (wsService.isSubscription(request.getSubscription())) {
                ResponseCommonModel connect = wsService.message(request);
                return connect;
            }
        }
        return ResponseUtils.trues();
    }

    @RequestMapping(value = "/heartbeat", method = RequestMethod.POST, produces = "application/json;charset=UTF-8")
    @ResponseBody
    public ResponseCommonModel heartbeat(@RequestBody List<WSRequest> request) {
        for (int i = 0; i < wsServices.size(); i++) {
            IWsService wsService = wsServices.get(i);
            for (int j = 0; j < request.size(); j++) {
                if (wsService.isSubscription(request.get(j).getSubscription())) {
                    ResponseCommonModel connect = wsService.heartbeat(request);
                    return connect;
                }
            }
        }
        return ResponseUtils.trues();
    }
}

```

### 业务层

1. 实现**IWsService**接口的所有方法
2. 继承**WSServiceAdaptor**，根据业务需要重写其他方法

这里需要注意的是有一个**isSubscription**方法，这个方法代表着前端连接时候的绑定事件，也就是channelGroup，这个需要业务开始时候商量好，然后业务方根据这个channelGroup来判定是否属于自己这部分的业务。如果符合则返回true，不符合则false，而下面实现的事件则不会执行。

```java
@Override
public boolean isSubscription(String subscription) {
    if("IM".equals(subscription)){
        return true;
    }
    return false;
}
```

## 非后端

1. 首先根据各端情况先集成各端的SDK等等，需要能够连接ws类型的服务。
2. 调通了SDK之后，然后开始拿服务端的IP和端口路由进行设置。
3. 连通了服务端的IP之后，首先需要发送一个CONNECT类型的请求进行注册。
4. 注册完成了，然后再根据业务看是否需要订阅等等。
5. 参数都在上面，传值得按照上面写的案例参数进行传递，否则会出现问题。