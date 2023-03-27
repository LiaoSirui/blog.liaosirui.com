## InfluxDB 简介

InfluxDB 默认使用下面的网络端口：

- TCP 端口 `8086` 用作 InfluxDB 的客户端和服务端的 http api 通信
- TCP 端口 `8088` 给备份和恢复数据的 RPC 服务使用

另外，InfluxDB 也提供了多个可能需要自定义端口的插件，所以的端口映射都可以通过配置文件修改，对于默认安装的 InfluxDB，这个配置文件位于 `/etc/influxdb/influxdb.conf`

## 安装

RedHat 和 CentOS 用户可以直接用包管理来安装最新版本的 InfluxDB

```bash
cat <<EOF | tee /etc/yum.repos.d/influxdb.repo
[influxdb]
name = InfluxDB Repository - RHEL \$releasever
baseurl = https://repos.influxdata.com/rhel/\$releasever/\$basearch/stable
enabled = 1
gpgcheck = 1
gpgkey = https://repos.influxdata.com/influxdb.key
EOF
```

运行下面的命令来安装 InfluxDB 服务：

```bash
dnf install -y influxdb
```

## 参考资料

<https://jasper-zhang1.gitbooks.io/influxdb/content/Introduction/getting_start.html>