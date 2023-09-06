## 简介

swap 功能是 linux是一个非常强大的功能，类似于 windows 的虚拟内存，当内存不足的时候，把一部分硬盘空间虚拟成内存使用,从而解决内存容量不足的情况。

## 开启 swap

创建分区文件，其中 count 为分区的大小

```bash
mkdir /swap && cd /swap

dd if=/dev/zero of=swapfile bs=1G count=32

chmod 0600 swapfile

mkswap -f swapfile
```

挂载分区文件

```bash
swapon swapfile
```

挂载持久化： 编辑 `/etc/fstab`, 添加

```ini
/swap/swapfile swap swap defaults 0 0
```

卸载分区文件

```bash
swapoff swapfile
```

## k8s 开启 swap

kubelet 有额外的环境变量文件 `/var/lib/kubelet/kubeadm-flags.env`

```bash
> cat /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

# Note: This dropin only works with kubeadm and kubelet v1.11+
[Service]
Environment="KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf"
Environment="KUBELET_CONFIG_ARGS=--config=/var/lib/kubelet/config.yaml"
# This is a file that "kubeadm init" and "kubeadm join" generates at runtime, populating the KUBELET_KUBEADM_ARGS variable dynamically
EnvironmentFile=-/var/lib/kubelet/kubeadm-flags.env
# This is a file that the user can use for overrides of the kubelet args as a last resort. Preferably, the user should use
# the .NodeRegistration.KubeletExtraArgs object in the configuration files instead. KUBELET_EXTRA_ARGS should be sourced from this file.
EnvironmentFile=-/etc/sysconfig/kubelet
ExecStart=
ExecStart=/usr/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_CONFIG_ARGS $KUBELET_KUBEADM_ARGS $KUBELET_EXTRA_ARGS

```

修改 kubelet 的启动文件配置，如下：

```bash
> vim /var/lib/kubelet/kubeadm-flags.env

加上 --fail-swap-on=false
```

修改预启动脚本

```
> /usr/bin/kubelet-pre-start.sh

注释关闭 swap
# swapoff -a
```

然后 reload 配置

```bash
systemctl daemon-reload
systemctl start kubelet
```

在 `/var/lib/kubelet/config.yaml` 中写入

```
featureGates:
  NodeSwap: true
memorySwap:
  swapBehavior: LimitedSwap
```

- `UnlimitedSwap`（默认）：Kubernetes 工作负载可以根据请求使用尽可能多的交换内存， 一直到达到系统限制为止。
- `LimitedSwap`：Kubernetes 工作负载对交换内存的使用受到限制。 只有具有 Burstable QoS 的 Pod 可以使用交换空间。
