1. - ## JDBCTemplate基本架构组图
     ![image.png](http://upload-images.jianshu.io/upload_images/6370985-701a13ddcb4e8e74.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

     ### JDBCOperations
     定义jdbc操作数据的常用接口.里面包含查询、增加、修改、删除等等一系列的操作，而JdbcTemplate则是实现这里面的所有方法，客户端调用到的也是相关的操作信息
     ### JdbcAccessor
     这一个类则实现了操作jdbc的一些规范，比如数据源的设置、是否懒加载。将jdbc中配置的数据源放入jdbcTemplate就可以任意的操作相关的方法。

     #### JdbcTemplate是如何操作数据库的？

     首先需要为大家介绍一个接口类?
     1. RowMapper
       - 作用:
         1. 处理每个resultSet对象,行级别处理
     - 它所实现的子类：

       1. 主要介绍三个
           1. SingleColumnRowMapper
             处理单列结果内容,比如查询的聚合函数等等,count(),sum();
           2. ColumnMapRowMapper
             处理返回结果为map的内容;
           3. BeanPropertyRowMapper
             处理返回结果为实体对象的实现操作;
     2. ResultSetExtractor
       - 作用:
         处理每个返回结果类型的接口
       - 子类:

       着重介绍两个
                   1. SqlRowSetResultSetExtractor
                      	返回一个SqlRowSet对象的结果集
                   2.  RowMapperResultSetExtractor
                     	        返回一个任意对象(Map、Model)


     1. 查询
         - Map结果:
           1. 	默认的结果参数处理类是: ColumnMapRowMapper
             2.默认的结果处理类是: RowMapperResultSetExtractor
             -Object结果:
             1.默认的结果处理类是: BeanPropertyRowMapper
             2.默认的结果处理类是: RowMapperResultSetExtractor
             -SqlRowSet结果
             1.默认的结果处理类是: SqlRowSetResultSetExtractor
             2.优化查询的几种方式:
             -如果是返回结果类型是对象
             1.则可以在反射的地方进行优化
             2.可以暴露一个接口,然后客户方自己手动设置值,便可以省去不少值
             -设置一个PreparedStatement对象的fetchsize值为Integer.MIN_VALUE,必须在查询之前.