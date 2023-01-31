## 运行原理


官方文档：<https://kubernetes.github.io/ingress-nginx/how-it-works/>

ingress-nginx 控制器主要是用来组装一个 nginx.conf 的配置文件，当配置文件发生任何变动的时候就需要重新加载 Nginx 来生效，但是并不会只在影响 upstream 配置的变更后就重新加载 Nginx，控制器内部会使用一个 lua-nginx-module 来实现该功能。

Kubernetes 控制器使用控制循环模式来检查控制器中所需的状态是否已更新或是否需要变更，所以 ingress-nginx 需要使用集群中的不同对象来构建模型，比如 Ingress、Service、Endpoints、Secret、ConfigMap 等可以生成反映集群状态的配置文件的对象，控制器需要一直 Watch 这些资源对象的变化，但是并没有办法知道特定的更改是否会影响到最终生成的 `nginx.conf` 配置文件，所以一旦 Watch 到了任何变化控制器都必须根据集群的状态重建一个新的模型，并将其与当前的模型进行比较，如果模型相同则就可以避免生成新的 Nginx 配置并触发重新加载，否则还需要检查模型的差异是否只和端点有关，如果是这样，则然后需要使用 HTTP POST 请求将新的端点列表发送到在 Nginx 内运行的 Lua 处理程序，并再次避免生成新的 Nginx 配置并触发重新加载，如果运行和新模型之间的差异不仅仅是端点，那么就会基于新模型创建一个新的 Nginx 配置了，这样构建模型最大的一个好处就是在状态没有变化时避免不必要的重新加载，可以节省大量 Nginx 重新加载。

下面简单描述了需要重新加载的一些场景：

- 创建了新的 Ingress 资源
- TLS 添加到现有 Ingress
- 从 Ingress 中添加或删除 path 路径
- Ingress、Service、Secret 被删除了
- Ingress 的一些缺失引用对象变可用了，例如 Service 或 Secret
- 更新了一个 Secret

对于集群规模较大的场景下频繁的对 Nginx 进行重新加载显然会造成大量的性能消耗，所以要尽可能减少出现重新加载的场景。



## 区别于 Nginx 社区维护的版本

## 安装 nginx-ingress

添加仓库

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx 
```

使用如下 values.yaml

```yaml
controller:
  extraArgs:
    enable-ssl-passthrough: 'true'
  config:
    worker-processes: 'auto'
    max-worker-connections: '10240'
    keep-alive: '200'
    keep-alive-requests: '10000000'
    use-http2: 'true'
    # enable-real-ip: 'true'
    # proxy-real-ip-cidr: '0.0.0.0/0'
    # use-proxy-protocol: 'true'
    use-forwarded-headers: 'true'
    compute-full-forwarded-for: "true"
  containerPort:
    http: 80
    https: 443
  hostPort:
    enabled: true
    ports:
      http: 10080
      https: 10443
  tolerations:
    - operator: "Exists"
  nodeSelector:
    # ingress-nginx: 'true'
    node-role.kubernetes.io/control-plane: ""
  replicaCount: 1
  service:
    enabled: false
  admissionWebhooks:
    enabled: false
  metrics:
    enabled: true
    serviceMonitor:
      enabled: false
    prometheusRule:
      enabled: false
defaultBackend:
  enabled: false

```

使用 helm 安装

```bash
helm upgrade --install \
  --namespace ingress-nginx --create-namespace \
  -f ./values.yaml \
  ingress-nginx ingress-nginx/ingress-nginx
```

进行测试

```bash
kubectl create deployment demo --image=httpd --port=80

kubectl expose deployment demo

kubectl create ingress demo-localhost --class=nginx \
  --rule="demo.local.liaosirui.com/*=demo:80"
```

