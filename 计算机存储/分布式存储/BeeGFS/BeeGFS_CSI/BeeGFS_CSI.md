## beegfs-csi-driver 简介

官方：

- Github 仓库：<https://github.com/ThinkParQ/beegfs-csi-driver>

## 安装版本

使用当前最新分支：v1.6.0

## 安装

### 配置宿主机环境

```bash
# 安装 dkms 模块
dnf install -y beegfs-client-dkms beegfs-helperd beegfs-utils crudini
```

构建日志存放在：

```bash
/var/lib/dkms/beegfs/<BeeGFS version>/$(uname -r)/x86_64/log/make.log
```

加载内核模块

```bash
modprobe beegfs
```

自动加载

```bash
> cat /etc/modules-load.d/beegfs-client-dkms.conf
# Load the BeeGFS client module at boot
beegfs
```

同步所需镜像

```bash
registry.k8s.io/sig-storage/csi-provisioner:v3.5.0
registry.k8s.io/sig-storage/csi-node-driver-registrar:v2.8.0
ghcr.io/thinkparq/beegfs-csi-driver:v1.6.0
```

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



