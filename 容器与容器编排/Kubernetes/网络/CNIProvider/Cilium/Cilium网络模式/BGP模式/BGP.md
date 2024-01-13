启用对 BGP 的支持只需要设置 `--enable-bgp-control-plane=true` 参数，并且通过一个新的 CRD `CiliumBGPPeeringPolicy` 实现更加细粒度和可扩展的配置

- 使用 `nodeSelector` 参数通过标签选择，可以将相同的 BGP 配置应用于多个节点
- 当 `exportPodCIDR` 参数设置为 true 时，可以动态地宣告所有 Pod CIDR，无需手动指定需要宣告哪些路由前缀
- `neighbors` 参数用于设置 BGP 邻居信息，通常是集群外部的网络设备

```yaml
apiVersion: "cilium.io/v2alpha1"
kind: CiliumBGPPeeringPolicy
metadata:
 name: rack0
spec:
 nodeSelector:
   matchLabels:
     rack: rack0
 virtualRouters:
 - localASN: 65010
   exportPodCIDR: true
   neighbors:
   - peerAddress: "10.0.0.1/32"
     peerASN: 65010
```

