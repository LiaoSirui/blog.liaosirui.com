## 安装 Sealos

添加 Yum 源

```bash
> cat >> /etc/yum.repos.d/sealos.repo << __EOF__
# refer: https://github.com/labring/sealos/releases
[fury]
name=Gemfury Private Repo
baseurl=https://yum.repo.sealos.io/
enabled=1
gpgcheck=0
__EOF__
```

使用 DNF 安装命令行

```bash
dnf install -y sealos
```

## 安装单节点集群

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
