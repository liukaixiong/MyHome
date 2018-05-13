

## Jrebel 激活

问题：

码农日常中，热部署是必不可少的，而jrebel插件很好的实现热部署功能。

IDEA下载jrebel插件，可以免费试用15天，但之后就无法使用。因为Jrebel是收费的。

解决方法：

楼主也是百度了很多，得到了2种解决方法。这2种方法都可以，已亲测（第一个需要访问国外的网页，需要FQ，我是直接让国外的朋友帮我激活的，

所以这里没有细说，主要讲第二种方法）。

1.官网激活。地址https://my.jrebel.com，注意：在官网激活你需要有fackbook或者推特的账号，所以这个需要FQ。

2.破解Jrebel。

1）首先在github上下载一个exe文件，（用来破解jrebel）https://github.com/ilanyu/ReverseProxy/releases/tag/v1.0

![img](https://images2018.cnblogs.com/blog/1284995/201803/1284995-20180302163305120-993207302.png)

上图window 64系统的下载选择文件，大家可以根据系统自行选择下载。

2）双击运行下载的exe文件，出现如下图（不要关闭！）

![img](https://images2018.cnblogs.com/blog/1284995/201803/1284995-20180302163550336-816980355.png)

3）打开IDEA选择help-jrebel-activation，出现如下所示图片[img](https://images2018.cnblogs.com/blog/1284995/201803/1284995-20180302164156018-852807725.png)

选择Connect to License Server 输入：

http://127.0.0.1:8888/zsc

zsc@123.com



>  **zsc**必须要和邮箱**zsc**@123.com前缀保持一致



第二行http://127.0.0.1:8888/ 不变，zsc随意写，

第二行随意写个邮箱，格式正确即可。

然后点击确定按钮，激活成功！！！（此时，即可关闭exe窗口）



还有其他参考的文章:

[使用文档](http://wiki.jikexueyuan.com/project/intellij-idea-tutorial/jrebel-setup.html)

[内网搭建](https://blog.csdn.net/gsls200808/article/details/78785352)

