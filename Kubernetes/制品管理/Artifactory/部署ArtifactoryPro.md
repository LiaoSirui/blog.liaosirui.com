官方文档：

- Installing the JFrog Platform Using Helm Chart: <https://www.jfrog.com/confluence/display/JFROG/Installing+the+JFrog+Platform+Using+Helm+Chart>
- Package Management: <https://www.jfrog.com/confluence/display/JFROG/Package+Management>

添加 Helm 仓库

```bash
helm repo add jfrog https://charts.jfrog.io
```

查看可用的版本

```bash
> helm search repo jfrog/artifactory

NAME                            CHART VERSION   APP VERSION     DESCRIPTION                                       
jfrog/artifactory               107.49.8        7.49.8          Universal Repository Manager supporting all maj...
jfrog/artifactory-cpp-ce        107.49.8        7.49.8          JFrog Artifactory CE for C++                      
jfrog/artifactory-ha            107.49.8        7.49.8          Universal Repository Manager supporting all maj...
jfrog/artifactory-jcr           107.49.8        7.49.8          JFrog Container Registry                          
jfrog/artifactory-oss           107.49.8        7.49.8          JFrog Artifactory OSS 
```

拉取 chart

```bash
helm pull jfrog/artifactory --version 107.49.8

# 拉取并解压
helm pull jfrog/artifactory --version 107.49.8 --untar
```

创建命名空间

```bash
kubectl create ns artifactory
```

生成 master key 和 join key，在正式生产环境部署需要固定这两个 key，方便后期维护集群

创建  Master Key

```bash
# Create a key
export MASTER_KEY=$(openssl rand -hex 32)
echo ${MASTER_KEY}
# 6d7fa2e379c8b290b03696fd5b492dc0b0aa3d4e10c770a1e9f8eb69cec587f0
 
# Create a secret containing the key. The key in the secret must be named master-key
# kubectl create secret generic my-masterkey-secret -n artifactory --from-literal=master-key=${MASTER_KEY}
```

创建 Join Key

```bash
# Create a key
export JOIN_KEY=$(openssl rand -hex 32)
echo ${JOIN_KEY}
# 57e7ed07326755bd84d0a68384d53869c08893e4c6681f1df33c361d3faa8eb8

# Create a secret containing the key. The key in the secret must be named join-key
# kubectl create secret generic my-joinkey-secret -n artifactory --from-literal=join-key=${JOIN_KEY}
```

使用 values.yaml 覆盖默认配置：

```yaml
global:
  nodeSelector:
    kubernetes.io/hostname: devmaster

rbac:
  create: true
serviceAccount:
  create: true

ingress:
  enabled: false
  hosts:
    - artifactory.local.liaosirui.com
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/proxy-body-size: "1024m"
  tls:
    - secretName: artifactory-https-tls
      hosts:
        - artifactory.local.liaosirui.com

artifactory:
  masterKey: 6d7fa2e379c8b290b03696fd5b492dc0b0aa3d4e10c770a1e9f8eb69cec587f0
  joinKey: 57e7ed07326755bd84d0a68384d53869c08893e4c6681f1df33c361d3faa8eb8
  resources:
    requests:
      memory: "6Gi"
    limits:
      memory: "10Gi"
  javaOpts:
    xms: "6g"
    xmx: "8g"
  admin:
    ip: "127.0.0.1"
    username: "admin"
    password:
  persistence:
    enabled: true
    size: 200Gi
    type: file-system
    storageClassName: "-"

nginx:
  persistence:
    enabled: false

postgresql:
  persistence:
    enabled: true
    size: 200Gi

```

使用 helm 部署

```bash
helm upgrade --install \
  -f ./values.yaml \
  --namespace artifactory --create-namespace \
  --version 107.49.8 \
  artifactory jfrog/artifactory
```

