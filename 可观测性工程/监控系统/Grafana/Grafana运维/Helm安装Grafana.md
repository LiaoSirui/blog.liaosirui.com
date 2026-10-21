## 使用 helm chart 进行安装

添加仓库

```bash
helm repo add grafana https://grafana.github.io/helm-charts
```

查看最新的版本

```bash
> helm search repo grafana  

grafana/grafana                                 6.52.4          9.4.3                   The leading tool for querying and visualizing t...
...
```

拉取最新版本

```bash
helm pull grafana/grafana --version 6.52.4

# 下载并解压
helm pull grafana/grafana --version 6.52.4 --untar
```

新建 pv

```yaml
kind: PersistentVolume
apiVersion: v1
metadata:
  annotations:
    pv.kubernetes.io/provisioned-by: beegfs.csi.netapp.com
  name: grafana-data
  labels:
    app.kubernetes.io/instance: grafana
    app.kubernetes.io/name: grafana
spec:
  capacity:
    storage: 100Gi
  csi:
    driver: beegfs.csi.netapp.com
    volumeHandle: 'beegfs://10.244.244.201/app-data/grafana'
    volumeAttributes:
      storage.kubernetes.io/csiProvisionerIdentity: 1680159721626-8081-beegfs.csi.netapp.com
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  volumeMode: Filesystem
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: grafana-data
  namespace: grafana
  labels:
    app.kubernetes.io/instance: grafana
    app.kubernetes.io/name: grafana
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Gi
  volumeMode: Filesystem
  selector:
    matchLabels:
      app.kubernetes.io/instance: grafana
      app.kubernetes.io/name: grafana

```

使用如下 `values.yaml`

```yaml
service:
  enabled: true
  type: LoadBalancer
  loadBalancerIP: 10.244.244.151
  allocateLoadBalancerNodePorts: false # not work here
  port: 3000

tolerations:
  - operator: Exists

nodeSelector:
  kubernetes.io/hostname: devmaster

persistence:
  type: pvc
  enabled: true
  existingClaim: grafana-data
  # storageClassName: csi-beegfs-hdd

adminUser: admin
adminPassword: abcd1234!

```

安装

```yaml
helm upgrade --install grafana  \
    --namespace grafana \
    --create-namespace \
    -f ./values.yaml \
    grafana/grafana --version 6.52.4
```

查看密码

```bash
kubectl get secret --namespace grafana grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```
