## 通过终端操作数据库

先找到数据库所在文件夹

```bash
cd /xx/xx/xx
```

进入数据库（可以通过 ls 查看文件夹下目录）

```bash
sqlite3 xx.db
```

查看数据库中的表

```sqlite
.tables
```

创建一个表结构

```sqlite
CREATE TABLE testTabel (
  ID INT PRIMARY KEY NOT NULL,
  DEPT CHAR(50) NOT NULL,
  EMP_ID INT NOT NULL
);
```

查看表结构

```sqlite
.schema xxx
```

查看某个表的数据

```sqlite
SELECT * FROM xxx;
```

通过 `.dump` 来进行查看表结构

```sqlite
.dump xxxx
```

退出 sqlite 语句

```sqlite
.quit
```
