- Kubernetes

对 APIServer 进行配置，例如

```bash
spec:
  containers:
    - name: kube-apiserver
      command:
        - kube-apiserver
        - --oidc-issuer-url=https://xxx.com/idp
        - --oidc-client-id=dex-idp
        - --oidc-username-claim=name
        - --oidc-username-prefix=-
        - --oidc-groups-claim=groups
        - --oidc-ca-file=/etc/kubernetes/pki/xxx.com.crt

```

