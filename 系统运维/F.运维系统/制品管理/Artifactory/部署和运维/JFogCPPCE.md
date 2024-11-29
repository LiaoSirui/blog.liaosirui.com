JFrog Artifactory Community Edition for C/C++

官网链接：<https://jfrog.com/community/open-source/>

下载地址：<https://conan.io/downloads>

手动安装

```bash
mkdir -p $JFROG_HOME/artifactory/var
mkdir -p $JFROG_HOME/artifactory/var/data
mkdir -p $JFROG_HOME/artifactory/var/etc

# Necessary if you want to add nginx
mkdir -p $JFROG_HOME/artifactory/var/data/nginx
# Necessary if you want to add postgres
mkdir -p $JFROG_HOME/artifactory/var/data/postgres 
```

授权

```bash
chown -R 1030:1030 $JFROG_HOME/artifactory/var
chown -R 1030:1030 $JFROG_HOME/artifactory/var/data
chown -R 1030:1030 $JFROG_HOME/artifactory/var/etc
chown -R 104:107 $JFROG_HOME/artifactory/var/data/nginx
chown -R 999:999 $JFROG_HOME/artifactory/var/data/postgres
```

重置密码

在 `JFORG_HOME/artifactory/var/etc/access` 目录下，新建 `bootstrap.creds` 文件，添加用户名及密码，格式如下：

```
admin@*=password
```

更改权限

```bash
chmod 600 bootstrap.creds
chown -R 1030:1030 bootstrap.creds
```

