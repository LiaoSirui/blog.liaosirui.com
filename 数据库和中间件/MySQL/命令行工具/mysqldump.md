<https://mysqldump.guru/run-mysqldump-without-locking-the-tables.html>

<https://www.stackhero.io/en/services/MySQL/documentations/Troubleshooting/How-to-solve-MySQL-error-Authentication-plugin-cachingsha2password-cannot-be-loaded>

<https://www.maoyingdong.com/mysql-update-sql-locking/>

<https://blog.csdn.net/yucaifu1989/article/details/79400446>

<https://blog.csdn.net/u013810234/article/details/105978479>



<https://cloud.tencent.com/developer/article/1401617>

<https://zhuanlan.zhihu.com/p/347105199>

<https://www.jianshu.com/p/3c7d6a59c4a3>



<https://blog.csdn.net/miyatang/article/details/78227344>



只导出表结构

```bash
mysqldump \
  -h $HOST \
  -u$USER \
  -p$PASSWORD \
  --single-transaction \
  --skip-lock-tables \
  --no-data \
  --databases <db1> <db2> <..>
```

