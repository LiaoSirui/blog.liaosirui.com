官方：

- Github 仓库：<https://github.com/NetApp/beegfs-csi-driver>

## 安装版本

使用当前最新分支：v1.4.0，<https://github.com/NetApp/beegfs-csi-driver/tree/v1.4.0>

k8s 版本为 1.26.1（此版本不在文档声明的支持范围，建议使用 1.25.2）

```bash
NAME        STATUS   ROLES           AGE    VERSION
devmaster   Ready    control-plane   7d9h   v1.26.1
devnode1    Ready    <none>          7d9h   v1.26.1
devnode2    Ready    <none>          7d9h   v1.26.1
```

beegfs 集群的版本：v7.3.2（文档中声明支持的版本为 BeeGFS versions 7.3.1+ or 7.2.7+）

```bash
Management
==========
devmaster [ID: 1]: reachable at 10.245.245.201:8008 (protocol: TCP)

Metadata
==========
devmaster [ID: 1]: reachable at 10.245.245.201:8005 (protocol: RDMA)

Storage
==========
devmaster [ID: 1]: reachable at 10.245.245.201:8003 (protocol: RDMA)
devnode1 [ID: 2]: reachable at 10.245.245.211:8003 (protocol: RDMA)
devnode2 [ID: 3]: reachable at 10.245.245.212:8003 (protocol: RDMA)
```

## 安装

### 客户端配置

由于集群不使用认证信息，因此需要更改 `deploy/k8s/overlays/default/csi-beegfs-config.yaml`

声明如下内容：

```yaml
config:
  beegfsClientConf:
    connDisableAuthentication: "true"
```

其他的示例配置，参考：<https://github.com/NetApp/beegfs-csi-driver/blob/v1.4.0/deploy/k8s/overlays/examples/csi-beegfs-config.yaml>

```yaml
config:
  connInterfaces:
    - ib0
    - eth0
  connNetFilter:
    - 10.0.0.1/24
    - 10.0.0.2/24
  connTcpOnlyFilter:
    - 10.0.0.1/24
  # The connRDMAInterfaces parameter requires BeeGFS client 7.3.0 or later.
  connRDMAInterfaces:
    - ib0
    - ib1
  beegfsClientConf:
    # All beegfs-client.conf values must be strings. Quotes are required on integers and booleans.
    connMgmtdPortTCP: "9008"
    connUseRDMA: "true"
    # The connTCPFallbackEnabled parameter requires BeeGFS client 7.3.0 or later.
    connTCPFallbackEnabled: "false"

fileSystemSpecificConfigs:
  - sysMgmtdHost: some.specific.file.system
    config:
      connInterfaces:
        - ib1
        - eth1
      connNetFilter:
        - 10.0.0.3/24
        - 10.0.0.4/24
      connTcpOnlyFilter:
        - 10.0.0.3/24
      beegfsClientConf:
        # All beegfs-client.conf values must be strings. Quotes are required on integers and booleans.
        connMgmtdPortTCP: "10008"
        connUseRDMA: "true"

nodeSpecificConfigs:
  - nodeList:
      - node1
      - node2
    config:
      connInterfaces:
        - ib2
        - eth2
      connNetFilter:
        - 10.0.0.5/24
        - 10.0.0.6/24
      connTcpOnlyFilter:
        - 10.0.0.5/24
      beegfsClientConf:
        # All beegfs-client.conf values must be strings. Quotes are required on integers and booleans.
        connMgmtdPortTCP: "11008"
        connUseRDMA: "true"

    fileSystemSpecificConfigs:
      - sysMgmtdHost: some.specific.file.system
        config:
          connInterfaces:
            - ib3
            - eth3
          connNetFilter:
            - 10.0.0.5/24
            - 10.0.0.6/24
          connTcpOnlyFilter:
            - 10.0.0.5/24
          beegfsClientConf:
            # All beegfs-client.conf values must be strings. Quotes are required on integers and booleans.
            connMgmtdPortTCP: "12008"
            connUseRDMA: "true"

```

本次使用的配置为：
```yaml
config:
  connInterfaces:
    - ib0
    - eth0
  connRDMAInterfaces:
    - ib0
  beegfsClientConf:
    connDisableAuthentication: "true"
    connMgmtdPortTCP: "9008"
    connUseRDMA: "true"
    connTCPFallbackEnabled: "false"

```

### 认证配置

同时在认证文件  `deploy/k8s/overlays/default/csi-beegfs-connauth.yaml` 中声明：

```yaml
- sysMgmtdHost: 10.245.245.201
  connAuth: ""
```

### 应用部署清单

```bash
kubectl apply -k deploy/k8s/overlays/default
```

查看部署后的 pod

```bash
```

