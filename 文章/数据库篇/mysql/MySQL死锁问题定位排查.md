---
typora-copy-images-to: ./
typora-root-url: img
---



# MySQL死锁问题定位排查

## 异常原因

```tex
 org.springframework.dao.DeadlockLoserDataAccessException: PreparedStatementCallback; SQL [ insert into customer_source (house_id,creator,ref_user_id,created,mobile,channel,ref_mobile,source,regist_time,sign_status,updator,id,updated,status) values ( ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? )]; Deadlock found when trying to get lock; try restarting transaction; nested exception is com.mysql.jdbc.exceptions.jdbc4.MySQLTransactionRollbackException: Deadlock found when trying to get lock; try restarting transaction 
```

最近线上出现了一次死锁的异常，由于之前没有经验，排查中遇到的问题以及手段记录下来，方便下次追查。

### 如何定位死锁?

Mysql中提供了最近一次死锁出现的语句。

```sql
show engine innodb status;
```

通过这个语句可以得到如下信息:[由于内容较多，只选举较重要的]

```tex
=====================================
2019-08-09 16:50:53 2ad9fabce700 INNODB MONITOR OUTPUT
=====================================
------------------------
LATEST DETECTED DEADLOCK
------------------------
2019-08-09 14:32:04 2ad966d44700
*** (1) TRANSACTION:
TRANSACTION 12615038, ACTIVE 0.393 sec inserting
mysql tables in use 1, locked 1
LOCK WAIT 4 lock struct(s), heap size 1184, 2 row lock(s), undo log entries 2
LOCK BLOCKING MySQL thread id: 9830283 block 9834936
MySQL thread id 9834936, OS thread handle 0x2ad968840700, query id 343309698 172.19.189.120 dmmanager update
insert into customer_xxxx (house_id,creator,ref_user_id,created,mobile,channel,ref_mobile,source,regist_time,sign_status,updator,id,updated,status) values ( 10118 ,  '203295' ,  186063 ,  '2019-08-09 14:32:03.859' ,  '156xxxxxxx' ,  'xxxx推广吴迪(xxxxx)' ,  'xxxxxxx' ,  3 ,  '2019-08-09 14:32:03' ,  0 ,  null ,  null ,  null ,  1 )
*** (1) WAITING FOR THIS LOCK TO BE GRANTED:
RECORD LOCKS space id 2648 page no 1228 n bits 568 index `idx_houseId_mobile` of table `marketing_db`.`customer_source` trx id 12615038 lock mode S waiting
Record lock, heap no 502 PHYSICAL RECORD: n_fields 3; compact format; info bits 0
 0: len 5; hex 3130313138; asc 10118;;
 1: len 11; hex 3135363430333236323230; asc 15640326220;;
 2: len 4; hex 80018b18; asc     ;;

*** (2) TRANSACTION:
TRANSACTION 12615033, ACTIVE 0.410 sec fetching rows
mysql tables in use 1, locked 1
522 lock struct(s), heap size 63016, 4 row lock(s), undo log entries 4
MySQL thread id 9830283, OS thread handle 0x2ad966d44700, query id 343309767 172.19.189.120 dmmanager Searching rows for update
update user_invitation set  invite_user_mobile = '156xxxxxxx'
        where invite_user_id = 203295 and beinvited_user_channel = '个人-未知号码'
*** (2) HOLDS THE LOCK(S):
RECORD LOCKS space id 2648 page no 1228 n bits 568 index `idx_houseId_mobile` of table `marketing_db`.`customer_source` trx id 12615033 lock_mode X locks rec but not gap
Record lock, heap no 502 PHYSICAL RECORD: n_fields 3; compact format; info bits 0
 0: len 5; hex 3130313138; asc 10118;;
 1: len 11; hex 3135363430333236323230; asc 15640326220;;
 2: len 4; hex 80018b18; asc     ;;

*** (2) WAITING FOR THIS LOCK TO BE GRANTED:
RECORD LOCKS space id 2484 page no 930 n bits 160 index `PRIMARY` of table `marketing_db`.`user_invitation` trx id 12615033 lock_mode X locks rec but not gap waiting
Record lock, heap no 91 PHYSICAL RECORD: n_fields 22; compact format; info bits 0

```

从如下信息可以得到较重要的信息: 

两个冲突的语句:

```sql
insert into customer_source (house_id,creator,ref_user_id,created,mobile,channel,ref_mobile,source,regist_time,sign_status,updator,id,updated,status) values ( 10118 ,  '203295' ,  186063 ,  '2019-08-09 14:32:03.859' ,  '156xxxxxxx' ,  'xxxx推广吴迪(xxxxx)' ,  'xxxxxxx' ,  3 ,  '2019-08-09 14:32:03' ,  0 ,  null ,  null ,  null ,  1 )
```

```sql
update user_invitation set  invite_user_mobile = '156xxxxxxx'
        where invite_user_id = 203295 and beinvited_user_channel = '个人-未知号码'
```

冲突的索引 : `idx_houseId_mobile` 、`PRIMARY`

**得到这两个信息的时候，我们需要知道在执行这两条语句的时候的业务流程是如何？**

![1565342244978](/../1565342244978.png)

从上面的日志分析来看：

由于customer_source 的索引中包含手机号，而user_invitation也包含和customer_source 一样的手机号，这时候虽然是两个不同的表，但是在抢占锁数据的时候起了冲突。

首先: 

1. 线程A抢占了customer_source表中156xxxxxxx这部分数据A
2. 线程B抢占了user_invitation表中156xxxxxxx这部分数据B。
3. 线程A需要修改表`user_invitation`这个手机号相关的数据，但这部分数据的锁被线程B持有，所以它阻塞等待线程B释放。
4. 线程B这时候执行到第四部要插入手机号这个数据的时候，发现线程A正在修改这部分数据并持有了锁，原本需要阻塞等待A释放，但这时候A也在等B便造成了死锁异常，事务回滚释放。
5. 线程A检测到B释放了锁，便继续下面步骤提交了事务。



解决思路: 

1. 调整业务顺序。
2. 如果有消息队列看是否能够使用。