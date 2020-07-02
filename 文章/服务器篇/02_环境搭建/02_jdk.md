- 由于版权原因，Linux发行版并没有包含官方版的Oracle JDK，必须自己从官网上下载安装。Oracle官网用Cookie限制下载方式，使得眼下只能用浏览器进行下载，使用其他方式可能会导致下载失败。但还是有方法可以在Linux进行下载的，本文以wget为例。
- 我们需要三个参数：**–no-check-certificate、–no-cookies、–header**，通过`man wget`命令可以查到。
- **用于禁止检查证书**

```
--no-check-certificate
       Don't check the server certificate against the available certificate authorities.  Also don't require the URL host name to match the common name presented by the certificate.

       As of Wget 1.10, the default is to verify the server's certificate against the recognized certificate authorities, breaking the SSL handshake and aborting the download if the verification fails.  Although this provides more secure downloads, it does
       break interoperability with some sites that worked with previous Wget versions, particularly those using self-signed, expired, or otherwise invalid certificates.  This option forces an "insecure" mode of operation that turns the certificate
       verification errors into warnings and allows you to proceed.

       If you encounter "certificate verification" errors or ones saying that "common name doesn't match requested host name", you can use this option to bypass the verification and proceed with the download.  Only use this option if you are otherwise
       convinced of the site's authenticity, or if you really don't care about the validity of its certificate.  It is almost always a bad idea not to check the certificates when transmitting confidential or important data.123456789
```

- **用于禁用Cookies**

```
--no-cookies
       Disable the use of cookies.  Cookies are a mechanism for maintaining server-side state.  The server sends the client a cookie using the "Set-Cookie" header, and the client responds with the same cookie upon further requests.  Since cookies allow the
       server owners to keep track of visitors and for sites to exchange this information, some consider them a breach of privacy.  The default is to use cookies; however, storing cookies is not on by default.
1234
```

- **用于定义请求头信息**

```
--header=header-line
       Send header-line along with the rest of the headers in each HTTP request.  The supplied header is sent as-is, which means it must contain name and value separated by colon, and must not contain newlines.

       You may define more than one additional header by specifying --header more than once.

               wget --header='Accept-Charset: iso-8859-2' \
                    --header='Accept-Language: hr'        \
                      http://fly.srk.fer.hr/

       Specification of an empty string as the header value will clear all previous user-defined headers.

       As of Wget 1.10, this option can be used to override headers otherwise generated automatically.  This example instructs Wget to connect to localhost, but to specify foo.bar in the "Host" header:

               wget --header="Host: foo.bar" http://localhost/

       In versions of Wget prior to 1.10 such use of --header caused sending of duplicate headers.12345678910111213141516
```

- 接下来我们就可以用wget命令愉快的下载JDK了

  1. 首先我们要找到要下载JDK的URL地址，例如：<http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.rpm>。这个地址可以去Orcale的官网找到。

  2. http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html

  3. 通过wget命令下载：

     ```
     wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.rpm1
     ```

  4. JDK我一般放在/usr/java目录下，现在我们把下载的rpm文件挪过去：

     ```
     //创建目录
     mkdir /usr/java
     
     //把下载的rpm文件copy过去
     cp jdk-8u131-linux-x64.rpm /usr/java
     ```

  5. 添加执行权限:

     ```
     //进入目录
     mkdir cd /usr/java
     
     //添加可执行权限
     chmod +x jdk-8u101-linux-x64.rpm
     ```

  6. 执行rpm命令安装:

     ```
     //安装rpm软件包
     rpm -ivh jdk-8u101-linux-x64.rpm
     
     ```

  7. 查看是否安装成功：

     ```
     //查看java的版本信息
     java -version12
     ```

- 能够显示出版本信息就说明安装成功了。 
  java version “1.8.0_131” 
  Java(TM) SE Runtime Environment (build 1.8.0_131-b11) 
  Java HotSpot(TM) 64-Bit Server VM (build 25.131-b11, mixed mode)