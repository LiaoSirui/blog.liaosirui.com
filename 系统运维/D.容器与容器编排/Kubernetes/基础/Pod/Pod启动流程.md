### APIServer 处理 pod 启动

APIServer 收到创建 pod 的请求后：

- 首先，对 client 来源进行认证，实现方式是证书 (cert) 或 token (sa)
- 然后，对 client 进行鉴权，确认其是否有创建 pod 的权限，实现方法是 rbac
- 然后，通过准入控制插件验证或修改资源请求，常用的准入控制插件有：LimitRanger/ResourceQuota/NamespaceLifecycle
- 最后，将 pod 资源存储到 etcd

### Scheduler 处理 pod 启动

Scheduler 监听到 APIServer 创建 pod 的事件后：

- 按照默认的调度算法 (预选算法 + 优选算法)，为 pod 选择一个可运行的节点 nodeName
- 向 APIServer 发送更新 pod 的消息：`pod.spec.nodeName`
- APIServer 更新 pod，通知 nodeName 上的 kubelet，pod 被调度到了 nodeName

### Kubelet 处理 pod 启动

kubelet 监听到 APIServer 创建 pod 的事件后，通知容器运行时 dockerd 拉取镜像，创建容器，启动容器

pod中容器的启动过程：

- InitC 容器
  - 多个 initC 顺序启动，前一个启动成功后才启动下一个
  - 仅当最后一个 initC 执行完毕后，才会启动主容器
  - 常用于进行初始化操作或等待依赖的服务已 ok
- postStart 钩子
  - postStart 与 container 的主进程并行执行
  - 在 postStart 执行完毕前，容器一直是 waiting 状态，pod 一直是 pending 状态
  - 若 postStart 运行失败，容器会被杀死
- startupProbe 钩子
  - v1.16 版本后新增的探测方式
  - 若配置了 startupProbe，就会先禁止其他探测，直到成功为止
- readinessProbe 探针
  - 探测容器状态是否 ready，准备好接收用户流量
  - 探测成功后，将 pod 的 endpoint 添加到 service
- livenessProbe 探针
  - 探测容器的健康状态，若探测失败，则按照重启策略进行重启
- containers
  - 多个 container 之间是顺序启动的，container 启动源码：<https://github.com/kubernetes/kubernetes/blob/master/pkg/kubelet/kuberuntime/kuberuntime_manager.go#L824>

