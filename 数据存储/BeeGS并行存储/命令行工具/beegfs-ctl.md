## listnodes

查看集群服务详细信息：`beegfs-ctl --listnodes --nodetype={node_type} --details` 

`{node_type}` 为 beegfs 集群节点类型，可选：mgmt、meta、storage、client

## listtargets

查看集群服务状态：`beegfs-ctl --listtargets --nodetype={node_type} --state` 

查看 Buddy Mirror 中的状态：

```bash
# 查看 metadata 状态
beegfs-ctl --listtargets --nodetype=meta --state

# 查看 storage 状态
# beegfs-ctl --listtargets --nodetype=storage --state
```

## resyncstats

查看同步状态

```bash
# metadata resync

beegfs-ctl --resyncstats --nodetype=meta --mirrorgroupid=1

beegfs-ctl --resyncstats --nodetype=meta --mirrorgroupid=2
```

## removenode

删除集群角色：`beegfs-ctl --removenode --nodetype={node_type} {node_id}` 

注：{node_id} 可通过 beegfs-net 查看 ID 值。删除集群角色不会自动迁移对应数据到其他节点，需谨慎使用！！

如需迁移数据后删除，参考官方手册：<https://www.beegfs.io/wiki/FAQ#migrate>

## getentryinfo

查看集群目录属性信息：`beegfs-ctl --getentryinfo {mount_path}` 注：{mount-path} 为 beegfs 集群挂载路径，当前有 RAID0 和 Buddy Mirror 两种模式