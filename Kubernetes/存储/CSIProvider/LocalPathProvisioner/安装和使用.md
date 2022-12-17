
## 简介

项目地址 <https://github.com/rancher/local-path-provisioner>

最新版本安装的 yaml 文件：<https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.22/deploy/local-path-storage.yaml>

kubernetes 提供的 local path 给持久化提供了相当大的便利, 但有一个问题是, 每次都需要手动提前在机器上创建相应的目录来做为被调度应用的持久化目录, 不是很方便, 有没有办法可以自动创建呢?

rancher也提供了相应的工具 local-path-provisioner

## 简单的使用

原版的：<https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.22/deploy/local-path-storage.yaml>

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: local-path-storage

---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: local-path-provisioner-service-account
  namespace: local-path-storage

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: local-path-provisioner-role
rules:
  - apiGroups: [ "" ]
    resources: [ "nodes", "persistentvolumeclaims", "configmaps" ]
    verbs: [ "get", "list", "watch" ]
  - apiGroups: [ "" ]
    resources: [ "endpoints", "persistentvolumes", "pods" ]
    verbs: [ "*" ]
  - apiGroups: [ "" ]
    resources: [ "events" ]
    verbs: [ "create", "patch" ]
  - apiGroups: [ "storage.k8s.io" ]
    resources: [ "storageclasses" ]
    verbs: [ "get", "list", "watch" ]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: local-path-provisioner-bind
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: local-path-provisioner-role
subjects:
  - kind: ServiceAccount
    name: local-path-provisioner-service-account
    namespace: local-path-storage

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: local-path-provisioner
  namespace: local-path-storage
spec:
  replicas: 1
  selector:
    matchLabels:
      app: local-path-provisioner
  template:
    metadata:
      labels:
        app: local-path-provisioner
    spec:
      serviceAccountName: local-path-provisioner-service-account
      containers:
        - name: local-path-provisioner
          image: rancher/local-path-provisioner:v0.0.22
          imagePullPolicy: IfNotPresent
          command:
            - local-path-provisioner
            - --debug
            - start
            - --config
            - /etc/config/config.json
          volumeMounts:
            - name: config-volume
              mountPath: /etc/config/
          env:
            - name: POD_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
      volumes:
        - name: config-volume
          configMap:
            name: local-path-config

---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-path
provisioner: rancher.io/local-path
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Delete

---
kind: ConfigMap
apiVersion: v1
metadata:
  name: local-path-config
  namespace: local-path-storage
data:
  config.json: |-
    {
            "nodePathMap":[
            {
                    "node":"DEFAULT_PATH_FOR_NON_LISTED_NODES",
                    "paths":["/opt/local-path-provisioner"]
            }
            ]
    }
  setup: |-
    #!/bin/sh
    set -eu
    mkdir -m 0777 -p "$VOL_DIR"
  teardown: |-
    #!/bin/sh
    set -eu
    rm -rf "$VOL_DIR"
  helperPod.yaml: |-
    apiVersion: v1
    kind: Pod
    metadata:
      name: helper-pod
    spec:
      containers:
      - name: helper-pod
        image: busybox
        imagePullPolicy: IfNotPresent
```

- 创建命名空间

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: aipaas-system
```

- 创建 SA

```yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: local-path-provisioner-service-account
  namespace: aipaas-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: local-path-provisioner-role
rules:
  - apiGroups: [ "" ]
    resources: [ "nodes", "persistentvolumeclaims", "configmaps" ]
    verbs: [ "get", "list", "watch" ]
  - apiGroups: [ "" ]
    resources: [ "endpoints", "persistentvolumes", "pods" ]
    verbs: [ "*" ]
  - apiGroups: [ "" ]
    resources: [ "events" ]
    verbs: [ "create", "patch" ]
  - apiGroups: [ "storage.k8s.io" ]
    resources: [ "storageclasses" ]
    verbs: [ "get", "list", "watch" ]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: local-path-provisioner-bind
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: local-path-provisioner-role
subjects:
  - kind: ServiceAccount
    name: local-path-provisioner-service-account
    namespace: aipaas-system
```

- 创建配置

```yaml
kind: ConfigMap
apiVersion: v1
metadata:
  name: local-path-config
  namespace: aipaas-system  
data:
  config.json: |-
        {
                "nodePathMap":[
                {
                        "node":"DEFAULT_PATH_FOR_NON_LISTED_NODES",
                        "paths":["/opt/local-path-provisioner"]
                }
                ]
        }
  setup: |-
    #!/bin/sh
    set -eu
    mkdir -m 0755 -p "$VOL_DIR"
  teardown: |-
    #!/bin/sh
    set -eu
    rm -rf "$VOL_DIR"
  helperPod.yaml: |-
    apiVersion: v1
    kind: Pod
    metadata:
      name: helper-pod
    spec:
      containers:
      - name: helper-pod
        image: busybox
        imagePullPolicy: IfNotPresent
```

- 创建 Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: local-path-provisioner
  namespace: aipaas-system
spec:
  replicas: 1
  selector:
    matchLabels:
      app: local-path-provisioner
  template:
    metadata:
      labels:
        app: local-path-provisioner
    spec:
      serviceAccountName: local-path-provisioner-service-account
      containers:
        - name: local-path-provisioner
          image: rancher/local-path-provisioner:v0.0.22
          imagePullPolicy: IfNotPresent
          command:
            - local-path-provisioner
            - --debug
            - start
            - --config
            - /etc/config/config.json
          volumeMounts:
            - name: config-volume
              mountPath: /etc/config/
          env:
            - name: POD_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
      volumes:
        - name: config-volume
          configMap:
            name: local-path-config
```

- 创建 StorageClass

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-path
provisioner: rancher.io/local-path
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Delete
# reclaimPolicy: Retain
```

## 官方示例

```bash
kubectl create -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/examples/pvc/pvc.yaml
kubectl create -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/examples/pod/pod.yaml
```

创建 pvc

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: local-path-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-path
  resources:
    requests:
      storage: 128Mi
```

创建 pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: volume-test
spec:
  containers:
  - name: volume-test
    image: nginx:stable-alpine
    imagePullPolicy: IfNotPresent
    volumeMounts:
    - name: volv
      mountPath: /data
    ports:
    - containerPort: 80
  volumes:
  - name: volv
    persistentVolumeClaim:
      claimName: local-path-pvc
```

生成的 helper pod

```yaml
kind: Pod
apiVersion: v1
metadata:
  name: helper-pod-create-pvc-3dae5c11-c901-41fd-ba9e-be6a53248383
  namespace: aipaas-system
  annotations:
    cni.projectcalico.org/containerID: aff10b06cda7b33a020b1466a2a1f8e8779845da670732672748028c1280e705
    cni.projectcalico.org/podIP: 10.4.198.233/32
    cni.projectcalico.org/podIPs: 10.4.198.233/32
spec:
  restartPolicy: Never
  serviceAccountName: local-path-provisioner-service-account
  priority: 0
  schedulerName: default-scheduler
  enableServiceLinks: true
  terminationGracePeriodSeconds: 30
  preemptionPolicy: PreemptLowerPriority
  nodeName: devmaster2
  securityContext: {}
  containers:
    - resources: {}
      terminationMessagePath: /dev/termination-log
      name: helper-pod
      command:
        - /bin/sh
        - /script/setup
      env:
        - name: VOL_DIR
          value: >-
            /opt/local-path-provisioner/pvc-3dae5c11-c901-41fd-ba9e-be6a53248383_aipaas-system_local-path-pvc
        - name: VOL_MODE
          value: Filesystem
        - name: VOL_SIZE_BYTES
          value: '134217728'
      imagePullPolicy: IfNotPresent
      volumeMounts:
        - name: script
          mountPath: /script
        - name: data
          mountPath: /opt/local-path-provisioner/
        - name: kube-api-access-w6h59
          readOnly: true
          mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      terminationMessagePolicy: File
      image: busybox
      args:
        - '-p'
        - >-
          /opt/local-path-provisioner/pvc-3dae5c11-c901-41fd-ba9e-be6a53248383_aipaas-system_local-path-pvc
        - '-s'
        - '134217728'
        - '-m'
        - Filesystem
  serviceAccount: local-path-provisioner-service-account
  volumes:
    - name: data
      hostPath:
        path: /opt/local-path-provisioner/
        type: DirectoryOrCreate
    - name: script
      configMap:
        name: local-path-config
        items:
          - key: setup
            path: setup
          - key: teardown
            path: teardown
        defaultMode: 420
    - name: kube-api-access-w6h59
      projected:
        sources:
          - serviceAccountToken:
              expirationSeconds: 3607
              path: token
          - configMap:
              name: kube-root-ca.crt
              items:
                - key: ca.crt
                  path: ca.crt
          - downwardAPI:
              items:
                - path: namespace
                  fieldRef:
                    apiVersion: v1
                    fieldPath: metadata.namespace
        defaultMode: 420
  dnsPolicy: ClusterFirst
  tolerations:
    - operator: Exists
```

如果 pvc 设置 label，这种情况是不支持的

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: local-path-pvc1
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-path
  resources:
    requests:
      storage: 128Mi
  selector: 
    matchLabels:
      user: srliao
```

## 配置

配置里是可以对不同的 node 指定不同的 path, 如果未指定 node， 则使用默认值

```yaml
kind: ConfigMap
apiVersion: v1
metadata:
  name: local-path-config
  namespace: aipaas-system
data:
  config.json: |-
        {
                "nodePathMap":[
                {
                        "node":"DEFAULT_PATH_FOR_NON_LISTED_NODES",
                        "paths":["/opt/local-path-provisioner"]
                },
                {
                        "node":"yasker-lp-dev1",
                        "paths":["/opt/local-path-provisioner", "/data1"]
                },
                {
                        "node":"yasker-lp-dev3",
                        "paths":[]
                }
                ]
        }
  setup: |-
        #!/bin/sh
        set -eu
        mkdir -m 0777 -p "$VOL_DIR"
  teardown: |-
        #!/bin/sh
        set -eu
        rm -rf "$VOL_DIR"
  helperPod.yaml: |-
        apiVersion: v1
        kind: Pod
        metadata:
          name: helper-pod
        spec:
          containers:
          - name: helper-pod
            image: busybox
```

The scripts receive their input as environment variables:

| Environment variable | Description                                              |
| ---------------------- | ---------------------------------------------------------- |
| `VOL_DIR`          | Volume directory that should be created or removed.      |
| `VOL_MODE`         | The PersistentVolume mode (`Block` or `Filesystem`). |
| `VOL_SIZE_BYTES`   | Requested volume size in bytes.                          |

### Scripts `setup` and `teardown` and the `helperPod.yaml` template

- The `setup` script is run before the volume is created, to prepare the volume directory on the node.
- The `teardown` script is run after the volume is deleted, to cleanup the volume directory on the node.
- The `helperPod.yaml` template is used to create a helper Pod that runs the `setup` or `teardown` script.

## 不足

通过这种方式我们可以不再需要生成 pv, 直接使用 pvc 即可，但还是有些不足的地方,目前还不支持对持久化目录做到可以限制使用大小

另外，kubernetes sig 也出了一个对于 local volume 的工具 sig-storage-local-static-provisioner 相对来说更加通用，但是也有不足的地方，感兴趣的可以参考

- [https://github.com/kubernetes-sigs/sig-storage-local-static-provisioner](https://github.com/kubernetes-sigs/sig-storage-local-static-provisioner)

## 其他

<https://blog.csdn.net/styshoo/article/details/123221890>

Kubernetes配置多个local-path-provisioner

local-path-provisioner可设置环境变量PROVISIONER_NAME，只要该环境变量的值，与新创建local-path的存储类中的provisioner值一致即可。

StorageClass

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-path-new
provisioner: provisioner-new
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Retain

```