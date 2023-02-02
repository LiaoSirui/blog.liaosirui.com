官方：

- YAML 文件：<https://github.com/NetApp/beegfs-csi-driver/tree/v1.4.0/examples/k8s>
- 文档：<https://github.com/NetApp/beegfs-csi-driver/blob/v1.4.0/examples/k8s/README.md>

## 动态持久卷

新建一个 sc

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: csi-beegfs-dyn-sc
provisioner: beegfs.csi.netapp.com
parameters:
  sysMgmtdHost: 10.245.245.201
  volDirBasePath: k8s/test/dyn
  stripePattern/storagePoolID: "2"
  permissions/mode: "0644"
reclaimPolicy: Delete
volumeBindingMode: Immediate
allowVolumeExpansion: false

```

新建一个 PVC

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: csi-beegfs-dyn-pvc
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 100Gi
  storageClassName: csi-beegfs-dyn-sc

```

新建一个 pod 使用这个 pvc

```yaml
kind: Pod
apiVersion: v1
metadata:
  name: csi-beegfs-dyn-app
spec:
  containers:
    - name: csi-beegfs-dyn-app
      image: alpine:latest
      volumeMounts:
      - mountPath: /mnt/dyn
        name: csi-beegfs-dyn-volume
      command: [ "ash", "-c", 'touch "/mnt/dyn/touched-by-${POD_UUID}" && sleep 7d']
      env:
        - name: POD_UUID
          valueFrom:
            fieldRef:
              fieldPath: metadata.uid
  volumes:
    - name: csi-beegfs-dyn-volume
      persistentVolumeClaim:
        claimName: csi-beegfs-dyn-pvc

```

查看创建文件所属的 storagepool

```bash
>  beegfs-ctl --getentryinfo k8s/test/dyn/pvc-886dd978/touched-by-35bc160e-1d88-42fb-bb0c-d7e96a6faf44

Entry type: file
EntryID: 1-63DB17BC-1
Metadata node: devmaster [ID: 1]
Stripe pattern details:
+ Type: RAID0
+ Chunksize: 512K
+ Number of storage targets: desired: 4; actual: 3
+ Storage targets:
  + 1201 @ devnode2 [ID: 3]
  + 1001 @ devmaster [ID: 1]
  + 1101 @ devnode1 [ID: 2]
```

在 Pod 中查看挂载信息

```bash
> /mnt/dyn # df -h .
Filesystem                Size      Used Available Use% Mounted on
beegfs_nodev             44.3T    318.0G     44.0T   1% /mnt/dyn
```

到 Pod 所在节点查看挂载信息

```bash
[root@devnode1 ~]# mount | grep beegfs_nodev | grep kube
beegfs_nodev on /var/lib/kubelet/plugins/kubernetes.io/csi/beegfs.csi.netapp.com/7eadd5097ab72af44e0db30cc02c23ecab032166cef86d1f92ef02f8ad8686fd/globalmount/mount type beegfs (rw,nosuid,relatime,cfgFile=/var/lib/kubelet/plugins/kubernetes.io/csi/beegfs.csi.netapp.com/7eadd5097ab72af44e0db30cc02c23ecab032166cef86d1f92ef02f8ad8686fd/globalmount/beegfs-client.conf)
beegfs_nodev on /var/lib/kubelet/pods/35bc160e-1d88-42fb-bb0c-d7e96a6faf44/volumes/kubernetes.io~csi/pvc-886dd978/mount type beegfs (rw,nosuid,relatime,cfgFile=/var/lib/kubelet/plugins/kubernetes.io/csi/beegfs.csi.netapp.com/7eadd5097ab72af44e0db30cc02c23ecab032166cef86d1f92ef02f8ad8686fd/globalmount/beegfs-client.conf)
```

删除 Pod 和 PVC 后观察 PV 以及宿主机上的 Mount 信息

- PV 被删除
- Beegfs 中的文件被清理
- 挂载信息被清理

## 动态临时卷

新建一个 sc

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: csi-beegfs-ge-sc
provisioner: beegfs.csi.netapp.com
parameters:
  sysMgmtdHost: 10.245.245.201
  volDirBasePath: k8s/name/ge
  stripePattern/storagePoolID: "2"
  permissions/mode: "0644"
reclaimPolicy: Delete
volumeBindingMode: Immediate
allowVolumeExpansion: false

```

新建一个 pod 创建动态 pvc

```yaml
kind: Pod
apiVersion: v1
metadata:
  name: csi-beegfs-ge-app
spec:
  containers:
    - name: csi-beegfs-ge-app
      image: alpine:latest
      volumeMounts:
      - mountPath: /mnt/ge
        name: csi-beegfs-ge-volume
      command: [ "ash", "-c", 'touch "/mnt/ge/touched-by-${POD_UUID}" && sleep 7d']
      env:
        - name: POD_UUID
          valueFrom:
            fieldRef:
              fieldPath: metadata.uid
  volumes:
    - name: csi-beegfs-ge-volume
      ephemeral:
        volumeClaimTemplate:
          spec:
            accessModes:
            - ReadWriteMany
            resources:
              requests:
                storage: 100Gi
            storageClassName: csi-beegfs-ge-sc

```

动态临时卷和动态持久卷类似，只是建立 pvc 的方式不同

不同点：

- Pod 删除后，PVC 和 PV 都会被自动删除

## 静态持久卷

手动建立一个 pv

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: csi-beegfs-static-pv
spec:
  accessModes:
  - ReadWriteMany
  capacity:
    storage: 100Gi
  persistentVolumeReclaimPolicy: Retain
  csi:
    driver: beegfs.csi.netapp.com
    # Ensure that the directory, e.g. "k8s/all/static", exists on BeeGFS.
    # The driver will not create the directory.
    volumeHandle: beegfs://10.245.245.201/k8s/all/static

```

新建 PVC 和 Pod 使用这个 PV

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: csi-beegfs-static-pvc
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 100Gi
  storageClassName: ""
  volumeName: csi-beegfs-static-pv

---
kind: Pod
apiVersion: v1
metadata:
  name: csi-beegfs-static-app
spec:
  containers:
    - name: csi-beegfs-static-app
      image: alpine:latest
      volumeMounts:
      - mountPath: /mnt/static
        name: csi-beegfs-static-volume 
      command: [ "ash", "-c", 'touch "/mnt/static/touched-by-k8s-name-${POD_UUID}" && sleep 7d']
      env:
        - name: POD_UUID
          valueFrom:
            fieldRef:
              fieldPath: metadata.uid
  volumes:
    - name: csi-beegfs-static-volume
      persistentVolumeClaim:
        claimName: csi-beegfs-static-pvc

```

如果这个目录没有提前创建，会发生如下错误

```bash
MountVolume.MountDevice failed for volume "csi-beegfs-static-pv" : rpc error: code = NotFound desc = beegfs-ctl failed with stdOut: and stdErr: Unable to find metadata node for path: /k8s/all/static Error: Path does not exist
```

默认创建的挂载会在 storagepool 1 中，如下：

```bash
> beegfs-ctl --getentryinfo k8s/all/static

Entry type: directory
EntryID: 1-63DB1BAC-1
Metadata node: devmaster [ID: 1]
Stripe pattern details:
+ Type: RAID0
+ Chunksize: 512K
+ Number of storage targets: desired: 4
+ Storage Pool: 1 (Default)
```

如有需要，可以手动更改 storagepool

```bash
beegfs-ctl --setpattern --storagepoolid=2 k8s/all/static
```

## 静态只读持久卷

与静态持久卷方式相同，不同的是 PVC 设置为只读

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: csi-beegfs-static-ro-pv
spec:
  accessModes:
  - ReadOnlyMany
  capacity:
    storage: 5Gi
  persistentVolumeReclaimPolicy: Retain
  csi:
    driver: beegfs.csi.netapp.com
    volumeHandle: beegfs://10.245.245.201/k8s/all/static

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: csi-beegfs-static-ro-pvc
spec:
  accessModes:
  - ReadOnlyMany
  resources:
    requests:
      storage: 5Gi
  storageClassName: ""
  volumeName: csi-beegfs-static-ro-pv

```

