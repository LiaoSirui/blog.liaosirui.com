## 连接 k8s 的 etcd

可以使用如下的脚本进行 alias

```bash
export HOST_1=https://192.168.148.116
export HOST_2=https://192.168.148.117
export HOST_3=https://192.168.148.115
export ETCDCTL_ENDPOINTS=$HOST_1:2379,$HOST_2:2379,$HOST_3:2379

export ETCDCTL_API=3
export ETCDCTL_CACERT=/etc/kubernetes/pki/etcd/ca.crt
export ETCDCTL_CERT=/etc/kubernetes/pki/etcd/server.crt
export ETCDCTL_KEY=/etc/kubernetes/pki/etcd/server.key

alias netcdctl='etcdctl --endpoints=${ETCDCTL_ENDPOINTS}'
```

## endpoint

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

## member

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

