将单节点转为复制集：https://mongoing.com/docs/tutorial/convert-standalone-to-replica-set.html

部署复制集：<https://mongoing.com/docs/tutorial/deploy-replica-set.html>

## 切换前验证

查看所有的数据库

```bash
# 登录
mongo --port 27017 -u "adminUser" -p "adminPass" --authenticationDatabase "admin"

# 查看所有数据库
show dbs

# 选中数据库
use config

# 查看 collections
show collections
```

关闭 standalone mongod 实例，并备份数据

```bash
# 直接拷贝数据目录
cp /srv/mongodb/db0 /srv/mongodb/db0.bak
```

## 切换步骤

重启实例，并使用 `--replSet` 参数来指定复制集的名字，下列的命令就会将单节点实例加入名为 `rs0` 的复制集中。下列命令使用了单节点实例的数据库目录 `/srv/mongodb/db0`

```bash
mongod --port 27017 --dbpath /srv/mongodb/db0 --replSet rs0
```

连接到 [`mongod`](https://mongoing.com/docs/reference/program/mongod.html#bin.mongod) 实例，使用 [`rs.initiate()`](https://mongoing.com/docs/reference/method/rs.initiate.html#rs.initiate) 来初始化复制集：

```bash
rs.initiate()
```

复制集配置完成

可以使用 

- `rs.conf()` 命令来查看复制集参数
- 可以使用 `rs.status()` 来查看复制集状态

## 复制集扩容

连接到 `mongod` 实例（之前的单节点实例），执行下列的命令将每个新节点加入复制集中：

```bash
rs.add("<hostname><:port>")
```

## 验证

## 参考文档

- <https://blog.51cto.com/u_16175499/7171988>