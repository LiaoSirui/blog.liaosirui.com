在部署之前需要确保各个 k8s 个服务节点内核参数都设置了`user.max_user_namespaces=28633`，以支持 rootless 模式运行容器

buildkit 源码的`examples/kubernetes`目录中已经给出了以各种形式在 k8s 上部署 buildkit 的示例 yaml 文件

例如：

- <https://github.com/moby/buildkit/blob/master/examples/kubernetes/deployment%2Bservice.privileged.yaml>

先使用 cfssl 工具生成服务端和客户端证书，需要注意把 buildkitd 的 service name 写到生成的服务端证书的 san 中

可参考：<https://kubernetes.io/zh-cn/docs/tasks/administer-cluster/certificates/#cfssl>

```bash
mkdir certs
cd certs

cfssl print-defaults config > config.json
cfssl print-defaults csr > csr.json
```

创建一个 JSON 配置文件来生成 CA 文件，例如：`ca-config.json`：

```json
{
    "signing": {
        "default": {
            "expiry": "876000h"
        },
        "profiles": {
            "ca": {
                "usages": [
                    "signing",
                    "key encipherment",
                    "server auth",
                    "client auth"
                ],
                "expiry": "876000h"
            },
            "daemon": {
                "expiry": "876000h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "server auth"
                ]
            },
            "client": {
                "expiry": "876000h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "client auth"
                ]
            }
        }
    }
}

```

创建一个 JSON 配置文件，用于 CA 证书签名请求（CSR），例如：`ca-csr.json`

```yaml
{
    "CN": "kubernetes",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "ST": "Sichuan",
            "L": "Chengdu",
            "O": "AlphaQuant",
            "OU": "AlphaQuant Trust Services"
        }
    ]
}

```

签发 ca

```bash
mkdir ca
cfssl gencert -initca ca-csr.json | cfssljson -bare ca/ca
```

签发服务端 `daemon-csr.json`

```json
{
    "CN": "kubernetes",
    "hosts": [
        "::",
        "::1",
        "127.0.0.1",
        "buildkitd",
        "buildkitd.gitlab-runner",
        "buildkitd.gitlab-runner.svc",
        "buildkitd.gitlab-runner.svc.cluster",
        "buildkitd.gitlab-runner.svc.cluster.local"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "ST": "Sichuan",
            "L": "Chengdu",
            "O": "AlphaQuant",
            "OU": "AlphaQuant Trust Services"
        }
    ]
}

```

生成 server 证书

```bash
mkdir daemon
cfssl gencert -ca=ca/ca.pem -ca-key=ca/ca-key.pem \
     --config=ca-config.json -profile=daemon \
     daemon-csr.json | cfssljson -bare daemon/daemon
```

同样创建 `client-csr.json`

```yaml
{
    "CN": "kubernetes",
    "key": {
        "algo": "rsa",
        "size": 2048
    }
}

```

生成 client 证书

```bash
mkdir client
cfssl gencert -ca=ca/ca.pem -ca-key=ca/ca-key.pem \
     --config=ca-config.json -profile=client \
     client-csr.json | cfssljson -bare client/client
```

基于上面的证书生成在 k8s 中保存证书的 secret 的 yaml 文件`buildkit-daemon-certs-secret.yaml`和`buildkit-client-certs-secret.yaml`:

（注：好像只能是 `ca.pem`，`cert.pem`，`key.pem` 字段名，需要另外手动生成）

```bash
kubectl create secret generic buildkit-daemon-certs \
    -n gitlab-runner \
    --dry-run=client -o yaml \
    --from-file=./daemon \
    > buildkit-daemon-certs-secret.yaml

kubectl create secret generic buildkit-client-certs \
    -n gitlab-runner \
    --dry-run=client -o yaml \
    --from-file=./client \
    > buildkit-client-certs-secret.yaml
```

buildctl 构建镜像时需要访问的私有镜像仓库的 secret 的 yaml 文件`buildkit-client-harbor-secret.yaml`：

```bash
kubectl create secret docker-registry buildkit-client-registry-secret \
  -n gitlab-runner \
  --dry-run=client -o yaml \
  --docker-server=harbor.alpha-quant.tech \
  --docker-username=username \
  --docker-password=password \
  > buildkit-client-registry-secret.yaml
```

对于 gitlab runner，需要

- 证书文件挂载到 `$HOME/.buildctl/certs` 目录下
- `buildkit-client-registry-secret` 中的 `.dockerconfigjson` 文件挂载到 `$HOME/.buildctl/secret` 下

测试镜像构建:

```bash
buildctl \
  --addr tcp://buildkitd:1234 \
  --tlscacert=$HOME/.buildctl/certs/ca.pem \
  --tlscert=$HOME/.buildctl/certs/cert.pem \
  --tlskey=$HOME/.buildctl/certs/key.pem \
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