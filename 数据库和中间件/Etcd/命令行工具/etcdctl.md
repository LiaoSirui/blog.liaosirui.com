## Etcdctl 简介

官方：

- GitHub 仓库：<https://github.com/etcd-io/etcd/tree/main/etcdctl>

## 安装 Etcdctl

同时安装了 etcdutl

```bash
export I_ETCDCTL_VERSION=v3.5.6

cd $(mktemp -d)
curl -sL "https://github.com/etcd-io/etcd/releases/download/${I_ETCDCTL_VERSION}/etcd-${I_ETCDCTL_VERSION}-linux-amd64.tar.gz" -o etcd.tgz
tar zxvf etcd.tgz -C .
mkdir -p /usr/local/etcd
mv "etcd-${I_ETCDCTL_VERSION}-linux-amd64" /usr/local/etcd

update-alternatives --install /usr/bin/etcdutl etcdutl "/usr/local/etcd/etcd-${I_ETCDCTL_VERSION}-linux-amd64/etcdutl" 1
alternatives --set etcdutl "/usr/local/etcd/etcd-${I_ETCDCTL_VERSION}-linux-amd64/etcdutl"
etcdutl version

update-alternatives --install /usr/bin/etcdctl etcdctl "/usr/local/etcd/etcd-${I_ETCDCTL_VERSION}-linux-amd64/etcdctl" 1
alternatives --set etcdctl "/usr/local/etcd/etcd-${I_ETCDCTL_VERSION}-linux-amd64/etcdctl"
etcdctl version
```

## 子命令

### endpoint

- 查看集群状态

```bash
> etcdctl endpoint status --write-out="table"
```

输出信息如下：

```bash
+------------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
|           ENDPOINT           |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX | ERRORS |
+------------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
| https://192.168.148.116:2379 | a513239cbbe4b01d |  3.4.13 |  852 MB |     false |      false |      3392 |  870533493 |          870533493 |        |
| https://192.168.148.117:2379 | c6357ab2854c19c9 |  3.4.13 |  852 MB |      true |      false |      3392 |  870533493 |          870533493 |        |
| https://192.168.148.115:2379 | 183e7af98a08d40a |  3.4.13 |  853 MB |     false |      false |      3392 |  870533493 |          870533493 |        |
+------------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
```

### member

- 查看集群成员

```bash
etcdctl member list --write-out="table"
```

输出信息如下：

```bash
+------------------+---------+-------------------+------------------------------+------------------------------+------------+
|        ID        | STATUS  |       NAME        |          PEER ADDRS          |         CLIENT ADDRS         | IS LEARNER |
+------------------+---------+-------------------+------------------------------+------------------------------+------------+
| 183e7af98a08d40a | started | control-master006 | https://192.168.148.115:2380 | https://192.168.148.115:2379 |      false |
| a513239cbbe4b01d | started | control-master004 | https://192.168.148.116:2380 | https://192.168.148.116:2379 |      false |
| c6357ab2854c19c9 | started | control-master005 | https://192.168.148.117:2380 | https://192.168.148.117:2379 |      false |
+------------------+---------+-------------------+------------------------------+------------------------------+------------+
```

### snapshot

快照备份和从快照恢复

```bash
etcdctl snapshot save <backup-file-location>

etcdctl snapshot restore  <backup-file-location>
```

