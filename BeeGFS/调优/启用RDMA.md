官方文档：<https://doc.beegfs.io/7.3.2/advanced_topics/rdma_support.html>

最新版：<https://doc.beegfs.io/latest/advanced_topics/rdma_support.html>

增加客户端编译参数，配置文件 `/etc/beegfs/beegfs-client-autobuild.conf`：

```
buildArgs=-j8 OFED_INCLUDE_PATH=/usr/src/openib/include
```

重新编译客户端；

```
/etc/init.d/beegfs-client rebuild
```

安装

```
dnf install -y libbeegfs-ib
```

验证

```
beegfs-ctl --listnodes --nodetype=storage --details
beegfs-ctl --listnodes --nodetype=meta --details
beegfs-ctl --listnodes --nodetype=client --details

beegfs-net
```


### 服务端

```bash
/etc/beegfs/conn-inf.conf
```

填入网卡名

```plain
eth0
siw0
```

依次停服务：

```bash
# 先停所有 client
systemctl stop beegfs-client

# 停所有 storage
systemctl stop beegfs-storage

# 停所有 meta
systemctl stop beegfs-meta

# 停止 managment
systemctl stop beegfs-mgmtd
```

修改所有配置文件：

```bash
# 客户端
vi /etc/beegfs/beegfs-client.conf
```

均修改配置

```bash
connRDMAInterfacesFile = /etc/beegfs/conn-inf.conf
```
