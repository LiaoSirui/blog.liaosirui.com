对于 Kubernetes 中的策略，大家可能比较熟悉的是 PodSecurityPolicy。不过 PodSecurityPolicy 自 Kubernetes v1.21 起已弃用，并将在 v1.25 中删除（当前版本是 v1.23 ）。当前建议大家迁移到 Kubernetes 新增的替换方案 Pod Security Admission 或者类似本文中介绍的 Kyverno 等这种第三方策略插件。

其实无论是 PodSecurityPolicy 还是它的替代方案 Pod Security Admission ，甚至包括 Kyverno 等，它们都是构筑在 Kubernetes 的 Admission 机制之上的。

主要从两个角度来理解为什么我们需要准入控制器（Admission Controller）：

从安全的角度

- 比如，为避免攻击。需要对Kubernetes 集群中部署的镜像来源判定；
- 比如，避免 Pod 使用 root 用户，或者尽量不开启特权容器等；

从治理的角度

- 比如，通过 admission controller 校验服务是否拥有必须的 label；
- 比如，避免出现资源超卖等；

Kyverno

- <https://www.qikqiak.com/k3s/security/kyverno/>
- <https://cloud.tencent.com/developer/article/2410697>
- <https://kyverno.io/docs/installation/>
- <https://moelove.info/2022/03/02/%E4%BA%91%E5%8E%9F%E7%94%9F%E7%AD%96%E7%95%A5%E5%BC%95%E6%93%8E-Kyverno-%E4%B8%8A/#kubernetes-%E7%9A%84%E7%AD%96%E7%95%A5>