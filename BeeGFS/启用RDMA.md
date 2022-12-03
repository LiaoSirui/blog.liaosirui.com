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

