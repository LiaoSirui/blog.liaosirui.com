## 简介

MySQL Shell是MySQL的高级客户端和代码编辑器。它除了基本的SQL功能外，还提供一套使用Javascript和Python的API去管理MySQL。

能使用它提供的XDevAPI操作MySQL 8.0提供的关系型数据库和文档数据库，还可以使用AdminAPI管理InnoDB集群。

## 特点

* 支持使用Javascript、Python、SQL三种方式操作数据库
* 支持交互式代码执行
* 批处理代码执行
* AdminAPI能管理MySQL实例、InnoDB集群、Innodb副本集、MySQL Cluster、MySQL Router
* XDevAPI能管理RDS和NOSQL
* 输出格式化
* 日志和调试
* 全局Session

## MySQL Shell 命令

## 全局对象

在启动MySQL Shell可以使用内置的全局对象，分别使：

* dba 管理MySQL实例、集群、副本集
* mysql 管理传统SQL模式
* mysqlx 管理X协议支持RDS和NoSQL
* shell 提供访问各种MySQL Shell函数

  * shell.option 管理MySQL Shell配置
  * shell.reports 管理用户定义的MySQL Shell配置
* util 工具包
* cluster InnoDB
* rs 副本集
* db 可用在全球建立了会话使用X协议连接指定一个默认的数据库和模式的代表。

## 启动MySQL Shell

使用 `mysqlsh` 启动MySQL Shell，例如：

```markdown
> mysqlsh
```

通过X Protocol连接MySQL服务器

```css
> mysqlsh --mysqlx -u root -h localhost -P 33060
```

使用传统模式连接MySQL服务器

```bash
> mysqlsh --uri mysql://user@localhost:3306
> mysqlsh mysql://user@localhost:3306
> mysqlsh --mysql --uri user@localhost:3306
```

启动MySQL Shell后连接MySQL服务器

```bash
mysql-js> \connect mysqlx://user@localhost:33060
mysql-js> \connect --mysqlx user@localhost:33060
mysql-js> shell.connect('mysqlx://user@localhost:33060')
mysql-js> shell.connect( {scheme:'mysqlx', user:'*user*', host:'localhost', port:33060} )
```

### 在Javascript和Python模式中使用脚本对象

### 全局对象

在JS和PY模式下可以使用`mysqlx`和`mysql`对象。
使用`getSession`函数可以获取一个session对象，例如：

```ini
mysql-js> var s1 = mysqlx.getSession('user@localhost:33060', 'password')
mysql-js> var s2 = mysql.getClassicSession('user@localhost:33060', 'password')
mysql-js> var s3 = shell.open_session('mysqlx://user@localhost:33060?compression=required', 'password')
```