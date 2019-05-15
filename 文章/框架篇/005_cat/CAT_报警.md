# CAT报警模块整理

## 步骤

1. 配置页面

   1. 服务端配置

      1. send-machine/alarm-machine设置为true。

   2. 告警策略

      1. 设置告警要发送的消息类型

   3. 默认告警人

      1. 这里需要指定要发送的联系人方式，这里需要注意的是假设你没有配置对应的消息类型的告警联系人，该类型的消息将不会被发送。

      **这里需要注意，你如果定义的是Transaction异常，需要先在默认告警人进行指定，不然会找不到接受人**

      ```xml
       <receiver id="Transaction" enable="true">
            <email>testUser1@test.com</email>
            <phone>12345678901</phone>
            <phone>12345678902</phone>
      </receiver>
      ```

        

      如果你发不出去，又不确定是不是默认告警人没配置好，可以去CAT中的Event页面进行查看，它在这里进行了打点，点的名称叫 `NoneReceiver:MAIL`，MAIL代表发送的类型，里面会列出找不到接受人的列表

   4. 告警服务端

      1. 这里需要配置你后端的配置地址，这里的参数可以自定义。
      2. successCode这里的返回是包含的意思,就是你返回的值只要出现successCode等于的值就表示发送成功。



## 