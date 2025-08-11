## 安装 Sealos

添加 Yum 源

```bash
> cat >> /etc/yum.repos.d/sealos.repo << __EOF__
# refer: https://github.com/labring/sealos/releases
[fury]
name=labring Yum Repo
baseurl=https://yum.fury.io/labring/
enabled=1
gpgcheck=0
__EOF__
```

使用 DNF 安装命令行

```bash
dnf install -y sealos
```

## 安装单节点集群

### 安装需求

- 每个集群节点应该有不同的主机名。主机名不要带下划线。
- 所有节点的时间需要同步。
- 需要在 K8s 集群的第一个 master 节点上运行 `sealos run` 命令，目前集群外的节点不支持集群安装
- 建议使用干净的操作系统来创建集群。不要自己装 Docker！（仅通过 Docker 命令来检测）

### 镜像选择

```bash
skopeo list-tags docker://docker.io/labring/kubernetes
```

### 初始化节点

```bash
sealos run \
  labring/kubernetes:v1.23.0 \
  labring/helm:v3.8.2 labring/calico:v3.24.1 \
  --masters 10.244.244.21 \
  --single \
  --debug 

# 安装 node: --nodes 10.244.244.21
```

## 参数详解

### 新增节点

- 增加 master

```bash
sealos join --master 192.168.0.6 --master 192.168.0.7

# 或者多个连续 IP
sealos join --master 192.168.0.6-192.168.0.9
```

- 增加 node

```bash
sealos join --node 192.168.0.6 --node 192.168.0.7

# 或者多个连续 IP
sealos join --node 192.168.0.6-192.168.0.9  
```

### 删除节点

- 删除指定 master 节点

```bash
sealos clean --master 192.168.0.6 --master 192.168.0.7

# 或者多个连续 IP
sealos clean --master 192.168.0.6-192.168.0.9
```

- 删除指定 node 节点

```bash
sealos clean --node 192.168.0.6 --node 192.168.0.7

# 或者多个连续IP
sealos clean --node 192.168.0.6-192.168.0.9
```

- 卸载集群

```bash
sealos clean --all
```
