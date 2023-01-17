官方文档：

- 安装文档：<https://github.com/minio/operator/blob/master/README.md>

## 概述

MinIO 是 kubernetes 原生的高性能对象存储，兼容 Amazon 的 s3 API。

MinIO Operator 是一个工具，该工具扩展了 k8s 的 api，可以通过 minio operator 在公有云和私有云上来部署 MinIO Tenants。

## 架构

![Tenant Architecture](.assets/architecture.png)

## MinIO 集群部署过程

### 安装 kubectl-minio 插件

通过 krew 安装插件：

```bash
kubectl krew update

kubectl krew install minio
```

查看安装后的版本

如果出现以下的部分，说明 kubectl-minio 插件已经安装成功

```bash
> kubectl minio version

v4.5.7
```

也可以通过 github 上去获取需要的版本，地址：<https://github.com/minio/operator/releases>，通过二进制进行安装

```bash
wget -qO- https://github.com/minio/operator/releases/latest/download/kubectl-minio_linux_amd64.zip | bsdtar -xvf- -C /usr/local/bin

chmod +x /usr/local/bin/kubectl-minio
```

注意：如果 kubectl minio 不是具体的版本，而是类似如下的信息：

```bash
> kubectl minio version

DEVELOPMENT.GOGET
```

可能会导致后续的初始化和安装失败，并且 operator 打开之后，功能会不完整。

### 初始化 minio operator

kubectl-minio 插件完成之后，需要进行初始化的操作，即通过 kubectl minio 命令安装 minio operator 服务

执行以下的命令进行初始化

注意：可以提前将镜像下载到本地的 harbor，因为，本地有这样的镜像，在不同的环境部署的时候会节省时间

```bash
export THIRD_REPO="docker-registry.local.liaosirui.com:5000/third"

kubectl minio init \
  --image=${THIRD_REPO}/docker.io/minio/operator:v4.5.7 \
  --namespace=minio \
  --cluster-domain=cluster.local \
  --default-console-image=${THIRD_REPO}/docker.io/minio/console:v0.22.5 \
  --default-minio-image=${THIRD_REPO}/docker.io/minio/minio:RELEASE.2023-01-12T02-06-16Z \
  --image-pull-secret=docker-registry-image-pull-secrets

```

转发 console

```bash
kubectl minio proxy -n minio
```



