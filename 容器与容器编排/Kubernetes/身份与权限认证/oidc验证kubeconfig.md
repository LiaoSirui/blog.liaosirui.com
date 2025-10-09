## Kubelogin

由于是在远端机器，因此需要转发下端口

```bash
ssh -L 127.0.0.1:34527:127.0.0.1:34527 server
```

然后在 server 执行如下命令：

```bash
kubectl oidc-login setup \
    --oidc-issuer-url=https://cpaas.alpha-quant.tech/sys-apps/idp \
    --oidc-client-id=dex-idp \
    --oidc-client-secret=628e0eb5-3f8f-4cd9 \
    --insecure-skip-tls-verify \
    --listen-address=0.0.0.0:34527 \
    --oidc-extra-scope=profile \
    --oidc-extra-scope=email \
    --oidc-extra-scope=groups
```

访问 <http://localhost:34527>

登录成功后按照提示进行配置

```bash
kubectl config set-credentials oidc \
    --exec-api-version=client.authentication.k8s.io/v1beta1 \
    --exec-command=kubectl \
    --exec-arg=oidc-login \
    --exec-arg=get-token \
    --exec-arg=--oidc-issuer-url=https://cpaas.alpha-quant.tech/sys-apps/idp \
    --exec-arg=--oidc-client-id=dex-idp \
    --exec-arg=--oidc-client-secret=628e0eb5-3f8f-4cd9 \
    --exec-arg=--insecure-skip-tls-verify \
    --exec-arg=--listen-address=0.0.0.0:34527 \
    --exec-arg=--oidc-extra-scope=profile \
    --exec-arg=--oidc-extra-scope=email \
    --exec-arg=--oidc-extra-scope=groups \
```

验证和切换登录

```bash
kubectl --user=oidc get nodes

kubectl config set-context --current --user=oidc
```

## 参考资料

- <https://dexidp.io/docs/guides/kubelogin-activedirectory/>
