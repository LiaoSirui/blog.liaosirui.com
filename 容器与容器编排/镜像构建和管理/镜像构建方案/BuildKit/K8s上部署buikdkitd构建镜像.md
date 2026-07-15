在部署之前需要确保各个 k8s 个服务节点内核参数都设置了`user.max_user_namespaces=28633`，以支持 rootless 模式运行容器

buildkit 源码的`examples/kubernetes`目录中已经给出了以各种形式在 k8s 上部署 buildkit 的示例 yaml 文件

例如：

- <https://github.com/moby/buildkit/blob/master/examples/kubernetes/deployment%2Bservice.privileged.yaml>

自签 Issuer，仅用于签发下面的根 CA

```yaml
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: buildkit-self-signed
  namespace: cpaas-infra-system
spec:
  selfSigned: {}
```

根 CA 证书

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: buildkit-ca
  namespace: cpaas-infra-system
spec:
  isCA: true
  commonName: buildkit-ca
  secretName: buildkit-ca
  duration: 87600h # 10 年
  renewBefore: 8760h # 到期前 1 年续期
  privateKey:
    algorithm: RSA
    size: 2048
  subject:
    organizations:
      - AlphaQuant
    organizationalUnits:
      - Trust Services
  issuerRef:
    name: buildkit-self-signed
    kind: Issuer
    group: cert-manager.io
```

用根 CA 建立签发者，供 daemon / client 证书使用

```yaml
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: buildkit-ca-issuer
  namespace: cpaas-infra-system
spec:
  ca:
    secretName: buildkit-ca
```

生成证书

```yaml
---
# 服务端证书
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: buildkit-daemon-certs
  namespace: cpaas-infra-system
spec:
  secretName: buildkit-daemon-certs
  duration: 8760h # 1 年
  renewBefore: 240h # 到期前 10 天续期
  commonName: buildkitd
  privateKey:
    algorithm: RSA
    size: 2048
  usages:
    - server auth
  dnsNames:
    - buildkitd
    - buildkitd.cpaas-infra-system
    - buildkitd.cpaas-infra-system.svc
    - buildkitd.cpaas-infra-system.svc.cluster.local
  ipAddresses:
    - 127.0.0.1
    - ::1
  issuerRef:
    name: buildkit-ca-issuer
    kind: Issuer
    group: cert-manager.io

---
# 客户端证书
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: buildkit-client-certs
  namespace: cpaas-infra-system
spec:
  secretName: buildkit-client-certs
  duration: 8760h # 1 年
  renewBefore: 240h # 到期前 10 天续期
  commonName: buildkit-client
  privateKey:
    algorithm: RSA
    size: 2048
  usages:
    - client auth
  issuerRef:
    name: buildkit-ca-issuer
    kind: Issuer
    group: cert-manager.io

```

部署 buildkit

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: buildkitd
  labels:
    app: buildkitd
spec:
  selector:
    matchLabels:
      app: buildkitd
  template:
    metadata:
      labels:
        app: buildkitd
    spec:
      containers:
        - name: buildkitd
          image: harbor.alpha-quant.tech/library/docker.io/moby/buildkit:buildx-stable-1
          resources:
            requests:
              cpu: "2"
              memory: "24Gi"
            limits:
              cpu: "8"
              memory: "24Gi"
          args:
            - --addr
            - unix:///run/buildkit/buildkitd.sock
            - --addr
            - tcp://0.0.0.0:1234
            - --tlscacert
            - /certs/ca.pem
            - --tlscert
            - /certs/cert.pem
            - --tlskey
            - /certs/key.pem
            - --allow-insecure-entitlement
            - security.insecure
          # the probe below will only work after Release v0.6.3
          readinessProbe:
            exec:
              command:
                - buildctl
                - debug
                - workers
            initialDelaySeconds: 5
            periodSeconds: 30
          # the probe below will only work after Release v0.6.3
          livenessProbe:
            exec:
              command:
                - buildctl
                - debug
                - workers
            initialDelaySeconds: 5
            periodSeconds: 30
          securityContext:
            privileged: true
          ports:
            - containerPort: 1234
              hostPort: 1234
          volumeMounts:
            - name: certs
              readOnly: true
              mountPath: /certs
            - name: buildkitd
              mountPath: /var/lib/buildkit
      volumes:
        # buildkit-daemon-certs 由 cert-manager 签发
        # cert-manager 使用 tls.crt/tls.key/ca.crt，此处重命名为 buildkitd 需要的 cert.pem/key.pem/ca.pem。
        - name: certs
          secret:
            secretName: buildkit-daemon-certs
            items:
              - key: ca.crt
                path: ca.pem
              - key: tls.crt
                path: cert.pem
              - key: tls.key
                path: key.pem
        - name: buildkitd
          persistentVolumeClaim:
            claimName: buildkitd
---
apiVersion: v1
kind: Service
metadata:
  name: buildkitd
  labels:
    app: buildkitd
spec:
  ports:
    - port: 1234
      protocol: TCP
  selector:
    app: buildkitd

```

buildctl 构建镜像时需要访问的私有镜像仓库的 secret 的 yaml 文件`buildkit-client-registry-secret.yaml`：

```bash
kubectl create secret docker-registry buildkit-client-registry-secret \
  -n gitlab-runner \
  --dry-run=client -o yaml \
  --docker-server=harbor.alpha-quant.tech \
  --docker-username=username \
  --docker-password=password \
  > buildkit-client-registry-secret.yaml
```

启动一个 docker cli 测试客户端

```yaml
kind: Deployment
apiVersion: apps/v1
metadata:
  name: docker-cli
spec:
  replicas: 0
  selector:
    matchLabels:
      app: docker-cli
  template:
    metadata:
      labels:
        app: docker-cli
    spec:
      volumes:
        - name: buildkit-client-certs
          secret:
            secretName: buildkit-client-certs
            defaultMode: 420
        - name: buildkit-client-registry-secret
          secret:
            secretName: buildkit-client-registry-secret
            defaultMode: 420
      containers:
        - name: docker-cli
          image: 'harbor.alpha-quant.tech/library/docker.io/library/docker:29.3.0-cli'
          command:
            - sh
            - '-c'
            - |
              docker buildx create \
                --name remote-container \
                --driver remote \
                --driver-opt cacert=/root/.buildctl/certs/ca.crt,cert=/root/.buildctl/certs/tls.crt,key=/root/.buildctl/certs/tls.key,servername=buildkitd \
                --use \
                tcp://buildkitd:1234
              sleep infinity
          resources:
            requests:
              cpu: "1"
              memory: 1Gi
            limits:
              cpu: "2"
              memory: 4Gi
          volumeMounts:
            - name: buildkit-client-certs
              readOnly: true
              mountPath: /root/.buildctl/certs
            - name: buildkit-client-registry-secret
              readOnly: true
              subPath: .dockerconfigjson
              mountPath: /root/.buildctl/secret/config.json
            - name: buildkit-client-registry-secret
              readOnly: true
              subPath: .dockerconfigjson
              mountPath: /root/.docker/config.json
      tolerations:
        - operator: Exists

```

对于 gitlab runner，需要

- 证书文件挂载到 `$HOME/.buildctl/certs` 目录下
- `buildkit-client-registry-secret` 中的 `.dockerconfigjson` 文件挂载到 `$HOME/.buildctl/secret` 下

测试镜像构建:

```bash
buildctl \
  --addr tcp://buildkitd:1234 \
  --tlscacert=$HOME/.buildctl/certs/ca.crt \
  --tlscert=$HOME/.buildctl/certs/tls.crt \
  --tlskey=$HOME/.buildctl/certs/tls.key \
  build   \
  --frontend dockerfile.v0  \
  --local context=/tmp/myproject   \
  --local dockerfile=/tmp/myproject \
  --output type=image,name=harbor.alpha-quant.tech/myproject/myimg:1.0,push=true
```

当把 buildkitd 部署到 k8s 集群后，k8s 集群上的 Gitlab Runner 只需要单独使用 buildctl 这个命令行工具就可以与其通信完成镜像构建工作，不再依赖于 Docker Daemon，也不需要再使用 Docker outside Docker

或者

```bash
docker buildx create \
  --name remote-container \
  --driver remote \
  --driver-opt cacert=/root/.buildctl/certs/ca.pem,cert=/root/.buildctl/certs/cert.pem,key=/root/.buildctl/certs/key.pem,servername=buildkitd \
  --use \
  tcp://buildkitd:1234
```

更多见：<https://docs.docker.com/build/builders/drivers/remote/>