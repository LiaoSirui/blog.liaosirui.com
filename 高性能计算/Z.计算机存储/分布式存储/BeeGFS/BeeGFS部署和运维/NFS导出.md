`beegfs-client.conf` 需要做如下配置

```
tuneRefreshOnGetAttr = true
```

NFSv4 导出示例

```
/mnt/beegfs    *(rw,async,fsid=0,crossmnt,no_subtree_check,no_root_squash)
```

挂载

```bash
mount -t nfs -overs=4 myserver:/ /mnt/beegfs_via_nfs/
```

关闭 NFS 锁

```
sysctl -w fs.leases-enable=0
```

`/etc/systemd/system/multi-user.target.wants/beegfs-client.service` 加入如下配置：

```bash
Before=nfs-server.service
```