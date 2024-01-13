
## 安装部署

参考: <https://operatorhub.io/operator/tektoncd-operator> 安装好 operator 和 CRD

```bash
# Install Operator Lifecycle Manager (OLM), a tool to help manage the Operators running on your cluster.
curl -sL https://github.com/operator-framework/operator-lifecycle-manager/releases/download/v0.21.2/install.sh | bash -s v0.21.2

# Install the operator by running the following command:
kubectl create -f https://operatorhub.io/install/tektoncd-operator.yaml

# After install, watch your operator come up using next command.
kubectl get csv -n operators
```

## 组成

- **Tekton Operator**

是一种 Kubernetes Operator 模式 ，允许您在 Kubernetes 集群上安装、更新和删除 Tekton 项目。

- **Tekton Pipelines**

是 Tekton的基础。它定义了一组 Kubernetes 自定义资源 ，用作构建块，可以从中组装 CI/CD 管道。

```yaml
apiVersion: operator.tekton.dev/v1alpha1
kind: TektonPipeline
metadata:
  name: pipeline
spec:
  targetNamespace: tekton-pipelines

```

- **Tekton Triggers**

允许您根据事件实例化管道。例如，您可以在每次将 PR 合并到 GitHub 存储库时触发管道的实例化和执行。

还可以构建启动特定 Tekton 触发器的用户界面。

```yaml
apiVersion: operator.tekton.dev/v1alpha1
kind: TektonTrigger
metadata:
  name: trigger
spec:
  targetNamespace: tekton-pipelines

```

- **Tekton CLI**

提供了一个名为 tkn 的命令行界面，它构建在 Kubernetes CLI 之上，允许您与 Tekton 进行交互。

- **Tekton Dashboard**

是 Tekton Pipelines 的基于 Web 的图形界面，可显示有关管道执行的信息。它目前正在进行中。

```yaml
apiVersion: operator.tekton.dev/v1alpha1
kind: TektonDashboard
metadata:
  name: dashboard
spec:
  targetNamespace: tekton-pipelines

```

- **Tekton Catalog**

是一个由社区贡献的高质量 Tekton 构建块的存储库 - Tasks、Pipelines，等等 - 可以在自己的管道中使用。

链接：<https://github.com/tektoncd/catalog>

- **Tekton Hub**

是一个基于 Web 的图形界面，用于访问 Tekton Catalog。

```yaml
apiVersion: operator.tekton.dev/v1alpha1
kind: TektonHub
metadata:
  name: hub
spec:
  api:
    hubConfigUrl: 'https://raw.githubusercontent.com/tektoncd/hub/main/config.yaml'

```

如果需要代理，则给对应的服务添加代理

```yaml
spec:
  containers:
    - env:
      - name: HTTP_PROXY
        value: "http://192.168.31.90:7890"
      - name: HTTPS_PROXY
        value: "http://192.168.31.90:7890"
      - name: ALL_PROXY
        value: "socks5://192.168.31.90:7890"
      - name: NO_PROXY
        value: "127.0.0.1,localhost,local,.liaosirui.com,192.168.1.0/24,192.168.31.0/24,10.3.0.0/16,10.4.0.0/16"

```

hub 需要存储，因此还需要建立 pv - pvc

```yaml
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: tekton-hub-db-pv
  namespace: tekton-pipelines
  labels:
    app: tekton-hub-db
spec:
  storageClassName: manual
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/data/tekton/hub-data"
    type: DirectoryOrCreate

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: tekton-hub-db
  namespace: tekton-pipelines
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  selector:
    matchLabels:
      app: tekton-hub-db

```

```yaml
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: tekton-hub-api-pv
  namespace: tekton-pipelines
  labels:
    app: tekton-hub-api
spec:
  storageClassName: manual
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/data/tekton/hub-api-data"
    type: DirectoryOrCreate

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: tekton-hub-api
  namespace: tekton-pipelines
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  selector:
    matchLabels:
      app: tekton-hub-api

```

建立 Ingress 以访问

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tekton-hub
  namespace: tekton-pipelines
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/proxy-body-size: "500m"
spec:
  tls:
    - hosts:
      - tekton-hub.liaosirui.com
      secretName: tekton-dashboard-https-tls
  rules:
    - host: tekton-hub.liaosirui.com
      http:
        paths:
          - pathType: Prefix
            backend:
              service:
                name: tekton-hub-ui
                port:
                  number: 8080
            path: /

```

## Tekton Pipelines基本概念

Pipelines 最基本的四个概念：Task、TaskRun、Pipeline、PipelineRun

![img](.assets/pipeline.png)

### Task

Task 为构建任务，是 Tekton 中不可分割的最小单位，正如同 Pod 在 Kubernetes 中的概念一样。在 Task 中，可以有多个 Step，每个 Step 由一个 Container 按照顺序来执行。

### Pipeline

Pipeline 由一个或多个 Task 组成。在 Pipeline 中，用户可以定义这些 Task 的执行顺序以及依赖关系来组成 DAG（有向无环图）。

![img](.assets/pipeline_run.png)

### PipelineRun

PipelineRun 是 Pipeline 的实际执行产物，当用户定义好 Pipeline 后，可以通过创建 PipelineRun 的方式来执行流水线，并生成一条流水线记录。

### TaskRun

PipelineRun 被创建出来后，会对应 Pipeline 里面的 Task 创建各自的 TaskRun。

一个 TaskRun 控制一个 Pod，Task 中的 Step 对应 Pod 中的 Container。

当然，TaskRun 也可以单独被创建。

### ClusterTask

覆盖整个集群的任务，而不是单一的某一个命名空间，这是和 Task 最大的区别，其他基本上一致的。

![img](.assets/pipeline_resource.png)

### PipelineResource

PipelineResource 代表着一系列的资源，主要承担作为 Task 的输入或者输出的作用。

它有以下几种类型：

- git：代表一个 git 仓库，包含了需要被构建的源代码。将 git 资源作为 Task 的 Input，会自动 clone 此 git 仓库。
- pullRequest：表示来自配置的 url（通常是一个 git 仓库）的 pull request 事件。将 pull request 资源作为 Task 的 Input，将自动下载 pull request 相关元数据的文件，如 base/head commit、comments 以及 labels。
- image：代表镜像仓库中的镜像，通常作为 Task 的 Output，用于生成镜像。
- cluster：表示一个除了当前集群外的 Kubernetes 集群。可以使用 Cluster 资源在不同的集群上部署应用。
- storage：表示 blob 存储，它包含一个对象或目录。将 Storage 资源作为 Task 的 Input 将自动下载存储内容，并允许 Task 执行操作。
- cloud event：会在 TaskRun 执行完成后发送事件信息（包含整个 TaskRun） 到指定的 URI 地址，在与第三方通信的时候十分有用。

## Tekton Triggers 基本概念

Tekton Triggers 是一个基于事件的触发器，它可以检测到事件的发生，并能提取事件中的信息，TaskRuns 和 PipelineRuns 可以根据该信息进行实例化和执行。

Tekton Triggers 最基本的四个概念：TriggerTemplate、TriggerBinding、EventListener、Interceptor。

![img](.assets/triggers.png)

### TriggerTemplate

指定要在检测到事件时实例化和执行的资源，如TaskRuns和PipelineRuns。

### TriggerBinding

指定要从事件信息中提取的字段，并将字段信息传递给 TriggerTemplate，这样字段就可以在 TaskRuns 和 PipelineRuns 中使用。

### EventListener

在 Kubernetes 集群启动一个事件监听服务、并暴露服务，将 TriggerTemplate 和 TriggerBinding 绑定。

### Interceptor

事件拦截器，用于过滤事件，运行在 TriggerBinding 之前。

## 完整流程

tekton 可以通过 EventListener 监听 gitlab 的 push 事件，从而触发定制好的流水线作业

![img](.assets/automation.png)
