## 需重点关注变更

### 守护进程配置版本 3

此版本增加了对 containerd 守护进程配置 `version = 3` 的支持。守护进程配置在启动时会自动迁移到最新版本。这确保以前的配置在未来的守护进程上继续工作；但是，建议迁移到最新版本以避免迁移并优化守护进程启动时间。有关更多详细信息，请参见发布文档中的 [“守护进程配置”](https://github.com/containerd/containerd/blob/release/2.0/RELEASES.md#daemon-configuration)。

问题不大。自动升级

### CRI 注册表属性已弃用

以下 `[plugins."io.containerd.grpc.v1.cri".registry]` 属性的支持已弃用，并将在未来的版本中移除。

- CRIRegistryMirrors（`mirrors`）属性。用户应迁移至使用 [config_path](https://github.com/containerd/containerd/blob/release/2.0/docs/hosts.md)。
- CRIRegistryAuths（`auths`）属性。用户应迁移至使用 [ImagePullSecrets](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/)。
- CRIRegistryConfigs（`configs`）属性。用户应迁移至使用 [config_path](https://github.com/containerd/containerd/blob/release/2.0/docs/hosts.md)。

registry 配置是常用配置，需要特别关注。一般在配置 register mirror 和 私有镜像仓 都会大量用到本配置。

### CRI v1alpha2 API 已被移除

在 containerd v1.7 中已弃用，CRI v1alpha2 API 的支持已被移除。用户应迁移至使用 CRI v1。

对 Kubernetes v1.31，kubelet 偏向于使用 CRI `v1` 版本。 如果容器运行时不支持 CRI 的 `v1` 版本，那么 kubelet 会尝试协商较老的、仍被支持的所有版本。 v1.31 版本的 kubelet 也可协商 CRI `v1alpha2` 版本，但该版本被视为已弃用。 如果 kubelet 无法协商出可支持的 CRI 版本，则 kubelet 放弃并且不会注册为节点。

### `io_uring_*` 系统调用默认被禁止

以下系统调用 (`io_uring_enter`, `io_uring_register`, 和 `io_uring_setup`) 已从默认的 Seccomp 配置文件允许列表中移除。许多报告的 Linux 内核漏洞与 `io_uring` 有关，使用它无法推荐为默认允许列表的一部分。

找了一下 kubernetes 使用 Seccomp 的方法，如果还想使用，可以使用自定义列表：[使用 seccomp 限制容器的系统调用 | Kubernetes](https://kubernetes.io/zh-cn/docs/tutorials/security/seccomp/)

### `LimitNOFILE` 配置已被移除

[Remove `LimitNOFILE` from `containerd.service` by polarathene · Pull Request #8924 · containerd/containerd · GitHub](https://github.com/containerd/containerd/pull/8924)

containerd 的资源限制（rlimits）由容器继承，因此守护进程的 `LimitNOFILE` 会影响容器内的 `RLIMIT_NOFILE`。建议使用默认的 systemd `LimitNOFILE` 配置。

## 变更过程

先关服务

```bash
systemctl disable --now kubelet
systemctl disable --now containerd
```

重启节点，然后执行清理

```bash
readonly BIN_DIR=/usr/bin

systemctl stop containerd
systemctl disable containerd
rm -rf /etc/containerd
rm -rf /etc/systemd/system/containerd.service
systemctl daemon-reload

rm -rf /var/lib/containerd
rm -rf /run/containerd/containerd.sock
rm -rf /var/lib/nerdctl
rm -f ${BIN_DIR}/containerd
rm -f ${BIN_DIR}/containerd-stress
rm -f ${BIN_DIR}/containerd-shim
rm -f ${BIN_DIR}/containerd-shim-runc-v1
rm -f ${BIN_DIR}/containerd-shim-runc-v2
# rm -f ${BIN_DIR}/crictl
# rm -f /etc/crictl.yaml
rm -f ${BIN_DIR}/ctr
rm -f ${BIN_DIR}/ctd-decoder
rm -f ${BIN_DIR}/runc
rm -f ${BIN_DIR}/nerdctl
rm -f ${BIN_DIR}/crun
rm -f ${BIN_DIR}/crun_

rm -rf /opt/containerd
rm -rf /etc/ld.so.conf.d/containerd.conf
```

重新安装

```bash
tar zxvf containerd-2.4.2-linux-amd64.tar.gz -C /usr/
cp crun-1.31-linux-amd64 /usr/bin/crun
cp runc.amd64-v1.5.3 /usr/bin/runc
# 配置文件目录、systemd service
```

