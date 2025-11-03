## Containerlab 简介

Containerlab 提供了一种简单、轻量的、基于容器的编排网络实验的方案，支持各种容器化网络操作系统，例如：Cisco、Arista 等等。Containerlab 可以根据用户定义的配置文件，启动容器并在它们之间创建虚拟连接以构建用户定义网络拓扑

官方：

- 官网：<https://containerlab.dev/>

- 安装 Containerlab: <https://containerlab.dev/install/>

- 代码仓库：<https://github.com/srl-labs/containerlab>

```yaml
name: sonic01

topology:
  nodes:
    srl:
      kind: srl
      image: ghcr.io/nokia/srlinux
    sonic:
      kind: sonic-vs
      image: docker-sonic-vs:2020-11-12

  links:
    - endpoints: ["srl:e1-1", "sonic:eth1"]
```

容器的管理接口会连接到名为 clab 的 bridge 类型的 Docker 网络中，业务接口通过配置文件中定义的 links 规则相连。这就好比数据中心中网络管理对应的带外管理（out-of-band）和带内管理（in-band）两种管理模式

![img](./.assets/Containerlab简介/clab.png)

Containerlab 还提供了丰富的实验案例，可以在 Lab examples 中找到 <https://containerlab.dev/lab-examples/lab-examples/>

甚至可以通过 Containerlab 创建出一个数据中心级别的网络架构(参见 5-stage Clos fabric <https://containerlab.dev/lab-examples/min-5clos/>)

![img](./.assets/Containerlab简介/min-5clos.png)

安装

```bash
bash -c "$(curl -sL https://get.containerlab.dev)" -- -v 0.71.0
```
