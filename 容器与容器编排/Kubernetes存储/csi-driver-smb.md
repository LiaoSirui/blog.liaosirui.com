仓库地址：<https://github.com/kubernetes-csi/csi-driver-smb>

与 csi-driver-nfs 的使用方式基本相同

认证：

```yaml
parameters:
  csi.storage.k8s.io/node-stage-secret-name: smb-nas-creds
  csi.storage.k8s.io/node-stage-secret-namespace: cpaas-storage-system
```

