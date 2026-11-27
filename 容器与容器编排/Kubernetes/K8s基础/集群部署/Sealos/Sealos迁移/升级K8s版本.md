（1）升级 containerd 版本到 2.42 后开始升级操作

（2）sealos 用自定义版本、镜像改用自定义版本

（3）去掉一些配置

```yaml
    # - name: feature-gates
    #   value: DynamicResourceAllocation=true
    # - name: runtime-config
    #   value: resource.k8s.io/v1beta1=true,resource.k8s.io/v1beta2=true

# 改下配置文件 /var/lib/sealos/data/default/etc/kubeadm-init.yaml
# 改下 /etc/kubernetes/manifests/kube-apiserver.yaml
# 改下 kubectl edit configmap -n kube-system kubeadm-config
# 改下 kubectl edit configmap -n kube-system kubelet-config
```

OIDC 参数会丢失，写入到 kubeadm-config

```yaml
# - --oidc-issuer-url=https://cpaas.dev.alpha-quant.cn/sys-apps/dex-idp
# - --oidc-client-id=dex-idp
# - --oidc-username-claim=name
# - --oidc-username-prefix=-
# - --oidc-groups-claim=groups
data:
  ClusterConfiguration: |
    apiServer:
      extraArgs:
      - name: oidc-issuer-url
        value: "https://cpaas.dev.alpha-quant.cn/sys-apps/dex-idp"
      - name: oidc-client-id
        value: "dex-idp"
      - name: oidc-username-claim
        value: "name"
      - name: oidc-username-prefix
        value: "-"
      - name: oidc-groups-claim
        value: "groups"
```

