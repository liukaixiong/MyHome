# 常用的SQL

## 查询所有表根据数据量排行

```sql
SELECT 
    table_name, 				-- 表名
    table_rows,					-- 表的行数
	table_comment,				-- 表的描述
	CREATE_TIME,				-- 这个表的创建时间
	AVG_ROW_LENGTH ,			-- 平均每行的长度
	DATA_LENGTH,				-- 这个表的大小长度
	INDEX_LENGTH,				-- 这个表的索引长度
	DATA_FREE,					-- 这个表的可用空间
	AUTO_INCREMENT				-- 表的自增值
FROM `information_schema`.`tables` WHERE TABLE_SCHEMA = 'marketing_db' ORDER BY table_rows DESC;
```

## 查询表结构、字段

```sql
-- 查看表字段
show columns from sms_log;
-- 查看建表语句
show create table sms_log;
```

