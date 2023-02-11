可以使用如下的脚本进行 alias

```bash
export ETCDCTL_API=3
export HOST_1=https://192.168.148.116
export HOST_2=https://192.168.148.117
export HOST_3=https://192.168.148.115
export ENDPOINTS=$HOST_1:2379,$HOST_2:2379,$HOST_3:2379
# export ENDPOINTS=$HOST_1:2379,$HOST_2:2379

alias newetcdctl='etcdctl --endpoints=$ENDPOINTS --cacert=/etc/kubernetes/pki/etcd/ca.crt \
   --cert=/etc/kubernetes/pki/etcd/server.crt \
   --key=/etc/kubernetes/pki/etcd/server.key'
```

