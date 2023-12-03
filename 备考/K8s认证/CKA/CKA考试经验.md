## 考试大纲

CKA认证考试包括这些一般领域及其在考试中的权重：

- 集群架构，安装和配置：25%
- 工作负载和调度：15%
- 服务和网络：20%
- 存储：10% 
- 故障排除：30%

详细内容

**集群架构，安装和配置：25%**

- 管理基于角色的访问控制（RBAC）

- 使用 Kubeadm 安装基本集群

- 管理高可用性的 Kubernetes 集群

- 设置基础架构以部署 Kubernetes 集群

- 使用 Kubeadm 在 Kubernetes 集群上执行版本升级

- 实施 etcd 备份和还原

**工作负载和调度：15%**

- 了解部署以及如何执行滚动更新和回滚

- 使用ConfigMaps和Secrets配置应用程序

- 了解如何扩展应用程序

- 了解用于创建健壮的、自修复的应用程序部署的原语

- 了解资源限制如何影响Pod调度

- 了解清单管理和通用模板工具

**服务和网络：20%**

- 了解集群节点上的主机网络配置

- 理解 Pods 之间的连通性

- 了解ClusterIP、NodePort、LoadBalancer 服务类型和端点

- 了解如何使用入口控制器和入口资源

- 了解如何配置和使用 CoreDNS

- 选择适当的容器网络接口插件

**存储：10%**

- 了解存储类、持久卷

- 了解卷模式、访问模式和卷回收策略

- 理解持久容量声明原语

- 了解如何配置具有持久性存储的应用程序

**故障排除：30%**

- 评估集群和节点日志

- 了解如何监视应用程序

- 管理容器标准输出和标准错误日志

- 解决应用程序故障

- 对群集组件故障进行故障排除

- 排除网络故障

## 考试模拟

可以有两次 `https://killer.sh/dashboard` 的模拟考试

![image-20231202155409838](.assets/CKA考试经验/image-20231202155409838.png)

## 考试准备

设置自动补全

```bash
alias k=kubectl
complete -F __start_kubectl k
```

## 学习资料

- <https://github.com/stretchcloud/cka-lab-practice>
- <https://github.com/David-VTUK/CKA-StudyGuide>

需要熟悉使用 [kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/) 创建集群、升级集群

在线练习环境：

- [katacoda](https://www.katacoda.com/courses/kubernetes/kubectl-run-containers)
- [play-with-k8s](https://labs.play-with-k8s.com/)

## 参考链接

- <https://www.zhaohuabing.com/post/2022-02-08-how-to-prepare-cka/>

- <https://www.cncf.io/certification/ckad/>

- <https://zhuanlan.zhihu.com/p/140731113>

- <https://cloud.tencent.com/developer/article/1394491>

- <https://www.secrss.com/articles/34946>

- <https://www.cnblogs.com/even160941/p/17710997.html>