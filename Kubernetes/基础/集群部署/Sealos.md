
## 安装单节点集群

```bash
sealos init --interface enp2s0 \
    --master 192.168.1.99 \
    --user root \
    --version v1.18.14 \
    --pkg-url=./kube1.18.14.tar.gz
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
