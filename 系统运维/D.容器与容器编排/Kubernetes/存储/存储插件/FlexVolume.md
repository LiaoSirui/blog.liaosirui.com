## FlexVolume 简介

FlexVolume 提供了一种扩展 Kubernetes 存储插件的方式，用户可以自定义自己的存储插件。

- 插件存放位置

要使用 FlexVolume 需要在每个节点上安装存储插件二进制文件，该二进制需要实现 FlexVolume 的相关接口，默认存储插件的存放路径为 

```bash
/usr/libexec/kubernetes/kubelet-plugins/volume/exec/<vendor~driver>/<driver>
```

`VolumePlugins` 组件会不断 watch 这个目录来实现插件的添加、删除等功能。

- Pod 使用

其中 `vendor~driver` 的名字需要和 Pod 中 `flexVolume.driver` 的字段名字匹配，例如：

```
/usr/libexec/kubernetes/kubelet-plugins/volume/exec/foo~cifs/cifs
```

对应的 Pod 中的 `flexVolume.driver` 属性为：`foo/cifs`。

## 接口

- init: `<driver executable> init` - `kubelet/kube-controller-manager` 初始化存储插件时调用，插件需要返回是否需要要 attach 和 detach 操作
- attach: `<driver executable> attach <json options> <node name>` - 将存储卷挂载到 Node 节点上
- detach: `<driver executable> detach <mount device> <node name>` - 将存储卷从 Node 上卸载
- waitforattach: `<driver executable> waitforattach <mount device> <json options>` - 等待 attach 操作成功（超时时间为 10 分钟）
- isattached: `<driver executable> isattached <json options> <node name>` - 检查存储卷是否已经挂载
- mountdevice: `<driver executable> mountdevice <mount dir> <mount device> <json options>` - 将设备挂载到指定目录中以便后续 bind mount 使用
- unmountdevice: `<driver executable> unmountdevice <mount device>` - 将设备取消挂载
- mount: `<driver executable> mount <mount dir> <json options>` - 将存储卷挂载到指定目录中
- unmount: `<driver executable> unmount <mount dir>` - 将存储卷取消挂载

在实现自定义存储插件的时候，需要实现 FlexVolume 的部分接口，因为要看实际需求，并不一定所有接口都需要实现。

比如对于类似于 NFS 这样的存储就没必要实现 `attach/detach` 这些接口，因为不需要，只需要实现 `init/mount/umount` 3个接口即可。

实现上面的这些接口需要返回如下所示的 JSON 格式的数据：

```json
{
    "status": "<Success/Failure/Not supported>",
    "message": "<Reason for success/failure>",
    "device": "<Path to the device attached. This field is valid only for attach & waitforattach call-outs>",
    "volumeName": "<Cluster wide unique name of the volume. Valid only for getvolumename call-out>",
    "attached": "<True/False (Return true if volume is attached on the node. Valid only for isattached call-out)>",
    "capabilities": "<Only included as part of the Init response>"
    {
        "attach": "<True/False (Return true if the driver implements attach and detach)>"
    }
}
```

## 示例

实现一个 NFS 的 FlexVolume 插件，最简单的方式就是写一个脚本，然后实现 init、mount、unmount 3个命令即可，然后按照上面的 JSON 格式返回数据，最后把这个脚本放在节点的 FlexVolume 插件目录下面即可。

下面就是官方给出的一个 NFS 的 FlexVolume 插件示例，可以从 https://github.com/kubernetes/examples/blob/master/staging/volumes/flexvolume/nfs 获取脚本：

```bash
#!/bin/bash
# 注意:
#  - 在使用插件之前需要先安装 jq
usage() {
    err "Invalid usage. Usage: "
    err "\t$0 init"
    err "\t$0 mount <mount dir> <json params>"
    err "\t$0 unmount <mount dir>"
    exit 1
}

err() {
    echo -ne $* 1>&2
}

log() {
    echo -ne $* >&1
}

ismounted() {
    MOUNT=`findmnt -n ${MNTPATH} 2>/dev/null | cut -d' ' -f1`
    if [ "${MOUNT}" == "${MNTPATH}" ]; then
        echo "1"
    else
        echo "0"
    fi
}

domount() {
    MNTPATH=$1

    NFS_SERVER=$(echo $2 | jq -r '.server')
    SHARE=$(echo $2 | jq -r '.share')

    if [ $(ismounted) -eq 1 ] ; then
        log '{"status": "Success"}'
        exit 0
    fi

    mkdir -p ${MNTPATH} &> /dev/null

    mount -t nfs ${NFS_SERVER}:/${SHARE} ${MNTPATH} &> /dev/null
    if [ $? -ne 0 ]; then
        err "{ \"status\": \"Failure\", \"message\": \"Failed to mount ${NFS_SERVER}:${SHARE} at ${MNTPATH}\"}"
        exit 1
    fi
    log '{"status": "Success"}'
    exit 0
}

unmount() {
    MNTPATH=$1
    if [ $(ismounted) -eq 0 ] ; then
        log '{"status": "Success"}'
        exit 0
    fi

    umount ${MNTPATH} &> /dev/null
    if [ $? -ne 0 ]; then
        err "{ \"status\": \"Failed\", \"message\": \"Failed to unmount volume at ${MNTPATH}\"}"
        exit 1
    fi

    log '{"status": "Success"}'
    exit 0
}

op=$1

if ! command -v jq >/dev/null 2>&1; then
    err "{ \"status\": \"Failure\", \"message\": \"'jq' binary not found. Please install jq package before using this driver\"}"
    exit 1
fi

if [ "$op" = "init" ]; then
    log '{"status": "Success", "capabilities": {"attach": false}}'
    exit 0
fi

if [ $# -lt 2 ]; then
    usage
fi

shift

case "$op" in
    mount)
        domount $*
        ;;
    unmount)
        unmount $*
        ;;
    *)
        log '{"status": "Not supported"}'
        exit 0
esac

exit 1

```

将上面脚本命名成 nfs，放置到 devnode1 节点对应的插件下面： `/usr/libexec/kubernetes/kubelet-plugins/volume/exec/srliao~nfs/nfs`，并设置权限为 700：

```bash
chmod 700 /usr/libexec/kubernetes/kubelet-plugins/volume/exec/srliao~nfs/nfs

# 安装 jq 工具
dnf install jq -y
```

当我们要去真正的 mount NFS 的时候，就是通过 kubelet 调用 `VolumePlugin`，然后直接执行命令 `/usr/libexec/kubernetes/kubelet-plugins/volume/exec/srliao~nfs/nfs mount <mount dir> <json param>` 来完成的，就相当于平时我们在宿主机上面手动挂载 NFS 的方式一样的，所以存储插件 nfs 是一个可执行的二进制文件或者 shell 脚本都是可以的。

这个时候我们部署一个应用到 node1 节点上，并用 `flexVolume` 来持久化容器中的数据（当然也可以通过定义 flexvolume 类型的 PV、PVC 来使用），如下所示：

```yaml
# test-flexvolume.yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-flexvolume
spec:
  nodeSelector:
    kubernetes.io/hostname: devnode1
  volumes:
  - name: test
    flexVolume:
      driver: "srliao/nfs"  # 定义插件类型，根据这个参数在对应的目录下面找到插件的可执行文件
      fsType: "nfs"  # 定义存储卷文件系统类型
      options:  # 定义所有与存储相关的一些具体参数
        server: "10.244.244.201"
        share: "/data/nfs"
  containers:
  - name: web
    image: nginx
    ports:
    - containerPort: 80
    volumeMounts:
    - name: test
      subPath: testflexvolume
      mountPath: /usr/share/nginx/html
```

其中 `flexVolume.driver` 就是插件目录 `srliao~nfs` 对应的 `srliao/nfs` 名称，`flexVolume.options` 中根据上面的 nfs 脚本可以得知里面配置的是 NFS 的 Server 地址和挂载目录路径

直接创建上面的资源对象：

```bash
> kubectl apply -f test-flexvolume.yaml

> kubectl get pods test-flexvolume
NAME              READY   STATUS    RESTARTS   AGE
test-flexvolume   1/1     Running   0          12m

> kubectl exec -it test-flexvolume mount |grep test
10.244.244.201:/data/nfs/testflexvolume on /usr/share/nginx/html type nfs4 (rw,relatime,vers=4.2,rsize=1048576,wsize=1048576,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=10.244.244.211,local_lock=none,addr=10.244.244.201)

 # devnode1 节点上执行
 > mount |grep test
 10.244.244.201:/data/nfs on /var/lib/kubelet/pods/134166bb-b927-4d8f-a918-5fd54714fb9a/volumes/srliao~nfs/test type nfs4 (rw,relatime,vers=4.2,rsize=1048576,wsize=1048576,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=10.244.244.211,local_lock=none,addr=10.244.244.201)
10.244.244.201:/data/nfs/testflexvolume on /var/lib/kubelet/pods/134166bb-b927-4d8f-a918-5fd54714fb9a/volume-subpaths/test/web/0 type nfs4 (rw,relatime,vers=4.2,rsize=1048576,wsize=1048576,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=10.244.244.211,local_lock=none,addr=10.244.244.201)
```

同样我们可以查看到 Pod 的本地持久化目录是被 mount 到了 NFS 上面，证明上面我们的 FlexVolume 插件是正常的。