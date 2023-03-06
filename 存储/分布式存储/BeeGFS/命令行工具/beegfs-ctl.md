```bash
beegfs-ctl -h
BeeGFS Command-Line Control Tool (http://www.beegfs.com)
Version: 7.3.2

GENERAL USAGE:
 $ beegfs-ctl --<modename> --help
 $ beegfs-ctl --<modename> [mode_arguments] [client_arguments]

MODES:
 --listnodes             => List registered clients and servers.
 --listtargets           => List metadata and storage targets.
 --removenode (*)        => Remove (unregister) a node.
 --removetarget (*)      => Remove (unregister) a storage target.

 --getentryinfo          => Show file system entry details.
 --setpattern (*)        => Set a new striping configuration.
 --mirrormd (*)          => Enable metadata mirroring.
 --find                  => Find files located on certain servers.
 --refreshentryinfo      => Refresh file system entry metadata.

 --createfile (*)        => Create a new file.
 --createdir (*)         => Create a new directory.
 --migrate               => Migrate files to other storage servers.
 --disposeunused (*)     => Purge remains of unlinked files.

 --serverstats           => Show server IO statistics.
 --clientstats           => Show client IO statistics.
 --userstats             => Show user IO statistics.
 --storagebench (*)      => Run a storage targets benchmark.

 --getquota              => Show quota information for users or groups.
 --setquota (*)          => Sets the quota limits for users or groups.

 --listmirrorgroups      => List mirror buddy groups.
 --addmirrorgroup (*)    => Add a mirror buddy group.
 --startresync (*)       => Start resync of a storage target or metadata node.
 --resyncstats           => Get statistics on a resync.
 --setstate (*)          => Manually set the consistency state of a target or
                            metadata node.

 --liststoragepools      => List storage pools.
 --addstoragepool (*)    => Add a storage pool.
 --removestoragepool (*) => Remove a storage pool.
 --modifystoragepool (*) => Modify a storage pool.

*) Marked modes require root privileges.

USAGE:
 This is the BeeGFS command-line control tool.

 Choose a control mode from the list above and use the parameter "--help" to
 show arguments and usage examples for that particular mode.

 Example: Show help for mode "--listnodes"
  $ beegfs-ctl --listnodes --help
```

## listnodes

查看集群服务详细信息：`beegfs-ctl --listnodes --nodetype={node_type} --details` 

`{node_type}` 为 beegfs 集群节点类型，可选：mgmt、meta、storage、client

## listtargets

查看集群服务状态：`beegfs-ctl --listtargets --nodetype={node_type} --state` 

`{node_type}` 为 beegfs 集群节点类型，可选 meta、storage

## removenode

删除集群角色：`beegfs-ctl --removenode --nodetype={node_type} {node_id}` 

注：{node_id} 可通过 beegfs-net 查看 ID 值。删除集群角色不会自动迁移对应数据到其他节点，需谨慎使用！！

如需迁移数据后删除，参考官方手册：<https://www.beegfs.io/wiki/FAQ#migrate>

## getentryinfo

查看集群目录属性信息：`beegfs-ctl --getentryinfo {mount_path}` 注：{mount-path} 为 beegfs 集群挂载路径，当前有 RAID0 和 Buddy Mirror 两种模式