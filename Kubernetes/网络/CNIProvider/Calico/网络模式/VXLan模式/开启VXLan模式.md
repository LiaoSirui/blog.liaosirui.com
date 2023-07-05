## 环境确认

开启内核模块

```bash
lsmod |grep vxlan

modprobe vxlan
```

## 变更

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

## 参考文档

- <https://docs.tigera.io/calico/latest/getting-started/kubernetes/self-managed-onprem/config-options#switching-from-ip-in-ip-to-vxlan>