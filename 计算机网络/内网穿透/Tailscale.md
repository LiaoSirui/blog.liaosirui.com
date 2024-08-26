## Tailscale

Tailscale 是一种基于 WireGuard 的虚拟组网工具，它在用户态实现了 WireGuard 协议，相比于内核态 WireGuard 性能会有所损失，但在功能和易用性上下了很大功夫：

- 开箱即用
  - 无需配置防火墙
  - 没有额外的配置
- 高安全性/私密性
  - 自动密钥轮换
  - 点对点连接
  - 支持用户审查端到端的访问记录
- 在原有的 ICE、STUN 等 UDP 协议外，实现了 DERP TCP 协议来实现 NAT 穿透
- 基于公网的控制服务器下发 ACL 和配置，实现节点动态更新
- 通过第三方（如 Google） SSO 服务生成用户和私钥，实现身份认证

## 参考文档

- <https://www.cnblogs.com/ryanyangcs/p/17954172>

- <https://littlenewton.uk/2023/09/tutorial-deployment-and-introduction-of-tailscale/index.html#1-Tailscale-%E7%AE%80%E4%BB%8B>

- <https://github.com/juanfont/headscale>