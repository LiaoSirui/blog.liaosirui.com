本文档基于 TPC-H 测试 OLAP 负载性能

## 简介

TPC-H 是事务处理性能委员会（ Transaction Processing Performance Council ）制定的基准程序之一，TPC- H 主要目的是评价特定查询的决策支持能力，该基准模拟了决策支持系统中的数据库操作，测试数据库系统复杂查询的响应时间，以每小时执行的查询数(TPC-H QphH@Siz)作为度量指标。

用于进行并行查询（OLAP）测试，以评估商业分析中决策支持系统（DSS）的性能。它包含了一整套面向商业的ad-hoc查询和并发数据修改，强调测试的是数据库、平台和I/O性能，关注查询能力。

TPC-H基准模型中定义了一个数据库模型，容量可以在1GB~10000GB的8个级别中进行选择。数据库模型包括CUSTOMER、LINEITEM、NATION、ORDERS、PART、PARTSUPP、REGION和SUPPLIER 8张数据表，涉及22条复杂的select查询流语句和2条带有insert和delete程序段的更新流语句。

测试分为Power测试和Throughout测试两种类型

* Power 测试是随机执行 22 条查询流中的一条测试流和 2 条更新流中的一条测试流，考核指标为 QppH@Size；
* Throughout 测试执行的是多条查询流和一条更新流对数据库的混合操作，考核指标是QthH@Size

Power测试和Throughout测试通过数理方式合成的结果为TPC-H基准测试中最关键的一项指标：每小时数据库查询数(QphH@Size)，是QppH@Size和QthH@Size结果的乘积的1/2次方。

## 相关链接

* tpch下载地址（TPC-H 需要完成注册后才可以下载）：https://www.tpc.org/tpc_documents_current_versions/download_programs/tools-download-request5.asp?bm_type=TPC-H&bm_vers=3.0.1&mode=CURRENT-ONLY

* tpch工具github仓库地址：https://github.com/electrum/tpch-dbgen

* 参考阿里云tpch工具使用：https://help.aliyun.com/document_detail/146099.html?spm=a2c4g.11186623.6.773.4797364bCS7aO5

## 部署 MySQL

建议Pod资源配置：

CPU： 2GHz （2000m）

建议配置

```
[mysqld]
innodb_buffer_pool_size=2G  # 缓存池大小 50%的内存
sql_mode=  # 取消主键限制
max_connections=1000   # 最大连接数
lower_case_table_names = 1  # 取消表字段大小写敏感
```

查看配置是否生效

```
show variables like 'innodb_buffer_pool_size';
show variables like 'sql_mode';
show variables like 'max_connections';
show variables like 'lower_case_table_names';
show variables like 'local_infile';
```

结果：

```
 MySQL  mysql-innodbcluster:3306 ssl  SQL > show variables like 'innodb_buffer_pool_size';
+-------------------------+------------+
| Variable_name           | Value      |
+-------------------------+------------+
| innodb_buffer_pool_size | 2147483648 |
+-------------------------+------------+
1 row in set (0.0015 sec)
 MySQL  mysql-innodbcluster:3306 ssl  SQL > show variables like 'sql_mode';
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| sql_mode      |       |
+---------------+-------+
1 row in set (0.0010 sec)
 MySQL  mysql-innodbcluster:3306 ssl  SQL > show variables like 'max_connections';
+-----------------+-------+
| Variable_name   | Value |
+-----------------+-------+
| max_connections | 1000  |
+-----------------+-------+
1 row in set (0.0009 sec)
 MySQL  mysql-innodbcluster:3306 ssl  SQL > show variables like 'lower_case_table_names';
+------------------------+-------+
| Variable_name          | Value |
+------------------------+-------+
| lower_case_table_names | 1     |
+------------------------+-------+
1 row in set (0.0014 sec)
```

## 测试

### 下载 dbgen

* TPC-H_Tools_v3.0.1.zip (Tools) https://www.tpc.org/tpc_documents_current_versions/download_programs/tools-download-request5.asp?bm_type=TPC-H&bm_vers=3.0.1&mode=CURRENT-ONLY

### 编译 dbgen

下载源码包，解压缩，然后：

```
cp makefile.suite makefile
```

修改makefile文件中的CC、DATABASE、MACHINE、WORKLOAD等定义：

```
  ################
  ## CHANGE NAME OF ANSI COMPILER HERE
  ################
  CC      = gcc
  # Current values for DATABASE are: INFORMIX, DB2, ORACLE,
  #                                  SQLSERVER, SYBASE, TDAT (Teradata)
  # Current values for MACHINE are:  ATT, DOS, HP, IBM, ICL, MVS,
  #                                  SGI, SUN, U2200, VMS, LINUX, WIN32
  # Current values for WORKLOAD are:  TPCH
  DATABASE= MYSQL
  MACHINE = LINUX
  WORKLOAD = TPCH
```

修改`tpcd.h`文件，并添加新的宏定义

```
#ifdef MYSQL
#define GEN_QUERY_PLAN ""
#define START_TRAN "START TRANSACTION"
#define END_TRAN "COMMIT"
#define SET_OUTPUT ""
#define SET_ROWCOUNT "limit %d;\n"
#define SET_DBASE "use %s;\n"
#endif
```

对文件进行编译

```
make
```

编译完成后该目录下会生成两个可执行文件：

* `dbgen`：数据生成工具。在使用InfiniDB官方测试脚本进行测试时，需要用该工具生成tpch相关表数据。
* `qgen`：SQL生成工具。生成初始化测试查询，由于不同的seed生成的查询不同，为了结果的可重复性。


### 创建测试用数据库

连接 mysql

```
 mysql --local-infile=1 -u root -h 10.3.105.182 -p'>-0URS4F3P4SS'
```

导入数据

```
create database tpcd;

use tpcd;

source dss.ddl
```

查看建立的表

```
show tables;

+--------------------+
| Tables_in_tpchtest |
+--------------------+
| customer           |
| lineitem           |
| nation             |
| orders             |
| part               |
| partsupp           |
| region             |
| supplier           |
+--------------------+
8 rows in set (0.0027 sec)
```

创建主外键

```
use tpcd;

source dss.ri
```

### 生成测试数据

通过 dbgen工具生成数据, 执行：

```
./dbgen -s 5
```

dbgen参数`-s`的作用是指定生成测试数据的仓库数

生成数据大小，默认为1G

```
ls *.tbl

-rw-r--r-- 1 root root 117M 10月 10 16:21 customer.tbl
-rw-r--r-- 1 root root 3.6G 10月 10 16:21 lineitem.tbl
-rw-r--r-- 1 root root 2.2K 10月 10 16:21 nation.tbl
-rw-r--r-- 1 root root 830M 10月 10 16:21 orders.tbl
-rw-r--r-- 1 root root 573M 10月 10 16:21 partsupp.tbl
-rw-r--r-- 1 root root 116M 10月 10 16:21 part.tbl
-rw-r--r-- 1 root root  389 10月 10 16:21 region.tbl
-rw-r--r-- 1 root root 6.8M 10月 10 16:21 supplier.tbl
```

登录 mysql

```
 mysql --local-infile=1 -u root -h 10.3.105.182 -p'>-0URS4F3P4SS'
```

执行如下 SQL，用来导入数据

```
load data local INFILE 'customer.tbl' INTO TABLE customer FIELDS TERMINATED BY '|';
load data local INFILE 'lineitem.tbl' INTO TABLE lineitem FIELDS TERMINATED BY '|';
load data local INFILE 'nation.tbl' INTO TABLE nation FIELDS TERMINATED BY '|';
load data local INFILE 'orders.tbl' INTO TABLE orders FIELDS TERMINATED BY '|';
load data local INFILE 'partsupp.tbl' INTO TABLE partsupp FIELDS TERMINATED BY '|';
load data local INFILE 'part.tbl' INTO TABLE part FIELDS TERMINATED BY '|';
load data local INFILE 'region.tbl' INTO TABLE region FIELDS TERMINATED BY '|';
load data local INFILE 'supplier.tbl' INTO TABLE supplier FIELDS TERMINATED BY '|';
```

### 生成查询

将 `qgen` 与 `dists.dss` 复制到 `queries`目录下。

```bash
cp qgen queries
cp dists.dss queries
```

使用以下脚本生成查询

```bash
#!/usr/bin/bash
for i in {1..22}
do  
  ./qgen -d $i -s 5 > db"$i".sql
done
```