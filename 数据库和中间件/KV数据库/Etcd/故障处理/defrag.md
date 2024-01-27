运行一个 job 来进行 defrag

```yaml
# etcd-defrag-job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: etcd-defrag-job
  labels:
    app: etcd-defrag-job
spec:
  template:
    metadata:
      labels:
        app: etcd-defrag-job
    spec:
      containers:
      - name: etcd
        image: harbor.local.liaosirui.com:5000/3rdparty/registry.k8s.io/etcd:3.5.6-0
        imagePullPolicy: IfNotPresent
        args:
        - /bin/sh
        - -cxe
        - |
          export HOST_1=https://10.244.244.201
          export TEMP_ETCDCTL_ENDPOINTS=$HOST_1:2379
          
          etcdctl --endpoints=${TEMP_ETCDCTL_ENDPOINTS} defrag --cluster
          etcdctl --endpoints=${TEMP_ETCDCTL_ENDPOINTS} --write-out="table" endpoint status

          etcdctl --endpoints=${TEMP_ETCDCTL_ENDPOINTS} alarm disarm;
          etcdctl --endpoints=${TEMP_ETCDCTL_ENDPOINTS} alarm list;
        volumeMounts:
        - mountPath: /etc/kubernetes/pki/etcd
          name: etcd-certs
        env:
          - name: ETCDCTL_CACERT
            value: /etc/kubernetes/pki/etcd/ca.crt
          - name: ETCDCTL_CERT
            value: /etc/kubernetes/pki/etcd/server.crt
          - name: ETCDCTL_KEY
            value: /etc/kubernetes/pki/etcd/server.key
          - name: ETCDCTL_API
            value: '3'
          - name: ETCDCTL_DIAL_TIMEOUT
            value: '3s'
      volumes:
      - name: etcd-certs
        hostPath:
          path: /etc/kubernetes/pki/etcd
          type: "Directory"
      restartPolicy: OnFailure
      nodeSelector:
        "node-role.kubernetes.io/control-plane": ""
      tolerations:
        - operator: "Exists"

```

提交容器

```bash
kubectl create -f ./etcd-defrag-job.yaml -n kube-system
```

查看容器

```bash
kubectl get job -n kube-system | grep etcd-defrag-job
```

查看日志

```bash
> kubectl logs -n kube-system -l app=etcd-defrag-job

+ etcdctl --endpoints=https://10.244.244.201:2379 defrag --cluster
Finished defragmenting etcd member[https://10.244.244.201:2379]
+ etcdctl --endpoints=https://10.244.244.201:2379 --write-out=table endpoint status
+-----------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
|          ENDPOINT           |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX | ERRORS |
+-----------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
| https://10.244.244.201:2379 | 5507efc8980c6940 |   3.5.6 |  5.4 MB |      true |      false |        19 |    4092525 |            4092525 |        |
+-----------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
+ etcdctl --endpoints=https://10.244.244.201:2379 alarm disarm
+ etcdctl --endpoints=https://10.244.244.201:2379 alarm list
```

