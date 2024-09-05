SQLite 是一个轻量级的数据库系统，它将整个数据库存储在一个单独的磁盘文件中。SQLite 不需要服务器，也不需要安装或配置，Python3 中就自带了一个 SQLite3 模块。虽然 SQLite 轻量，但功能却不轻，SQLite 支持大部分 SQL 语言的功能

pandas 通过 `to_sql()` 和 `read_sql()` 这两个函数，可以非常方便地实现对 SQLite 数据库的读写操作

连接数据库，如果数据库不存在，则创建该数据库：

```python
# 设置数据库的路径和文件名
file_path = './data.db'

# 创建数据库连接
conn = sqlite3.connect(file_path)
```

上述语句返回一个数据库对象 conn，后面对数据库的读写操作都需要用到 conn 这个数据库对象

用 pandas 的 `to_sql()` 函数将 dataframe 数据写入数据库：

```python
df.to_sql("600000", conn, if_exists='replace', index=False)
```

简单解释下to_sql()函数的参数：

- "600000" 表示将数据存入数据库中名为"600000"的表中，一个数据库中可以有多张表，分别存储不同的数据。比如可以为每只股票建立一张表，用来存储该股票的数据，所有这些表都在一个数据库中

- conn 为之前步骤建立的数据库连接对象

- if_exists 参数选 `'replace'` 表示如果这张表中已经存在数据，则覆盖原有数据；如果不想覆盖原有数据，而是采用追加的方式将数据写入表中，则需要将 if_exists 参数设置为 `'append'`，这在更新数据时很有用

- index 参数设置为 False 表示不用将 DataFrame 的索引写入数据库

用 pandas 的 `read_sql()` 函数从数据库中读取数据到 DataFrame

```python
# SQL查询语句，从'600000'表中选取所有内容
sql = "SELECT * FROM '600000'"
df = pd.read_sql(sql, conn)

# 输出数据查看
print(df)
```

- sql 为 SQL查询语句，SQL 是用于访问和处理数据库的标准的计算机语言，支持 SQLite、MySQL、SQL Server、Access、Oracle、Sybase、DB2 等等多种数据库。用 SQL 查询语句可以方便的实现数据插入、查询、更新、删除等操作

- conn 为之前步骤建立的数据库连接对象

关闭数据库连接：

```python
conn.close()
```

