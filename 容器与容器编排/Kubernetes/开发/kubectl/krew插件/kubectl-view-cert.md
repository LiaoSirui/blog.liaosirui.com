## kubectl-view-cert 简介

当一个 kubernetes 集群中有大量的应用创建了声明 tls 类型的 ingress 资源时，维护这个 tls 的 secret 工作将变得异常繁琐。特别是当证书即将过期需要替换时，运维不得不挨个检查一遍，整个过程需要非常细致且麻烦，通常它的流程经过下面阶段：

- 遍历 namespaces 下的 secret
- 用 base64 将私钥 decode 出来
- 再用 `openssl x509 -noout -text -in <私钥>` 查看证书信息

kubectl-view-cert 这个插件可以简化上述步骤。安装这个插件直接执行下述命令即可：

```bash
kubectl krew install view-cert
```

官方：

- GitHub 仓库：<https://github.com/lmolas/kubectl-view-cert>

## kubectl-view-cert 使用

kubectl-view-cert 常用参数：

- `-A, --all-namespaces` 查询所有命名空间的 tls 证书
- `-E, --expired`  只显示已经过期的 tls 证书
- `-D, --expired-days-from-now int`  显示当前时间之后 N 天过期的证书
- `-S, --show-ca` 显示 CA 证书，如果有的话

遍历集群下所有 tls 已经过期的 secret

```bash
kubectl view-cert -A -E
```

遍历集群下所有 tls 还剩 180 天到期的 secret

```bash
kubectl view-cert -A -E -D 180
```

