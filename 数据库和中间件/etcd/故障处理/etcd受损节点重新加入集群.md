- 移除受损节点

查看当前集群状态

```bash
> etcdctl member list

f0a399bcc03bea5f, started, k8s-02, https://172.31.243.179:2380, https://172.31.243.179:2379, false
8262a810106df86c, started, k8s-03, https://172.31.243.180:2380, https://172.31.243.180:2379, false
```

原本是三节点，现在一个节点加入不了集群，因为数据受损

如果这里有出现受损节点的信息，需要 `etcdctl member remove <集群id>`，然后再执行后面的操作

- 删除受损 etcd 节点的数据

移动原有的数据到新的目录

```bash
mv /data/etcd{,-bak$(date +%F)}
```

注意，重新建的目录需要授权为 `0700`

```bash
mv /data/etcd
chmod 0700 /data/etcd
```

- 数据受损节点重新加入集群

```bash
etcdctl member add \
  k8s-03 \ # 节点名称
  --peer-urls=https://172.31.243.178:2380 # 对端的 IP 和端口
```

上面的命令执行后会出现提示：

```bash
```

修改 etcd 启动参数，重启 etcd

