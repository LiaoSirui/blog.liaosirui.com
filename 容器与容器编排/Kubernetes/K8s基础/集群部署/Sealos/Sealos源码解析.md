## 概述

`sealos run` 是一个声明式 reconcile 循环：把「集群镜像列表 + master/node IP 列表」当作期望状态(desired)，把本地 `~/.sealos/<cluster>/Clusterfile` 当作当前状态(current)，两者做 diff，然后选择走 新建(Create)、装应用/升级(Install)、扩缩容(Scale) 三条流水线中的一条或多条，最后把结果回写到 Clusterfile。

核心代码都在：<https://github.com/labring/sealos/tree/v5.1.2-rc6/lifecycle>

### 集群镜像类型

| label | 常量 | 语义 | 分发到哪些节点 | 谁来跑 entrypoint |
| --- | --- | --- | --- | --- |
| `rootfs` | `v2.RootfsImage` | k8s 本体(kubeadm/kubelet/crictl 二进制、containerd、registry、脚本) | 所有 master + node | 所有节点 |
| `patch` | `v2.PatchImage` | 覆盖/补丁 rootfs 的一部分 | 所有 master + node | 所有节点 |
| 空 或 `application` | `v2.AppImage` | 应用(calico / helm chart / yaml) | 只发 master0 | 只在 master0 |

类型由镜像 label 决定

```bash
sealos.io.type
apps.sealos.io/type
```

<https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/types/v1beta1/cluster.go#L75-L86>

类型判断的代码：<https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/types/v1beta1/cluster.go#L106-L116>

- `sealos.io.version`：必须是 `v1beta1` / `v1beta2`，否则 rootfs 镜像被拒 <https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/apply/processor/interface.go#L176-L243>

- label `version` 只有 rootfs 类型的镜像才会返回非空，这正是升级的触发开关 <https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/types/v1beta1/cluster.go#L99-L104>

- `sealos.io.distribution` → 决定用 kubeadm 还是 k3s runtime <https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/types/v1beta1/utils.go#L187-L193>

### Clusterfile

位置：`~/.sealos/<clusterName>/Clusterfile`

### 目录布局

<https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/constants/pathresolver.go>

```
远端(每个节点)：
/var/lib/sealos/data/<cluster>/            # Root()
├── rootfs/                                # RootFSPath()  ← rootfs 镜像内容 copy 到这里
│   ├── bin/                               # kubeadm kubelet kubectl ...
│   ├── etc/                               # 模板渲染目标
│   ├── scripts/                           # check.sh init.sh clean.sh init-registry.sh ...
│   ├── manifests/                         # 模板渲染目标
│   ├── statics/                           # audit-policy.yml 等静态文件
│   ├── registry/                          # 软链到实际 registry 数据目录
│   └── opt/sealctl                        # RootFSSealctlPath()
└── etc/                                   # ConfigsPath()：kubeadm-init.yaml / kubeadm-join-*.yaml

本地：
~/.sealos/<cluster>/                       # RunRoot()
├── Clusterfile
├── pki/  pki/etcd/                        # 本地签发的 CA 与叶子证书
├── etc/                                   # admin.conf / controller-manager.conf / scheduler.conf
└── tmp/                                   # 生成中间配置、升级 staging
```

### 调用链总览

```bash
cmd/sealos/cmd/run.go            newRunCmd()
  └─ buildah.PreloadIfTarFile()               # -t oci-archive/docker-archive 时先 load tar
  └─ apply.NewApplierFromArgs()               # pkg/apply/run.go
       ├─ clusterfile.NewClusterFile().Process()
       ├─ ClusterArgs.runArgs()               # 参数校验 + 探测 arch + 组装 Spec.Hosts
       └─ applydrivers.NewDefaultApplier()
  └─ applier.Apply()                          # pkg/apply/applydrivers/apply_drivers_default.go
       ├─ 无 current  → initCluster()   → processor.CreateProcessor
       └─ 有 current  → reconcileCluster()
                          ├─ installApp()  → processor.InstallProcessor (含升级)
                          └─ scaleCluster()→ processor.ScaleProcessor  (扩容 / 缩容)
       └─ applyAfter()： saveClusterFile() + syncWorkdir()
```

## 全新部署

<https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/apply/processor/create.go#L61-L80>

```bash
Check
  → PreProcess
    → RunConfig
      → MountRootfs
        → MirrorRegistry
          → Bootstrap
            → Init
              → Join
                → RunGuest
```

### Check

<https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/checker/check_list.go#L33-L40>

`IPsHostChecker`(SSH 可达 + hostname 不重复)和 `ContainerdChecker`(是否已有冲突的 containerd)。`pkg/checker/` 下还有 cluster/node/pod/svc/registry/crictl/cri-shim/initsystem 等 checker，主要给 `sealos status` 和 post 阶段用。

### PreProcess

<https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/apply/processor/interface.go#L176-L243>

- 对 `Spec.Image` 逐个 `InspectImage`(本地找不到就 fallback 到 `docker` transport 远端 inspect)。
- 校验 rootfs 镜像的 `sealos.io.version`。
- `buildah pull --policy missing` → `buildah create` 得到一个 container + 可读写 mountpoint(overlayfs 的 `merged` 目录)。
  - 注释里点明了为什么每次都重建 container：宿主机重启后 overlay 的 `merged` 会变成空目录。
- `OCIToImageMount` 把 OCI config 翻译成 `MountImage`：Env / Entrypoint / Cmd / Labels / Type。
- 必须至少有一个 rootfs 类型镜像，否则报 `can't apply application type images only`。
- Env 优先级(低 → 高)：镜像自带 Env < `cluster.Spec.Env` < `-e` 命令行(`ExtraEnvs`)。
- 最后 `factory.New()` 按 distribution 选 runtime：kubeadm 或 k3s

### RunConfig

对每个 mount 并发跑 `config.NewConfiguration(...).Dump()` —— 把 Clusterfile 里的 `Config` 对象(`apiVersion： apps.sealos.io/v1beta1， kind： Config`)patch/覆盖进镜像 mountpoint 里对应的文件

### MountRootfs

<https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/filesystem/rootfs/rootfs_default.go#L58-L173>

- 本地渲染：`env.RenderAll` 处理 mountpoint 里的 `*.tmpl`，然后 `chmod -R 0755`。

- 按节点并发分发：对 rootfs/patch 类型 `ssh.CopyDir` 到远端 `RootFSPath()`，过滤掉 `registry/` 目录(registry 之后会进行同步)。然后把本地 `sealctl` 二进制同步过去(先比 sha256 + 比 arch，一致就跳过)，再远端执行 `sealctl render --clear etc scripts manifests` 做二次渲染。

  - 注入的内建 env：`SEALOS_SYS_KUBE_VERSION`、`SEALOS_SYS_SEALOS_VERSION`、`SEALOS_SYS_RUN_MODE`(该节点的 roles)。

- app 类型只发 master0，目标是 `GetAppWorkDir()` = `/var/lib/sealos/data/<cluster>/applications/<ctr>/workdir`。

### MirrorRegistry

<https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/filesystem/registry/sync.go>

- 如果所有 mount 里都没有 `registry/` 目录，直接跳过。
- 对每个 registry 节点：先探测 `sealctl registry serve filesystem` 支持哪些 flag，然后远端起一个临时 registry (默认 5050 端口)，本地也起一个临时 registry 指向 mountpoint 的 `registry/` 目录，用 `containers/image` 的 copy 做 HTTP registry-to-registry 同步。
- HTTP 起不来就 fallback 到 SSH 模式(直接 `CopyDir` 整个 registry 目录)。
- 退出时 kill 临时 registry(通过 pid file + `/proc/<pid>/cmdline` 校验，避免误杀)。

### Bootstrap

三个 phase(Preflight / Init / Postflight)，每个 applier 在所有节点上并发执行完，才进入下一个 applier

<https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/bootstrap/bootstrap.go#L63-L82>

内置 applier 顺序

<https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/bootstrap/bootstrap.go#L155-L158>

| # | Applier | Filter | 动作 |
| --- | --- | --- | --- |
| P1 | `defaultChecker` | 全部 | `bash check.sh` |
| I1 | `registryHostApplier` | 全部 | `/etc/hosts` 加 registry 域名 → registry IP |
| I2 | `registryApplier` | 仅 registry 节点 | 软链 registry 数据目录、更新 registry 密码、`bash init-registry.sh`、`WaitRegistryReady` |
| I3 | `defaultCRIInitializer` | 全部 | `bash init-cri.sh`(镜像 label 没提供就跳过) |
| I4 | `apiServerHostApplier` | 全部 | master：`/etc/hosts` → master0 IP;node：→ VIP |
| I5 | `lvscareHostApplier` | 仅 node | `/etc/hosts` 加 lvscare 域名 → 本机 IP |
| I6 | `defaultInitializer` | 全部 | `bash init.sh` |

`Delete()` 是 逆序执行 Undo(postflight → init → preflight)，对应 `clean.sh` / `clean-registry.sh` / `clean-cri.sh`。

脚本名可以被镜像 label 覆盖

<https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/types/v1beta1/utils.go#L170-L176>s

### Init

kubeadm 实现

<https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/runtime/kubernetes/runtime.go#L51-L58>

```go
runPipelines("init masters"，
    k.InitKubeadmConfigToMaster0，   // 本地生成 kubeadm-init.yaml → scp 到 master0 的 ConfigsPath
    k.InitCertsAndKubeConfigs，      // 本地签发 PKI + kubeconfig，再送到 master0
    k.CopyStaticFilesToMasters，     // audit-policy.yml → /etc/kubernetes/
    k.InitMaster0，                  // imagePull + kubeadm init
)
```

关键设计：证书是 sealos 在本地签的，不是 kubeadm 签的。

[`GenerateCert`](../pkg/runtime/kubernetes/init.go#L46-L70) 用 

- `cert.GenerateCertForKubeVersion` 在本地 `~/.sealos/<cluster>/pki` 生成全套 CA + 叶子证书(certSANs 里包含 apiserver 域名、VIP、所有 master IP)
- `CreateKubeConfigFiles` 生成 admin/controller-manager/scheduler 的 kubeconfig，然后一起 scp 到 master0。好处是多 master 共享同一套 CA、后续 `sealos cert` 可以离线换 SAN。

InitMaster0 <https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/runtime/kubernetes/master.go#L38-L53>

- [`imagePull`](../pkg/runtime/kubernetes/master.go#L55-L98)：`WaitRegistryReady` → `kubeadm config images list -o json` → 把镜像地址里的 registry 域名替换成集群内 registry → 逐个 `crictl pull`。这是离线安装的关键一步。<https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/runtime/kubernetes/master.go#L55-L98>
- `kubeadm init --config=<ConfigsPath>/kubeadm-init.yaml --skip-certificate-key-print --skip-token-print --ignore-preflight-errors=SystemVerification` <https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/runtime/kubernetes/commands.go>
- `copyMasterKubeConfig` → 远端 `$HOME/.kube/config`。

### Join

ScaleUp <https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/runtime/kubernetes/runtime.go#L96-L111>

- join master

`ssh.WaitReady` → 拷静态文件 → `setKubernetesToken`(通过 kubeadm 上传 control-plane 共享证书，把 `certificateKey` 嵌进 join config)→ 并发生成并下发各 master 的 `kubeadm-join-master.yaml` → 串行 逐个 `imagePull` + `kubeadm join` + 改 `/etc/hosts` + copy kubeconfig。

<https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/runtime/kubernetes/master.go#L133-L185>

- join node

并发执行：下发 join-node config → `execIPVS`(在 node 上跑一次 lvscare，建立 VIP → 所有 master 的 IPVS 规则)→ `kubeadm join`。

<https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/runtime/kubernetes/node.go#L30-L72>

### RunGuest

跑镜像的 entrypoint/cmd

<https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/guest/guest.go#L43-L80>

- rootfs/patch：在所有目标节点并发执行。
- application：只在 master0 执行。
- 命令来源：`Entrypoint` + `Cmd`，做 `$VAR` 展开 `expansion.Expand` <https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/fork/golang/expansion/expand.go>；`index == 0 && len(cluster.Spec.Command) > 0` 时用 `--cmd` 覆盖第一个镜像的 Cmd。
- 执行时 `cd` 到该镜像的 workdir(app 是 `applications/<name>/workdir`，rootfs 是 `rootfs/`)，见 `FormalizeWorkingCommand` <https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/guest/util.go>

## 增量路径

<https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/apply/applydrivers/apply_drivers_default.go#L185-L197>

```go
processor.SyncNewVersionConfig(name)          // 老版本 pki/etc 目录迁移兼容
if len(RunNewImages) != 0 {
    appErr = c.installApp(RunNewImages)       // InstallProcessor(含升级)
}
mj， md ：= GetDiffHosts(current.masters， desired.masters)
nj， nd ：= GetDiffHosts(current.nodes，   desired.nodes)
return c.scaleCluster(mj， md， nj， nd)， nil    // ScaleProcessor
```

### InstallProcessor

<https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/apply/processor/install.go#L69-L85>

```bash
SyncStatusAndCheck
  → ConfirmOverrideApps
    → PreProcess
      → RunConfig
        → MountRootfs
          → MirrorRegistry
            → UpgradeIfNeed
              → RunGuest
                → PostProcess
```

- SyncStatusAndCheck：重新 Process Clusterfile，`SyncClusterStatus` 从 buildah 的 container 列表重建 `Status.Mounts`，并算出哪些镜像是「重复安装」→ `imagesToOverride`。
- ConfirmOverrideApps：重复安装要交互确认，`-f/--force` 跳过。取消返回 `ErrCancelled`(会被记为 cancelled 而不是 failed)。
- PreProcess：`pull` → 对每个新镜像 `buildah create`，已存在且 `ForceOverride` 时先 `buildah delete` 老 container。把新 mount 追加到 `Status.Mounts` 末尾并记录到 `NewMounts`。
- RunConfig / MountRootfs / MirrorRegistry：同 Create，但只处理 `NewMounts`，`len(NewMounts)==0` 时整步跳过。
- RunGuest：只跑 `NewMounts` 的 entrypoint。

### 升级的触发条件

<https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/apply/processor/install.go#L206-L222>

```go
for _， img ：= range c.NewMounts {
    version ：= img.KubeVersion()     // 只有 rootfs 类型且带 kube 版本 label 才非空
    if version == "" { continue }
    c.Runtime.Upgrade(version)
    cluster.ReplaceRootfsImage()     // 升级成功后，把旧的 rootfs mount 从列表里剔掉
}
```

升级集群 = 对一个已存在的集群 `sealos run labring/kubernetes:v1.25.x`，没有独立的 `upgrade` 子命令。

前置校验 <https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/runtime/kubernetes/runtime.go#L174-L207>

- 目标版本 == 当前版本 → 再查一遍所有 node 的 `kubeletVersion` 和 Ready 状态；全部对齐才 skip，否则继续升级做恢复(断点续传语义)。
- 目标 < 当前 → 拒绝降级。
- 跨超过一个 minor(`v0.Minor()+1 < v1.Minor()`)→ 拒绝。

`upgradeCluster` 的执行顺序 <https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/runtime/kubernetes/upgrade.go#L71-L99>

```bash
autoUpdateConfig(version)         # ① 改集群内的配置
runUpgradeMigrations(...)         # ② 证书 migration(仅 <1.29 → >=1.29)
upgradeMaster0(...)               # ③
upgradeOtherNodes(...)            # ④ 其余 master + 所有 node，串行
syncLocalCertificateIdentity(...) # ⑤ 本地 PKI / kubeconfig 身份模型对齐
```

（1）`autoUpdateConfig` <https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/runtime/kubernetes/upgrade.go#L691-L757>：
用 k8s client 读 `kube-system/kubeadm-config` 和 `kubelet-config` 两个 ConfigMap → decode → 改 `kubernetesVersion`、切换 kubeadm API 版本(`v1beta3`/`v1beta4`)、设 featureGates、`imagePullPolicy: Never`(镜像已经预拉)→ 写回 ConfigMap。返回转换后的 config 和 `hasLocalEtcd`。

（2）`runUpgradeMigrations`：跨 1.29 边界时，kubeadm 改了 `apiserver-kubelet-client`(以及本地 etcd 场景下的 `apiserver-etcd-client`、`etcd-healthcheck-client`)的身份模型，需要重新签发这几张叶子证书并同步到所有 master。两种实现路径：

- 目标支持 v1beta4 → 在 master0 上 `kubeadm init phase certs <name> --config <staged>`(带备份/回滚的 shell，见 <https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/runtime/kubernetes/upgrade.go#L344-L365>)。
- 否则 → 把 CA 拉到本地，用 sealos 自己的 `cert.RenewLeafCertsForKubeVersion` 签，再推回去。

（3）`upgradeMaster0` <https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/runtime/kubernetes/upgrade.go#L537-L606>：

```
syncKubeletConfig                          # 写 /var/lib/kubelet/config.yaml(会按版本裁剪字段)
[>=1.26] changeCRIVersion                  # image-cri-shim.yaml： v1alpha2 → v1，重启 shim + kubelet
[>=1.27] changeKubeletExtraArgs            # 清理 --container-runtime / --pod-infra-container-image 等废弃 flag
pingAPIServer                              # 1 分钟内轮询 List Nodes，确认 apiserver 可用
cp rootfs/bin/kubeadm /usr/bin             # 先换 kubeadm!
imagePull(version)                         # 用新 kubeadm 列镜像并 crictl pull(失败只 warn)
kubeadm upgrade apply <ver> --yes ...       # 核心
kubectl cordon <master0>
cp rootfs/bin/{kubectl，kubelet} /usr/bin
systemctl daemon-reload && restart kubelet
tryUncordonNode                            # 带 1 分钟重试
```

> 注释里特别说明了为什么先装新 kubeadm：kubeadm 才知道目标版本的组件镜像矩阵，否则会去预拉上一个 minor 的镜像。
> 另外 `--config` 不再传给 `upgrade apply` —— 新 kubeadm 只接受 `UpgradeConfiguration`，期望配置已经在步骤 1 写进 ConfigMap 了。

（4）`upgradeOtherNodes`：对每个节点串行，流程同上，但用 `kubeadm upgrade node --skip-phases preflight`(<https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/runtime/kubernetes/upgrade.go#L849-L866> ) 的 1 分钟重试 + 重试前 ping apiserver)。

（5）`syncLocalCertificateIdentity`：重新签本地 `pki/` 叶子证书、renew 本地 kubeconfig;`>=1.29` 还要确保 `kubeadm：cluster-admins` ClusterRoleBinding 存在，并重新生成所有 master 的 `admin.conf` + `$HOME/.kube/config`。

证书续期的开关：`shouldUseKubeadmV1beta4Features(version)` 决定用 `kubeadm upgrade apply <ver> --yes` 还是加 `--certificate-renewal=false`(老版本靠 sealos 自己管证书，所以禁掉 kubeadm 的续期)。

## 关键代码

主干调用链

| 文件 | 关注点 |
| --- | --- |
| [cmd/sealos/cmd/run.go](../cmd/sealos/cmd/run.go) | cobra 挂载、`--force` / `-t` |
| [pkg/apply/args.go](https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/apply/args.go) | 所有 flag 的定义 |
| [pkg/apply/run.go](https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/apply/run.go) | 参数 → desired Cluster |
| [pkg/apply/applydrivers/apply_drivers_default.go](https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/apply/applydrivers/apply_drivers_default.go) | 分支决策 + 错误分类 + 状态回写 |
| [pkg/apply/processor/create.go](https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/apply/processor/create.go) | 9 步流水线骨架 |
| [pkg/apply/processor/install.go](https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/apply/processor/install.go) | 增量 + `UpgradeIfNeed` |
| [pkg/apply/processor/scale.go](https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/apply/processor/scale.go) | 扩缩容两条流水线 |
| [pkg/apply/processor/interface.go](https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/apply/processor/interface.go) | `MountClusterImages` / `SyncClusterStatus` / `OCIToImageMount` / `MirrorRegistry` |

类型系统与状态模型

- [pkg/types/v1beta1/cluster.go](https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/types/v1beta1/cluster.go)：`Cluster`、`Host`、`MountImage`、三种 ImageType、所有 label / env key。
- [pkg/types/v1beta1/utils.go](https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/types/v1beta1/utils.go)：`GetMasterIPAndPortList` / `GetRegistryIP` / `GetVIP` / `GetDistribution` / `ReplaceRootfsImage` / `SetNewImages`。
- [pkg/types/v1beta1/config.go](https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/types/v1beta1/config.go)：`Config` CRD 的四种 strategy(`merge` / `override` / `insert` / `append`)。
- [pkg/clusterfile/](https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/clusterfile/)：Process → 模板渲染(helm values)→ decode 三件套。
- [pkg/constants/pathresolver.go](https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/constants/pathresolver.go) + [bash.go](https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/constants/bash.go)：路径与脚本名的唯一来源。

分发层：rootfs / registry / bootstrap

- [pkg/filesystem/rootfs/rootfs_default.go](https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/filesystem/rootfs/rootfs_default.go)：三轮分发、sealctl 同步的 digest+arch 双重检查、`sealctl render`。
- [pkg/filesystem/registry/sync.go](https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/filesystem/registry/sync.go)：临时 registry + HTTP 同步 + SSH fallback + pid file 清理。配合 [pkg/sreg/](https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/sreg/) 看 `containers/image` 怎么用。
- [pkg/bootstrap/](https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/bootstrap/)：Applier 模式(Filter/Apply/Undo)、三 phase、Apply 正序 / Delete 逆序。
- [pkg/env/](https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/env/) + [pkg/template/](https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/template/)：模板渲染。
- [pkg/ssh/](https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/ssh/) + [pkg/exec/](https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/exec/)：`CacheClient`、`CopyDir`、`WaitReady`、`Remote.HostsAdd/HostsDelete`。

runtime 层：kubeadm

- [pkg/runtime/interface.go](https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/runtime/interface.go)：`Init/Reset/ScaleUp/ScaleDown/Upgrade/GetRawConfig` + `SyncNodeIPVS`。
- [pkg/runtime/factory/factory.go](https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/runtime/factory/factory.go)：distribution 分发。
- [pkg/runtime/kubernetes/types/](https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/runtime/kubernetes/types/)：`KubeadmConfig` 的默认值、v1beta3/v1beta4 转换。
- [pkg/runtime/kubernetes/kubeadm.go](https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/runtime/kubernetes/kubeadm.go) + [config_versioning.go](https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/runtime/kubernetes/config_versioning.go)：`generateInitConfigs` / `generateJoinMasterConfigs` / `marshalConfigsForVersion`。
- [pkg/runtime/kubernetes/certs.go](https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/runtime/kubernetes/certs.go) + [pkg/cert/](https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/cert/)：本地 CA 模型、`InitCertsAndKubeConfigs`、`syncCert`、certSANs。
- [master.go](https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/runtime/kubernetes/master.go) / [node.go](https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/runtime/kubernetes/node.go) / [commands.go](https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/runtime/kubernetes/commands.go)：join 的串行 vs 并发、`imagePull` 的域名重写。
- [pkg/ipvs/](https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/ipvs/) + `SyncNodeIPVS`：lvscare 高可用方案。
- [upgrade.go](https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/runtime/kubernetes/upgrade.go) —— [upgrade_test.go](https://github.com/labring/sealos/blob/v5.1.2-rc6/lifecycle/pkg/runtime/kubernetes/upgrade_test.go) 看各版本分支(V1260 / V1270 / V1290 / V1300)分别改了什么。