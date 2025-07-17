### `\o`

写入文件命令：

```postgresql
psql> \o /mytemp/write.txt
```

接下来执行 query 命令：

```postgresql
SELECT foo, bar FROM baz
```

执行的结果将自动写入到文件 write.txt 中，但是每一行第一个字符是空格

如果想再次打开屏幕输出，则再次使用命令：

```postgresql
-- 关闭文件输出，切换到屏幕输出
psql> \o
```

也可以使用 COPY 指令完成

```postgresql
COPY (SELECT foo, bar FROM baz) TO '/tmp/query.csv' (format csv, delimiter ';')
```
