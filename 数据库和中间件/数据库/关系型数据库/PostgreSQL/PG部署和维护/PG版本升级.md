文档：

- <https://www.postgresql.org/docs/13/release-13.html#id-1.11.6.6.4>

升级方式：

- `pg_dumpall` 将数据库转储成一个脚本文件，然后在新版数据库中可以直接导入。这种方式操作简单，跟着官方文档就能轻松操作，但是明显只适用于数据量较少的情况
- `pg_upgrade` 这种方式是直接将数据文件升级到高版本

首先拉取一个 PG13 的镜像，然后放好别动：

```bash
docker pull postgres:13.13
docker pull postgres:14.11
```

准备旧数据：

```bash
# 拷贝
mkdir /data/ssd/pg13
mv /data/ssd/gitlab-ee/pg-data /data/ssd/pg13/

# 备份
cd /data/ssd/pg13
tar zcvf pg-data.tgz pg-data/

cd /db_update

# 将旧数据库容器的 bin 跟 data 复制出来
docker cp pgdb:/usr/local old_bin
docker cp pgdb:/usr/local old_share
docker cp pgdb:/var/lib/postgresql/data old_data

# 授权
chmod -R 777 /db_update/old_data
```

将旧版本数据库容器的 bin、lib 都拷贝出来

```bash
docker create --name old-pg postgres:13.13

# 拷贝数据
docker cp old-pg:/usr/lib ./old_usr_lib
docker cp old-pg:/usr/share ./old_usr_share
```

新建一个正式容器，并映射 data 目录，初始化完成后 ctrl+c 退出

```bash
mkdir -p /data/ssd/gitlab-ee/pg-data
chown 999 /data/ssd/gitlab-ee/pg-data

# 一定要和原来的初始化保持一致
# 注意 -e POSTGRES_DB=gitlab 需要取消，否则无法导入
docker run --name="pg-new" \
    --rm \
    -v "/data/ssd/gitlab-ee/pg-data:/var/lib/postgresql/data" \
    -e POSTGRES_USER=gitlab \
    -e POSTGRES_PASSWORD=123456 \
    postgres:14.11

# 删除数据库
docker exec -it pg-new dropdb gitlab -U gitlab
# 初始化完成后 ctrl+c 退出
```

新建一个临时容器，用于升级数据，映射 PG13 的 bin 跟 data 目录，容器内的 data 跟正式容器映射到同一个目录

```bash
docker run -it \
    --name="tmp" \
    --rm \
    -v "${PWD}/old_usr_lib/postgresql/13:/usr/lib/postgresql/13" \
    -v "${PWD}/old_usr_lib:/old_usr_lib" \
    -v "${PWD}/old_usr_share/postgresql/13:/usr/share/postgresql/13" \
    -v "${PWD}/old_usr_share:/old_usr_share" \
    -v "/data/ssd/pg13/pg-data:/data/old_data" \
    -v "/data/ssd/gitlab-ee/pg-data:/var/lib/postgresql/data" \
    --privileged=true \
    --entrypoint="/bin/bash" \
    postgres:14.11
```

执行升级

```bash
chown -Rf postgres /data/old_data

# export LD_LIBRARY_PATH=/old_usr_lib/x86_64-linux-gnu:/old_usr_lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
# 缺库从 /old_usr_lib 找并拷贝到对应的 /usr/lib/... 下
cp /old_usr_lib/x86_64-linux-gnu/libLLVM-15.so.1 /usr/lib/x86_64-linux-gnu/
cp /old_usr_lib/x86_64-linux-gnu/libLLVM-15.so /usr/lib/x86_64-linux-gnu/

# 切换数据库用户
su - postgres
cd /tmp

# 检查是否可以升级
/usr/lib/postgresql/14/bin/pg_upgrade \
    -b /usr/lib/postgresql/13/bin \
    -B /usr/lib/postgresql/14/bin \
    -d /data/old_data/ \
    -D /var/lib/postgresql/data \
    -U gitlab \
    -p 5433 \
    -P 5434 \
    -c
```

最后执行升级

```bash
/usr/lib/postgresql/14/bin/pg_upgrade \
    -b /usr/lib/postgresql/13/bin \
    -B /usr/lib/postgresql/14/bin \
    -d /data/old_data/ \
    -D /var/lib/postgresql/data \
    -U gitlab \
    -p 5433 \
    -P 5434
```

等待升级完成即可，重新授权

```bash
GRANT ALL PRIVILEGES ON DATABASE gitlab TO gitlab;
```
