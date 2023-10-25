## 查看所有 api 资源

命令`kubectl api-resources`来查看所有 api 资源

通过`kubectl api-versions`来查看 api 的版本

通过`kubectl explain <资源名对象名>`查看资源对象拥有的字段

## 运行 pod

```bash
NODE=node-foobar
kubectl run pwru \
    --image=cilium/pwru:latest \
    --privileged=true \
    --attach=true -i=true --tty=true --rm=true \
    --overrides='{"apiVersion":"v1","spec":{"nodeSelector":{"kubernetes.io/hostname":"'$NODE'"}, "hostNetwork": true, "hostPID": true}}' \
    -- --filter-dst-ip=1.1.1.1 --output-tuple
```

## 端口转发

https://chanjarster.github.io/post/k8s/kubectl-port-forward/

### 转发 Service 端口

```
kubectl port-forward --namespace <命名空间> svc/<service名字> <本地端口>:<service端口>


 labels:
    redis_setup_type: cluster
    app: aipaas-redis-cluster-follower
    release.app.local/name: chart-redis
    release.app.local/component: cluster
    statefulset.kubernetes.io/pod-name: aipaas-redis-cluster-follower-2
    release.app.local/instance: redis
    helm.sh/managed-by: Helm
    controller-revision-hash: aipaas-redis-cluster-follower-56bd58b76f
    release.app.local/fullname: aipaas-redis
    app.kubernetes.io/managed-by: Helm
    helm.sh/chart: chart-redis-5.10.0
    role: follower
    helm.sh/app-ersion: v7.0.5
            failureThreshold: 10

        - labelSelector:
            matchLabels:
              release.app.local/component: redis-follower
              release.app.local/fullname: aipaas-redis
              release.app.local/instance: redis
              release.app.local/name: chart-redis
```

### 工作原理

https://mp.weixin.qq.com/s/bmRqaWgF0GNVj6RqaXcz9w

## 从 ServiceAccount 生成 kubeconfig

```yaml
apiVersion: v1
current-context: dev-quant-admin@dev-quant
kind: Config
preferences: {}
clusters:
- cluster:
    insecure-skip-tls-verify: true
    server: https://kubernetes.default.svc.cluster.local
  name: dev-quant
users:
- name: dev-quant-admin
  user:
    token:
contexts:
- context:
    cluster: dev-quant
    namespace: kube-system
    user: dev-quant-admin
  name: dev-quant-admin@dev-quant

```

