## 自定义网段

```yaml
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
networking:
  serviceSubnet: "100.55.0.0/16"
  podSubnet: "10.160.0.0/12"
```

使用如下 Kubefile

```bash
FROM labring/kubernetes-docker:v1.25.0
COPY kubeadm.yml etc/
```

构建镜像

```bash
sealos build --debug -t hack:dev .
```

