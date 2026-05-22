## 部署

### MinIO 部署

Velero 依赖对象存储保存备份数据，这里部署 MinIO 替代公有云对象存储

部署完成后，可以通过 `http://<nodeip>:30081` 访问 minio 的 console 页面

如果需要在不同 Kubernetes 和存储池集群备份与恢复数据，需要将 MinIO 服务端安装在 Kubernetes 集群外，保证在集群发生灾难性故障时，不会对备份数据产生影响，可以通过二进制的方式进行安装

### Velero 客户端

在 Github (<https://github.com/vmware-tanzu/velero/releases>)下载指定的 velero 二进制客户端，解压放置 `$PATH`路径

```bash
# refer: https://github.com/vmware-tanzu/velero/releases
export INST_VELERO_VERSION=v1.10.3

cd $(mktemp -d)
curl -sL "https://github.com/vmware-tanzu/velero/releases/download/${INST_VELERO_VERSION}/velero-${INST_VELERO_VERSION}-linux-amd64.tar.gz" \
    -o velero.tgz 
tar zxf velero.tgz -C /usr/local 
chmod +x /usr/local/velero-${INST_VELERO_VERSION}-linux-amd64/velero 
update-alternatives --install /usr/bin/velero velero /usr/local/velero-${INST_VELERO_VERSION}-linux-amd64/velero 1 
alternatives --set velero /usr/local/velero-${INST_VELERO_VERSION}-linux-amd64/velero 

```

### Velero 服务端

首先准备密钥文件，access key id 和 secret access key 为MinIO 的用户名和密码

```ini
# 秘钥文件 credentials-velero
[default]
aws_access_key_id=<access key id>
aws_secret_access_key=<secret access key>
```

可以使用 velero 客户端来安装服务端，也可以使用 Helm Chart 来进行安装

以客户端来安装，velero 命令默认读取 kubectl 配置的集群上下文，所以前提是 velero 客户端所在的节点有可访问集群的 kubeconfig 配置

```bash
velero install \
    --provider aws \
    --bucket velero \
    --image velero/velero:v1.10.3 \
    --plugins velero/velero-plugin-for-aws:v1.7.0 \
    --namespace velero \
    --secret-file ./credentials-velero \
    --use-volume-snapshots=false \
    --kubeconfig=/root/.kube/config \
    --backup-location-config region=minio,s3ForcePathStyle="true",s3Url=http://10.244.244.11:30080
```

- 这里使用 MinIO 作为对象存储，MinIO 是兼容 S3 的，所以配置的 provider（声明使用的 Velero 插件类型）是 AWS `–secret-file` 用来提供访问 MinIO 的密钥
- `–plugins` 使用的 velero 插件，MinIO 使用 AWS S3 兼容插件
- s3Url 配置 MinIO 服务对外暴露的 nodePort 端口及部署节点 IP

## 使用

### 备份数据

`--include-namespaces` 用来备份该命名空间下的所有资源，不包括集群资源，此外还可以使用 `--include-resources` 指定要备份的资源类型 ，`--include-cluster-resources` 指定是否备份集群资源

```bash
velero backup create flux-backup --include-namespaces flux-system
```

该命令请求创建一个对项目（命名空间）的备份，备份请求发送之后可以用命令查看备份状态，等到 STATUS 列变为 `Completed` 表示备份完成

```bash
> velero backup describe flux-backup
Name:         flux-backup
Namespace:    velero
Labels:       velero.io/storage-location=default
Annotations:  velero.io/source-cluster-k8s-gitversion=v1.27.1
              velero.io/source-cluster-k8s-major-version=1
              velero.io/source-cluster-k8s-minor-version=27

Phase:  Completed

Errors:    0
Warnings:  0

Namespaces:
  Included:  flux-system
  Excluded:  <none>

Resources:
  Included:        *
  Excluded:        <none>
  Cluster-scoped:  auto

Label selector:  <none>

Storage Location:  default

Velero-Native Snapshot PVs:  auto

TTL:  720h0m0s

CSISnapshotTimeout:  10m0s

Hooks:  <none>

Backup Format Version:  1.1.0

Started:    2023-05-29 13:56:01 +0800 CST
Completed:  2023-05-29 13:56:04 +0800 CST

Expiration:  2023-06-28 13:56:01 +0800 CST

Total items to be backed up:  45
Items backed up:              45

Velero-Native Snapshots: <none included>

# 更多详细信息：
# velero backup logs flux-backup
```

备份完成后可以去 minio 的 bucket 上查看是否有对应的备份数据

现在删除应用所在的命名空间来模拟生产环境发生灾难或运维错误导致应用失败的场景：

```bash
kubectl delete namespace flux-system
```

使用 velero 从 minio 中来恢复应用和数据：

```bash
velero restore create --from-backup flux-backup
```

同样可以使用 `velero restore get` 来查看还原的进度，等到 STATUS 列变为 `Completed` 表示还原完成：

```bash
> velero restore describe flux-backup-20230529135856

Name:         flux-backup-20230529135856
Namespace:    velero
Labels:       <none>
Annotations:  <none>

Phase:                       Completed
Total items to be restored:  45
Items restored:              45

Started:    2023-05-29 13:58:57 +0800 CST
Completed:  2023-05-29 13:59:06 +0800 CST

Warnings:
  Velero:     <none>
  Cluster:  could not restore, CustomResourceDefinition "ciliumendpoints.cilium.io" already exists. Warning: the in-cluster version is different than the backed-up version.
  Namespaces:
    flux-system:  could not restore, ConfigMap "kube-root-ca.crt" already exists. Warning: the in-cluster version is different than the backed-up version.
                  could not restore, CiliumEndpoint "source-controller-7f47858959-8wsk8" already exists. Warning: the in-cluster version is different than the backed-up version.
                  could not restore, Endpoints "notification-controller" already exists. Warning: the in-cluster version is different than the backed-up version.
                  could not restore, Endpoints "source-controller" already exists. Warning: the in-cluster version is different than the backed-up version.
                  could not restore, Endpoints "webhook-receiver" already exists. Warning: the in-cluster version is different than the backed-up version.
                  could not restore, Lease "helm-controller-leader-election" already exists. Warning: the in-cluster version is different than the backed-up version.
                  could not restore, Lease "kustomize-controller-leader-election" already exists. Warning: the in-cluster version is different than the backed-up version.
                  could not restore, Lease "notification-controller-leader-election" already exists. Warning: the in-cluster version is different than the backed-up version.
                  could not restore, Lease "source-controller-leader-election" already exists. Warning: the in-cluster version is different than the backed-up version.

Backup:  flux-backup

Namespaces:
  Included:  all namespaces found in the backup
  Excluded:  <none>

Resources:
  Included:        *
  Excluded:        nodes, events, events.events.k8s.io, backups.velero.io, restores.velero.io, resticrepositories.velero.io, csinodes.storage.k8s.io, volumeattachments.storage.k8s.io, backuprepositories.velero.io
  Cluster-scoped:  auto

Namespace mappings:  <none>

Label selector:  <none>

Restore PVs:  auto

Existing Resource Policy:   <none>

Preserve Service NodePorts:  auto
```

只要将每个 velero 实例指向相同的对象存储，velero 就能将资源从一个群集迁移到另一个群集。此外还支持定时备份，触发备份 Hooks 等操作

## Helm 部署

参考：<https://github.com/jenting/velero-install/blob/main/velero/helm-install-velero-minio.sh>

```bash
helm repo add vmware-tanzu https://vmware-tanzu.github.io/helm-charts

cat <<EOF > credentials-velero
[default]
aws_access_key_id = minio
aws_secret_access_key = minio123
EOF

helm install velero \
    --namespace=velero \
    --create-namespace \
    --set-file credentials.secretContents.cloud=credentials-velero \
    --set configuration.backupStorageLocation[0].name=default \
    --set configuration.backupStorageLocation[0].provider=aws \
    --set configuration.backupStorageLocation[0].bucket=velero \
    --set configuration.backupStorageLocation[0].config.region=minio-default \
    --set configuration.backupStorageLocation[0].config.s3ForcePathStyle=true \
    --set configuration.backupStorageLocation[0].config.s3Url=http://minio-default.velero.svc.cluster.local:9000 \
    --set configuration.backupStorageLocation[0].config.publicUrl=http://localhost:9000 \
    --set configuration.backupStorageLocation[1].name=primary \
    --set configuration.backupStorageLocation[1].provider=aws \
    --set configuration.backupStorageLocation[1].bucket=velero \
    --set configuration.backupStorageLocation[1].config.region=minio-primary \
    --set configuration.backupStorageLocation[1].config.s3ForcePathStyle=true \
    --set configuration.backupStorageLocation[1].config.s3Url=http://minio-primary.velero.svc.cluster.local:9000 \
    --set configuration.backupStorageLocation[2].name=secondary \
    --set configuration.backupStorageLocation[2].provider=aws \
    --set configuration.backupStorageLocation[2].bucket=velero \
    --set configuration.backupStorageLocation[2].config.region=minio-secondary \
    --set configuration.backupStorageLocation[2].config.s3ForcePathStyle=true \
    --set configuration.backupStorageLocation[2].config.s3Url=http://minio-secondary.velero.svc.cluster.local:9000 \
    --set snapshotsEnabled=true \
    --set deployNodeAgent=true \
    --set configuration.volumeSnapshotLocation[0].name=default \
    --set configuration.volumeSnapshotLocation[0].provider=aws \
    --set configuration.volumeSnapshotLocation[0].config.region=minio-default \
    --set initContainers[0].name=velero-plugin-for-aws \
    --set initContainers[0].image=velero/velero-plugin-for-aws:v1.7.0 \
    --set initContainers[0].volumeMounts[0].mountPath=/target \
    --set initContainers[0].volumeMounts[0].name=plugins \
    vmware-tanzu/velero
```

## 其他插件

- Alibaba Cloud <https://github.com/AliyunContainerService/velero-plugin>
