

## 开启 VXLan 模式

### 官方文档

By default, the Calico manifests enable IP-in-IP encapsulation. If you are on a network that blocks IP-in-IP, such as Azure, you may wish to switch to [Calico’s VXLAN encapsulation mode](https://docs.tigera.io/archive/v3.12/networking/vxlan-ipip). To do this at install time (so that Calico creates the default IP pool with VXLAN and no IP-in-IP configuration has to be undone):

- Start with one of the [Calico for policy and networking](https://docs.tigera.io/archive/v3.12/getting-started/kubernetes/installation/calico) manifests.
- Replace environment variable name `CALICO_IPV4POOL_IPIP` with`CALICO_IPV4POOL_VXLAN`. Leave the value of the new variable as “Always”.
- Optionally, (to save some resources if you’re running a VXLAN-only cluster) completely disable Calico’s BGP-based networking:
  - Replace `calico_backend: "bird"` with `calico_backend: "vxlan"`. This disables BIRD.
  - Comment out the line `- -bird-ready` and `- -bird-live` from the calico/node readiness/liveness check (otherwise disabling BIRD will cause the readiness/liveness check to fail on every node):

```
          livenessProbe:
            exec:
              command:
              - /bin/calico-node
              - -felix-live
             # - -bird-live
          readinessProbe:
            exec:
              command:
              - /bin/calico-node
              # - -bird-ready
              - -felix-ready
```

For more information on calico/node’s configuration variables, including additional VXLAN settings, see [Configuring calico/node](https://docs.tigera.io/archive/v3.12/reference/node/configuration).

> **Note**: The `CALICO_IPV4POOL_VXLAN` environment variable only takes effect when the first calico/node to start creates the default IP pool. It has no effect after the pool has already been created. To switch to VXLAN mode after installation time, use calicoctl to modify the [IPPool](https://docs.tigera.io/archive/v3.12/reference/resources/ippool) resource.

- <https://docs.tigera.io/calico/latest/getting-started/kubernetes/self-managed-onprem/config-options#switching-from-ip-in-ip-to-vxlan>

### 操作步骤

VXLAN模式：

开启内核模块

```bash
lsmod |grep vxlan

modprobe vxlan
```

1. `DaemonSet`的`calico-node`中环境变量字段`CALICO_IPV4POOL_IPIP`

```yaml
- name: CALICO_IPV4POOL_IPIP
  value: Never
- name: CALICO_IPV4POOL_VXLAN
  value: Always
```

1. `DaemonSet`的`calico-node`中探针字段，注释`-bird-live`字段

```yaml
livenessProbe:
  exec:
    command:
    - /bin/calico-node
    - -felix-live
    # - -bird-live
readinessProbe:
  exec:
    command:
    - /bin/calico-node
    # - -bird-ready
    - -felix-ready
```

1. 保证`ConfigMap`的`calico-config`中的`calico_backend: "vxlan"`

通过手动修改`calico-node`的`DaemonSet`，修改字段`IP_AUTODETECTION_METHOD`

```yaml
- name: IP_AUTODETECTION_METHOD
  value: can-reach=8.8.8.8     # 修改为"interface=eth0"
```

VXLan 隧道模式，不能与 ipipMode 同时使用

有三个值，跟 ipipMode 的一样。

- Always: 始终使用 VXLAN 隧道
- CrossSubnet: 只有在跨子网的时候才使用 VXLAN 隧道
- Never: 不使用 VXLAN

以下内容添加到 `/etc/NetworkManager/conf.d/calico.conf` 中，可以阻止 NetworkManager 管理 `calico.vxlan`

```
[keyfile]
unmanaged-devices=interface-name:cali*;interface-name:tunl*;interface-name:vxlan.calico
```

NetworkManager 会操作路由表，干扰到 calico 正常的路由下发

参考资料：<https://docs.tigera.io/calico/latest/operations/troubleshoot/troubleshooting#configure-networkmanager>

## 问题排查

查看对端 vxlan 网卡：

```
bridge fdb show
```

在主机网卡上抓包看看封装后的请求是否已到达：

```bash
tcpdump -n -vv -i eth0 host 10.10.72.11 and udp
```

## 参考文档

- <https://lyyao09.github.io/2022/03/19/k8s/K8S%E9%97%AE%E9%A2%98%E6%8E%92%E6%9F%A5-Calico%E7%9A%84Vxlan%E6%A8%A1%E5%BC%8F%E4%B8%8B%E8%8A%82%E7%82%B9%E5%8F%91%E8%B5%B7K8s%20Service%E8%AF%B7%E6%B1%82%E5%BB%B6%E8%BF%9F/>

- <https://guide-wiki.daocloud.io/dce40/calico-60719592.html>

- <https://help.aliyun.com/document_detail/436507.html>