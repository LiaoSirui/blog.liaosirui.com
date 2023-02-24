## KubeVirt 简介

Kubevirt 是 Redhat 开源一套以容器方式运行虚拟机的项目，通过 kubernetes 云原生来管理虚拟机生命周期。KubeVirt 是一个 kubernetes 插件，在调度容器之余也可以调度传统的虚拟机。

它通过使用自定义资源（CRD）和其它 Kubernetes 功能来无缝扩展现有的集群，以提供一组可用于管理虚拟机的虚拟化的 API。CRD 形式将 VM 管理接口接入到 kubernetes，通过一个 podvirtd 方式，实现管理 pod 与以 lib 的 VM 接口，以作为容器通用的虚拟管理机，并使用与容器相同的资源管理、调度计划。

<img src=".assets/architecture-simple.png" alt="img" style="zoom:20%;" />

官方：

- 官网：<https://kubevirt.io/>
- 文档：<https://kubevirt.io/user-guide/>
- GitHub 仓库：<https://github.com/kubevirt/kubevirt>

## Kubevirt 架构设计

### CRD 资源

kubevirt 主要实现了下面几种资源，以实现对虚拟机的管理：

- VirtualMachineInstance（VMI）

类似于 kubernetes Pod，是管理虚拟机的最小资源。一个 VirtualMachineInstance 对象即表示一台正在运行的虚拟机实例，包含一个虚拟机所需要的各种配置。

通常情况下用户不会直接创建 VMI 对象，而是创建更高层级的对象，即 VM 和 VMRS。

- VirtualMachine（VM）

为集群内的 VirtualMachineInstance 提供管理功能，例如开机、关机、重启虚拟机，确保虚拟机实例的启动状态，与虚拟机实例是 `1:1` 的关系，类似与 `spec.replica` 为 1 的 StatefulSet。

- VirtualMachineInstanceReplicaSet

类似 ReplicaSet，可以启动指定数量的 VirtualMachineInstance，并且保证指定数量的 VirtualMachineInstance 运行，可以配置 HPA。

### 整体架构

Kubevirt 的整体架构：

<img src=".assets/architecture.png" alt="img" style="zoom:20%;" />



##### `virt-api`

- kubevirt 是 CRD 形式管理 vm pod，virt-api 就是去所有虚拟化操作的入口，包括常规的 CRD 更新验证以及 vm 的 start、stop

##### `virt-controlller`

- virt-controller 会根据 VMI CRD，生成 virt-lancher pod，并维护 CRD 的状态

##### `virt-handler`

- `virt-handler` 会以 Daemonset 的状态部署在每个节点上，负责监控上每个虚拟机实例的状态变化，一旦检测到变化，会进行响应并确保相应的操作能够达到要求的状态。
- `virt-handler` 保持集群级之间的同步规范，与 libvirt 的同步报告 libvirt 和集群的规范；调用以节点为中心的变化域 VMI 规范定义的网络状态和管理要求。

##### `virt-launcher`

- `virt-lanuncher pod` 一个 VMI，kubelet 只是负责运行状态，不会去关心 `virt-lanuncher pod` VMI 创建情况。
- `virt-handler` 会根据 CRD 参数配置去通知 virt-lanuncher 去使用本地 libvirtd 实例来启动 VMI，virt-lanuncher 会通过 pid 去管理 VMI，如果 pod 生命周期结束，virt-lanuncher 也会去通知 VMI 去终止。
- 然后再去启动一个 libvirtd，去启动 virt-lanuncher pod，通过 libvirtd 去管理 VM 的生命周期，不再是以前的机器那套，libvirtd 去管理多个 VM。

##### `libvirtd`

- `libvirtd` 每个 VMI pod 中都有一个 的实例。`virt-launcher` 使用 libvirtd 来管理 VMI 进程的生命周期。

##### `virtctl`

- virctl 是 kubevirt 自带控制类似 kubectl 命令，它是越过 virt-lancher pod 这层去直接管理 vm，可以完成 vm 的 start、stop、restart。

## 虚拟机流程

VM 的内部流程：

1. K8S API 创建 VMI CRD 对象
2. `virt-controller` 监听到 `VMI` 创建时间，会根据 VMI 配置生成 pod spec 文件，创建 `virt-launcher pods`
3. `virt-controller` 发现 virt-launcher pod 创建完成后，更新 VMI CRD 状态
4. `virt-handler` 监听到 VMI 状态变更，通信 `virt-launcher` 去创建虚拟机，并负责虚拟机生命周期管理

```plain
Client                     K8s API     VMI CRD  Virt Controller         VMI Handler
-------------------------- ----------- ------- ----------------------- ----------

                           listen <----------- WATCH /virtualmachines
                           listen <----------------------------------- WATCH /virtualmachines
                                                  |                       |
POST /virtualmachines ---> validate               |                       |
                           create ---> VMI ---> observe --------------> observe
                             |          |         v                       v
                           validate <--------- POST /pods              defineVMI
                           create       |         |                       |
                             |          |         |                       |
                           schedPod ---------> observe                    |
                             |          |         v                       |
                           validate <--------- PUT /virtualmachines       |
                           update ---> VMI ---------------------------> observe
                             |          |         |                    launchVMI
                             |          |         |                       |
                             :          :         :                       :
                             |          |         |                       |
DELETE /virtualmachines -> validate     |         |                       |
                           delete ----> * ---------------------------> observe
                             |                    |                    shutdownVMI
                             |                    |                       |
                             :                    :                       :
```

## 磁盘和卷

虚拟机镜像（磁盘）是启动虚拟机必不可少的部分，KubeVirt 中提供多种方式的虚拟机磁盘，虚拟机镜像（磁盘）使用方式非常灵活。

这里列出几种比较常用的：

- PersistentVolumeClaim 

使用 PVC 做为后端存储，适用于数据持久化，即在虚拟机重启或者重建后数据依旧存在。使用的 PV 类型可以是 block 和 filesystem，使用 filesystem 时，会使用 PVC 上的 `/disk.img`，格式为 RAW 格式的文件作为硬盘。block 模式时，使用 block volume 直接作为原始块设备提供给虚拟机。

- ephemeral

基于后端存储在本地做一个写时复制（COW）镜像层，所有的写入都在本地存储的镜像中，VM 实例停止时写入层就被删除，后端存储上的镜像不变化。

- containerDisk

基于 scratch 构建的一个 docker image，镜像中包含虚拟机启动所需要的虚拟机镜像，可以将该 docker image push 到 registry，使用时从 registry 拉取镜像，直接使用 containerDisk 作为 VMI 磁盘，数据是无法持久化的。

- hostDisk

使用节点上的磁盘镜像，类似于 hostpath，也可以在初始化时创建空的镜像。

- dataVolume

提供在虚拟机启动流程中自动将虚拟机磁盘导入 pvc 的功能，在不使用 DataVolume 的情况下，用户必须先准备带有磁盘映像的 pvc，然后再将其分配给 VM 或 VMI。dataVolume 拉取镜像的来源可以时 http，对象存储，另一块 PVC 等。


## KubeVirt 安装

需要先开启宿主机的虚拟化支持

## 参考资料

- <https://cloud.tencent.com/developer/article/1587640>
- <https://www.informaticar.net/setup-virtualization-on-red-hat-8/>
- <https://blog.csdn.net/BY_xiaopeng/article/details/124458361>
- <https://freewechat.com/a/MzI1OTY2MzMxOQ==/2247494070/1>
- 如何使用 Kubevirt 管理 Kubernetes 中的虚拟机 https://mp.weixin.qq.com/s/UFxPutqcuA19HsHtDsCeBQ
- kubevirt（一）虚拟化技术 <https://mp.weixin.qq.com/s?__biz=MzAwMDQyOTcwOA==&mid=2247485409&idx=1&sn=5a8990a27b56cc693490e9a9e172768f&chksm=9ae85c02ad9fd514b740178d3b78added9aa0f776b67156a0b0367e91a694e6fe4eb901d7d68&scene=178&cur_album_id=2573510573263667200#rd>
- kubevirt（二）实现原理 https://mp.weixin.qq.com/s?__biz=MzAwMDQyOTcwOA==&mid=2247485425&idx=1&sn=0bd289c71671b19b1db1651a4b646882&chksm=9ae85c12ad9fd50451f3c53427e2818e3d71ecbacecd2d0828f7601f3e49503c752cf0c4218a&scene=178&cur_album_id=2573510573263667200#rd
- kubevirt（三）迁移（migration）https://mp.weixin.qq.com/s/Wx7RSBlW23pVpHkvngkJMw
- kubevirt（四）热插拔卷（hotplug volume）https://mp.weixin.qq.com/s/z5chVax1m-m3e2JBs9rdUA

- <https://www.infvie.com/ops-notes/kubernetes-kubevirt-virtual-machine-management.html>