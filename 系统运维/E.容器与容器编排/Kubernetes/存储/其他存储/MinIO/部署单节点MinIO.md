MinIO 环境部署（分布式)

参考文档：<https://mp.weixin.qq.com/s/ui0AciaTDFBZ0QwljPhx8g>

添加 helm 仓库

```bash
helm repo add minio https://helm.min.io/
```

查看 minio 的最新版本

```bash
> helm search repo minio                  

NAME            CHART VERSION   APP VERSION     DESCRIPTION                                       
minio/minio     8.0.10          master          High Performance, Kubernetes Native Object Storage
```

拉取最新版本的 Chart

```bash
helm pull minio/minio --version 8.0.10

# 下载并解压
helm pull minio/minio --version 8.0.10 --untar
```

新建 sc

```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: csi-beegfs-ssd-nonroot
provisioner: beegfs.csi.netapp.com
parameters:
  permissions/gid: '1000'
  permissions/mode: '0755'
  permissions/uid: '1000'
  stripePattern/storagePoolID: '2'
  sysMgmtdHost: 10.245.245.201
  volDirBasePath: kube/ssd-dyn
reclaimPolicy: Delete
allowVolumeExpansion: false
volumeBindingMode: Immediate
```

修改 values.yaml 文件

```yaml
accessKey: 'minio'
secretKey: 'LSR1142.minio'

# Number of drives attached to a node
drivesPerNode: 1
# Number of MinIO containers running
replicas: 4
# Number of expanded MinIO clusters
zones: 1

tolerations:
  - operator: "Exists"

persistence:
  enabled: true
  storageClass: 'csi-beegfs-ssd'
  VolumeName: ''
  accessMode: ReadWriteMany
  size: 100Gi

service:
  type: LoadBalancer
  loadBalancerIP: 10.244.244.198

resources:
  requests:
    memory: 128Mi

ingress:
  enabled: false

securityContext:
  enabled: false

```

安装

```bash
helm upgrade --install \
  -n minio-system --create-namespace \
  -f ./values.yaml \
  --version 8.0.10 \
  minio \
  minio/minio
```

