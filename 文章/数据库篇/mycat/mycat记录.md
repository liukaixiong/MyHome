#  mycat 使用记录

## 资料文件:

github : https://github.com/MyCATApache/Mycat-Server/wiki

操作类: http://songwie.com/teachs?searthstr=Mycat&start=0&limit=100

下载包: http://dl.mycat.io/

web监控平台：http://dl.mycat.io/mycat-web-1.0/

## 基本操作

###  启动服务

`../bin/startup_nowrap.bat`

### 连接mycat 

linux : `mysql -uroot -proot -P8066 -h127.0.0.1`

windows: 和上面差不多



## 目录介绍

`bin` : 启动文件

`conf` : 配置文件存放配置文件

- `server.xml` : 是Mycat服务器参数调整和用户授权的配置文件。帐号密码也包含在里面
- `schema.xml` : 是逻辑库定义和表以及分片定义的配置文件。对数据库的逻辑操作都是在里面定义
- `rule.xml`:  是分片规则的配置文件，分片规则的具体一些参数信息单独存放为文件，也在这个目录下，配置文件修改需要重启MyCAT。
- `log4j.xml` : 日志存放在logs/log中，每天一个文件，日志的配置是在conf/log4j.xml中，根据自己的需要可以调整输出级别为debug ,**debug级别下，会输出更多的信息，方便排查问题。**
- `autopartition-long.txt`,`partition-hash-int.txt`,`sequence_conf.properties`， `sequence_db_conf.properties` 分片相关的id分片规则配置文件`
- `lib` ：  MyCAT自身的jar包或依赖的jar包的存放目录。
- `logs`：MyCAT日志的存放目录。日志存放在logs/log中，每天一个文件




### **schema.xml**:

```xml
<mycat:schema xmlns:mycat="http://io.mycat/">

  	<!-- -------------------------mycat的DB层面设置---------------------- -->
  	<!-- “checkSQLschema”：描述的是当前的连接是否需要检测数据库的模式 -->
  	<!-- “sqlMaxLimit”：表示返回的最大的数据量的行数 -->
  	<!-- “dataNode="dn1"”：该操作使用的数据节点是dn1的逻辑名称 -->
	<schema name="TESTDB" checkSQLschema="false" sqlMaxLimit="100">
		<!-- auto sharding by id (long) -->
		<table name="travelrecord" dataNode="dn1,dn2,dn3" rule="auto-sharding-long" />

		<!-- global table is auto cloned to all defined data nodes ,so can join
			with any table whose sharding node is in the same data node -->
      	<!-- 同步到三个节点 --> 
      	<!-- table 表名-->
      	<!-- primaryKey 主键 -->
        <!-- type 类型 global 全局 -->
      	<!-- dataNode 范围节点 代表表对应的分片-->
      	<!-- 
     	 rule 代表表要采用的数据切分方式，名称对应到rule.xml中的对应配置，如果要分片必须配置。			-->	
      	<!-- childTable 主子表对应关系,适合在join的时候,表不在一个分片上 -->
		<table name="company" primaryKey="ID" type="global" dataNode="dn1,dn2,dn3" />
      	<!-- 同步到两个库中 -->
		<table name="goods" primaryKey="ID" type="global" dataNode="dn1,dn2" />
		<!-- random sharding using mod sharind rule --> 
      	<!-- autoIncrement 取模划分到指定库 -->
		<table name="hotnews" primaryKey="ID" autoIncrement="true" dataNode="dn1,dn2,dn3"
			   rule="mod-long" /> 
      	<!-- 通过intfile切分 -->
		<table name="employee" primaryKey="ID" dataNode="dn1,dn2"
			   rule="sharding-by-intfile" />
      	
      <!-- 这里面的意思是 -->
      <!-- 
			1. 首先customer表会根据sharding-by-intfile里面的分片数决定放到那个库中
			2. 然后orders表关联的customer_id在插入的时候就决定了这个order数据会被关联到哪个库中
			3. 下面的也是一样
		其实就是说customer_id落在哪个库,下面关联的数据也会落到哪个库
		-->
		<table name="customer" primaryKey="ID" dataNode="dn1,dn2"
			   rule="sharding-by-intfile">
			<childTable name="orders" primaryKey="ID" joinKey="customer_id"
						parentKey="id">
				<childTable name="order_items" joinKey="order_id"
							parentKey="id" />
			</childTable>
			<childTable name="customer_addr" primaryKey="ID" joinKey="customer_id"
						parentKey="id" />
		</table>
		 
	</schema> 
  
  
  	<!-- -----------------mycat和mysql之间的关系配置------------------------ -->
  	<!-- “dataHost="localhost1"”：定义数据节点的逻辑名称 -->
  	<!-- “database="test"”：定义数据节点要使用的数据库名称 -->
	<dataNode name="dn1" dataHost="localhost1" database="mycat1" />
	<dataNode name="dn2" dataHost="localhost1" database="mycat2" />
	<dataNode name="dn3" dataHost="localhost1" database="mycat3" />
  
  
  	<!-- ----------------mysql之间的关系配置--------------------------- -->
  	<!-- 定义数据节点，包括了各种逻辑项的配置 -->
  	<!-- 
        minCon : 指定每个读写实例连接池的最大连接。
        minCon : 指定每个读写实例连接池的最小连接。
		balance: 负载均衡类型，目前的取值有4种：  
			0 : 不开启读写分离机制，所有读操作都发送到当前可用的writeHost上。
			1 : 所有读操作都随机的发送到readHost。全部的readHost与stand by writeHost参与select语句的负载均衡，简单的说，当双主双从模式(M1->S1，M2->S2，并且M1与 M2互为主备)，正常情况下，M2,S1,S2都参与select语句的负载均衡。
			2 : 所有读操作都随机的在writeHost、readhost上分发。
			3 : 所有读请求随机的分发到wiriterHost对应的readhost执行，writerHost不负担读压力
		writeType:
			0:所有写操作发送到配置的第一个writeHost，第一个挂了切到还生存的第二个writeHost，重新启动后已切换后的为准，切换记录在配置文件中:dnindex.properties.
			1:所有写操作都随机的发送到配置的writeHost，1.5以后废弃不推荐。
			2:不执行写操作
		switchType 指的是切换的模式，目前的取值也有4种 :
			-1:表示不自动切换
			1:默认值，表示自动切换
			2: 基于MySQL主从同步的状态决定是否切换,心跳语句为 show slave status
			3: 基于MySQL galary cluster的切换机制（适合集群）（1.4.1），心跳语句为 show status like 'wsrep%
		dbType属性: 指定后端连接的数据库类型，目前支持二进制的mysql协议，还有其他使用JDBC连接的数据库。例如：MongoDB、Oracle、Spark等。
		heartbeat标签: 这个标签内指明用于和后端数据库进行心跳检查的语句。例如,MYSQL可以使用select user()，oracle可以使用select 1 from dual等。这个标签还有一个connectionInitSql属性，主要是当使用Oracla数据库时，需要执行的初始化SQL语句就这个放到这里面来。例如：alter session set nls_date_format='yyyy-mm-dd hh24:mi:ss'
		slaveThreshold: switchType="2" 与 slaveThreshold="100"，此时意味着开启MySQL主从复制状态绑定的读写分离与切换机制，MyCat心跳机制通过检测 show slave status 中的 
"Seconds_Behind_Master", "Slave_IO_Running", "Slave_SQL_Running" 三个字段来确定当前主从同步的状态以及Seconds_Behind_Master主从复制时延，当Seconds_Behind_Master 大于slaveThreshold时，读写分离筛选器会过滤掉此Slave机器，防止读到很久之前的旧数据，而当主节点宕机后，切换逻辑会检查Slave上的Seconds_Behind_Master是否为0，为0时则表示主从同步，可以安全切换，否则不会切换。
	-->
	<dataHost name="localhost1" maxCon="1000" minCon="10" balance="0"
			  writeType="0" dbType="mysql" dbDriver="native" switchType="1"  slaveThreshold="100">
		<heartbeat>select user()</heartbeat>
		<!-- can have multi write hosts -->
		<writeHost host="hostM1" url="127.0.0.1:3306" user="root"
				   password="1234">
			<!-- can have multi read hosts -->
			<readHost host="hostS2" url="127.0.0.1:3306" user="root" password="1234" />
		</writeHost>
		<writeHost host="hostS1" url="127.0.0.1:3306" user="root"
				   password="1234" />
	</dataHost> 
</mycat:schema>
```



#### 通配符

##### table节点的dataNode属性

```xml
<table name="offer" dataNode="offer_dn$1-3" rule="offerRule" />
其中的offer_dn$0-3等价于offer_dn1，offer_dn2，offer_dn3共3个节点
```



##### dataNode节点的通配配置

1. 同一个dataHost上有多个database

```xml
<dataNode name="dn$1-3" dataHost="test1" database="base$1-3" />
等价于3个dataNode节点，其中name和database中的通配数量必须相等。
<dataNode name="dn1" dataHost="test1" database="base1" />
<dataNode name="dn2" dataHost="test1" database="base2" />
<dataNode name="dn3" dataHost="test1" database="base3" />
```

2. 多个dataHost上有相同的database

```xml
<dataNode name="dn$1-3" dataHost="test$1-3" database="base" />
等价于3个节点，其中name和dataHost中的通配数量必须相等。
<dataNode name="dn1" dataHost="test1" database="base" />
<dataNode name="dn2" dataHost="test2" database="base" />
<dataNode name="dn3" dataHost="test3" database="base" />
```

3. 多个dataHost上有相同的多个database

```xml
<dataNode name="dn$1-6" dataHost="test$1-3" database="base$1-2" />
等价于6个节点，有3个dataHost，每个dataHost上都有2个database 。
其中name的通配数量必须等于datahost数量乘以database数量
<dataNode name="dn1" dataHost="test1" database="base1" />
<dataNode name="dn2" dataHost="test1" database="base2" />
<dataNode name="dn3" dataHost="test2" database="base1" />
<dataNode name="dn4" dataHost="test2" database="base2" />
<dataNode name="dn5" dataHost="test3" database="base1" />
<dataNode name="dn6" dataHost="test3" database="base2" />
```



### server.xml







##  **常用的水平分库**

### 求模分库 

 `mod-long`

通过在配置文件中配置可能的枚举id，自己配置分片，使用规则：

```xml
<tableRule name="mod-long">
    <rule>
      <columns>user_id</columns>
      <algorithm>mod-long</algorithm>
    </rule>
  </tableRule>
  <function name="mod-long" class="org.opencloudb.route.function.PartitionByMod">
   <!-- how many data nodes  -->
    <property name="count">3</property>
  </function> 
配置说明：
上面columns 标识将要分片的表字段，algorithm 分片函数，
此种配置非常明确即根据id进行十进制求模预算，相比方式1，此种在批量插入时需要切换数据源，id不连续
```





### **范围分库**

`auto-sharding-long`

```XML
<tableRule name="auto-sharding-long">
    <rule>
      <columns>user_id</columns>
      <algorithm>rang-long</algorithm>
    </rule>
  </tableRule>
<function name="rang-long" class="org.opencloudb.route.function.AutoPartitionByLong">
    <property name="mapFile">autopartition-long.txt</property>
  </function>
# range start-end ,data node index
# K=1000,M=10000.
0-500M=0
500M-1000M=1
1000M-1500M=2
或
0-10000000=0
10000001-20000000=1
```

```Tex
上面columns标识将要分片的表字段，algorithm 分片函数，

rang-long 函数中mapFile代表配置文件路径

所有的节点配置都是从0开始，及0代表节点1，此配置非常简单，即预先制定可能的id范围到某个分片

```







### **Hash分库**

`hash-int` 

### **月分库**

`sharding-by-month`

### **天分库** 

 `sharding-by-date` 

```xml
<tableRule name="sharding-by-date">
      <rule>
        <columns>create_time</columns>
        <algorithm>sharding-by-date</algorithm>
      </rule>
   </tableRule>  
<function name="sharding-by-date" class="org.opencloudb.route.function.PartitionByDate">
    <property name="dateFormat">yyyy-MM-dd</property>
    <property name="sBeginDate">2014-01-01</property>
    <property name="sPartionDay">10</property>
  </function>
配置说明：
上面columns 标识将要分片的表字段，algorithm 分片函数，
配置中配置了开始日期，分区天数，即默认从开始日期算起，分隔10天一个分区

Assert.assertEquals(true, 0 == partition.calculate("2014-01-01"));
Assert.assertEquals(true, 0 == partition.calculate("2014-01-10"));
Assert.assertEquals(true, 1 == partition.calculate("2014-01-11"));
Assert.assertEquals(true, 12 == partition.calculate("2014-05-01"));

```







### **ER模型分库**：`childTable`

### **枚举法** 

 `sharding-by-intfile`

### **固定分片Hash算法** 

`rule1`

```xml
<tableRule name="rule1">
    <rule>
      <columns>user_id</columns>
      <algorithm>func1</algorithm>
    </rule>
</tableRule>

  <function name="func1" class="org.opencloudb.route.function.PartitionByLong">
    <property name="partitionCount">2,1</property>
    <property name="partitionLength">256,512</property>
  </function>

```

```tex
上面columns 标识将要分片的表字段，algorithm 分片函数，
partitionCount 分片个数列表，partitionLength 分片范围列表
分区长度:默认为最大2^n=1024 ,即最大支持1024分区
约束 :
count,length两个数组的长度必须是一致的。
1024 = sum((count[i]*length[i])). count和length两个向量的点积恒等于1024
用法例子：
        本例的分区策略：希望将数据水平分成3份，前两份各占25%，第三份占50%。（故本例非均匀分区）
        // |<---------------------1024------------------------>|
        // |<----256--->|<----256--->|<----------512---------->|
        // | partition0 | partition1 | partition2 |
        // | 共2份,故count[0]=2 | 共1份，故count[1]=1 |
        int[] count = new int[] { 2, 1 };
        int[] length = new int[] { 256, 512 };
        PartitionUtil pu = new PartitionUtil(count, length);

        // 下面代码演示分别以offerId字段或memberId字段根据上述分区策略拆分的分配结果
        int DEFAULT_STR_HEAD_LEN = 8; // cobar默认会配置为此值
        long offerId = 12345;
        String memberId = "qiushuo";

// 若根据offerId分配，partNo1将等于0，即按照上述分区策略，offerId为12345时将会被分配到partition0中
        int partNo1 = pu.partition(offerId);

// 若根据memberId分配，partNo2将等于2，即按照上述分区策略，memberId为qiushuo时将会被分到partition2中
        int partNo2 = pu.partition(memberId, 0, DEFAULT_STR_HEAD_LEN);

如果需要平均分配设置：平均分为4分片，partitionCount*partitionLength=1024
<function name="func1" class="org.opencloudb.route.function.PartitionByLong">
    <property name="partitionCount">4</property>
    <property name="partitionLength">256</property>
</function>

```



### **自定义分库**

`CustomRule`

### **通配取模** 

`sharding-by-pattern`

```xml
<tableRule name="sharding-by-pattern">
      <rule>
        <columns>user_id</columns>
        <algorithm>sharding-by-pattern</algorithm>
      </rule>
   </tableRule>
<function name="sharding-by-pattern" class="org.opencloudb.route.function.PartitionByPattern">
    <property name="patternValue">256</property>
    <property name="defaultNode">2</property>
    <property name="mapFile">partition-pattern.txt</property>

  </function>
partition-pattern.txt 
# id partition range start-end ,data node index
###### first host configuration
1-32=0
33-64=1
65-96=2
97-128=3
######## second host configuration
129-160=4
161-192=5
193-224=6
225-256=7
0-0=7

配置说明：
上面columns 标识将要分片的表字段，algorithm 分片函数，patternValue 即求模基数，defaoultNode 默认节点，如果配置了默认，则不会按照求模运算
mapFile 配置文件路径
配置文件中，1-32 即代表id%256后分布的范围，如果在1-32则在分区1，其他类推，如果id非数据，则会分配在defaoultNode 默认节点

String idVal = "0";
Assert.assertEquals(true, 7 == autoPartition.calculate(idVal));
idVal = "45a";
Assert.assertEquals(true, 2 == autoPartition.calculate(idVal));

```

### **ASCII码求模通配**

 `sharding-by-prefixpattern`

```xml
<tableRule name="sharding-by-prefixpattern">
      <rule>
        <columns>user_id</columns>
        <algorithm>sharding-by-prefixpattern</algorithm>
      </rule>
   </tableRule>
<function name="sharding-by-pattern" class="org.opencloudb.route.function.PartitionByPattern">
    <property name="patternValue">256</property>
    <property name="prefixLength">5</property>
    <property name="mapFile">partition-pattern.txt</property>
  </function>
partition-pattern.txt
# range start-end ,data node index
# ASCII
# 48-57=0-9
# 64、65-90=@、A-Z
# 97-122=a-z
###### first host configuration
1-4=0
5-8=1
9-12=2
13-16=3
###### second host configuration
17-20=4
21-24=5
25-28=6
29-32=7
0-0=7
配置说明：
上面columns 标识将要分片的表字段，algorithm 分片函数，patternValue 即求模基数，prefixLength ASCII 截取的位数
mapFile 配置文件路径
配置文件中，1-32 即代表id%256后分布的范围，如果在1-32则在分区1，其他类推 

此种方式类似方式6只不过采取的是将列种获取前prefixLength位列所有ASCII码的和进行求模sum%patternValue ,获取的值，在通配范围内的
即 分片数，
/**
* ASCII编码：
* 48-57=0-9阿拉伯数字
* 64、65-90=@、A-Z
* 97-122=a-z
*/
如 
String idVal="gf89f9a";
Assert.assertEquals(true, 0==autoPartition.calculate(idVal));

idVal="8df99a";
Assert.assertEquals(true, 4==autoPartition.calculate(idVal));

idVal="8dhdf99a";
Assert.assertEquals(true, 3==autoPartition.calculate(idVal));
```



### **编程指定**

 `sharding-by-substring`

```xml
<tableRule name="sharding-by-substring">
      <rule>
        <columns>user_id</columns>
        <algorithm>sharding-by-substring</algorithm>
      </rule>
   </tableRule>
<function name="sharding-by-substring" class="org.opencloudb.route.function.PartitionDirectBySubString">
    <property name="startIndex">0</property> <!-- zero-based -->
    <property name="size">2</property>
    <property name="partitionCount">8</property>
    <property name="defaultPartition">0</property>
  </function>
配置说明：
上面columns 标识将要分片的表字段，algorithm 分片函数 
此方法为直接根据字符子串（必须是数字）计算分区号（由应用传递参数，显式指定分区号）。
例如id=05-100000002
在此配置中代表根据id中从startIndex=0，开始，截取siz=2位数字即05，05就是获取的分区，如果没传默认分配到defaultPartition

```



### **字符串拆分hash解析**

`sharding-by-stringhash`

```xml
<tableRule name="sharding-by-stringhash">
      <rule>
        <columns>user_id</columns>
        <algorithm>sharding-by-stringhash</algorithm>
      </rule>
   </tableRule>
<function name="sharding-by-substring" class="org.opencloudb.route.function.PartitionDirectBySubString">
    <property name=length>512</property> <!-- zero-based -->
    <property name="count">2</property>
    <property name="hashSlice">0:2</property>
  </function>
配置说明：
上面columns 标识将要分片的表字段，algorithm 分片函数 
函数中length代表字符串hash求模基数，count分区数，hashSlice hash预算位

即根据子字符串 hash运算

hashSlice ： 0 means str.length(), -1 means str.length()-1

/**
     * "2" -&gt; (0,2)<br/>
     * "1:2" -&gt; (1,2)<br/>
     * "1:" -&gt; (1,0)<br/>
     * "-1:" -&gt; (-1,0)<br/>
     * ":-1" -&gt; (0,-1)<br/>
     * ":" -&gt; (0,0)<br/>
     */
例子：
String idVal=null;
 rule.setPartitionLength("512");
 rule.setPartitionCount("2");
 rule.init();
 rule.setHashSlice("0:2");
//		idVal = "0";
//		Assert.assertEquals(true, 0 == rule.calculate(idVal));
//		idVal = "45a";
//		Assert.assertEquals(true, 1 == rule.calculate(idVal));
 //last 4
 rule = new PartitionByString();
 rule.setPartitionLength("512");
 rule.setPartitionCount("2");
 rule.init();
 //last 4 characters
 rule.setHashSlice("-4:0");
 idVal = "aaaabbb0000";
 Assert.assertEquals(true, 0 == rule.calculate(idVal));
 idVal = "aaaabbb2359";
 Assert.assertEquals(true, 0 == rule.calculate(idVal));

```

### **一致性hash**

```xml
<tableRule name="sharding-by-murmur">
  <rule>
    <columns>user_id</columns>
    <algorithm>murmur</algorithm>
  </rule>
</tableRule>
<function name="murmur" class="org.opencloudb.route.function.PartitionByMurmurHash">
      <property name="seed">0</property><!-- 默认是0-->
      <property name="count">2</property><!-- 要分片的数据库节点数量，必须指定，否则没法分片-->
      <property name="virtualBucketTimes">160</property><!-- 一个实际的数据库节点被映射为这么多虚拟节点，默认是160倍，也就是虚拟节点数是物理节点数的160倍-->
      <!--
      <property name="weightMapFile">weightMapFile</property>
                     节点的权重，没有指定权重的节点默认是1。以properties文件的格式填写，以从0开始到count-1的整数值也就是节点索引为key，以节点权重值为值。所有权重值必须是正整数，否则以1代替 -->
      <!--
      <property name="bucketMapPath">/etc/mycat/bucketMapPath</property>
                      用于测试时观察各物理节点与虚拟节点的分布情况，如果指定了这个属性，会把虚拟节点的murmur hash值与物理节点的映射按行输出到这个文件，没有默认值，如果不指定，就不会输出任何东西 -->
  </function>

一致性hash预算有效解决了分布式数据的扩容问题，前1-9中id规则都多少存在数据扩容难题，而10规则解决了数据扩容难点
```



**具体匹配规则**：

1. `auto-sharding-long`
2. 对应 `rule.xml` 中的 `rang-long` 
3. 又对应 `function`的`autopartition-long.txt`文件




## mycat-server

###  概念

> schema.xml 的配置会影响到mycat的库创建，例如里面的表，如果在db1、db2、db3的表在mysql中不存在，则会影响查询。
>
> **总结就是mycat里面的表，必须在mysql中存在。否则在mycat会查询报错。**
>
> 一旦上面没有配置好,会导致mycat非常卡



**如果有错误，则去查看日志。**



## 全局序列号配置

配置步骤:

1. 创建一个`mycat_sequence`表 ,这个表的脚本在`conf/dbseq.sql`中
2. `server.xml` 将 `sequnceHandlerType`设置为1 
3. `conf/sequence_db_conf`  中配置你的表创建的**库**的位置和类型,为`schema.xml`中引用做准备``
4. `schema.xml`：　<table> `autoIncrement`设置为true
5. 另外mysql中的表也需要设置为自增列

自增形式:

​	根据mycat_sequence表中的increment定义的值来判断每次获取多大的值.

​	例如 :  步长为5 当前值为1 取的时候会1-5的值取出来,并且修改表的当前值为6..

​		 通俗一点将就是一次性获取6个id,分配完了之后再获取.这是为了减少数据库的读取次数



## 读写分离配置

`schema.xml`

```xml
<dataHost name="localhost1" maxCon="1000" minCon="10" balance="0"
			  writeType="0" dbType="mysql" dbDriver="native" switchType="1"  slaveThreshold="100">
		<heartbeat>select user()</heartbeat>
		<!-- can have multi write hosts -->
		<writeHost host="hostM1" url="127.0.0.1:3306" user="root"
				   password="1234">
			<!-- can have multi read hosts -->
			<readHost host="hostS2" url="127.0.0.1:3306" user="root" password="1234" />
		</writeHost>
		<writeHost host="hostS1" url="127.0.0.1:3306" user="root"
				   password="1234" />
		<!-- <writeHost host="hostM2" url="localhost:3316" user="root" password="123456"/> -->
	</dataHost>
```

1. **设置 balance="1"与writeType="0"**

Balance参数设置：

- balance=“0”, 所有读操作都发送到当前可用的writeHost上。
- balance=“1”，所有读操作都随机的发送到readHost。
- balance=“2”，所有读操作都随机的在writeHost、readhost上分发

2. **WriteType**参数设置：

- writeType=“0”, 所有写操作都发送到可用的writeHost上。
- writeType=“1”，所有写操作都随机的发送到readHost。
- writeType=“2”，所有写操作都随机的在writeHost、readhost分上发。

 “readHost是从属于writeHost的，即意味着它从那个writeHost获取同步数据，因此，当它所属的writeHost宕机了，则它也不会再参与到读写分离中来，即“不工作了”，这是因为此时，它的数据已经“不可靠”了。基于这个考虑，目前mycat 1.3和1.4版本中，若想支持MySQL一主一从的标准配置，并且在主节点宕机的情况下，从节点还能读取数据，则需要在Mycat里配置为两个writeHost并设置banlance=1。”

3.  **设置switchType="2" 与slaveThreshold="100"**

“Mycat心跳检查语句配置为 show slave status ，dataHost 上定义两个新属性： switchType="2" 与slaveThreshold="100"，此时意味着开启MySQL主从复制状态绑定的读写分离与切换机制。Mycat心跳机制通过检测 show slave status 中的 "Seconds_Behind_Master", "Slave_IO_Running","Slave_SQL_Running" 三个字段来确定当前主从同步的状态以及Seconds_Behind_Master主从复制时延。“

## mycat-web

下载指定包

### 修改配置

`mycat-web\WEB-INF\classes`

- `jdbc.properties` : 修改数据库配置,脚本在(`mycat-web\WEB-INF\db`)
- `mycat.properties` : 修改zookeeper地址为`127.0.0.1`,并且需要启动`zookeeper`

启动`start.bat`,访问地址:`http://localhost:8082/mycat/`

