## 节点安装（Package Download and Installation）

1. 在所有节点下载 BeeGFS 的 repo 文件到 /etc/yum.repos.d/

   ```bash
   wget -O /etc/yum.repos.d/beegfs-rhel9.repo https://www.beegfs.io/release/beegfs_7.3.2/dists/beegfs-rhel9.repo
   ```

   安装依赖的包

   ```bash
   dnf install -y kernel-devel
   dnf groupinstall -y "Development Tools"
   ```

2. 在管理节点安装 Management Service

   ```bash
   dnf install -y beegfs-mgmtd
   ```

3. 在 Metadata 节点安装 Metadata Service

   ```bash
   dnf install -y beegfs-meta
   ```

4. 在 Storage 节点安装 Storage Service

   ```bash
   dnf install -y beegfs-storage
   ```

5. 在 Client 节点安装 Client and Command-line Utils

   ```bash
   dnf install -y beegfs-client beegfs-helperd beegfs-utils beegfs-common kernel-devel
   ```

6. 在监控节点（Mon）安装 Mon Service

   ```bash
   dnf install -y beegfs-mon
   ```

7. 如果需要使用 Infiniband RDMA 功能，还需要在 Metadata 和 Storage 节点安装 libbeegfs-ib

   ```bash
   dnf install -y libbeegfs-ib
   ```

## Storage 节点配置

依次添加 pool：

```bash
# id 2
beegfs-ctl --addstoragepool --desc="ssd"
# id 3
beegfs-ctl --addstoragepool --desc="hdd"
```

依次添加 target：

```bash
# devmaster
## ssd
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool1001 -s 1 -P 2 -i 1001 -m 10.245.245.201
## hdd
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool2001 -s 1 -P 3 -i 2001 -m 10.245.245.201
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool2002 -s 1 -P 3 -i 2002 -m 10.245.245.201

# devnode1
## ssd
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool1101 -s 2 -P 2 -i 1101 -m 10.245.245.201
## hdd
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool2101 -s 2 -P 3 -i 2101 -m 10.245.245.201
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool2102 -s 2 -P 3 -i 2102 -m 10.245.245.201

# devnode2
## ssd
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool1201 -s 3 -P 2 -i 1201 -m 10.245.245.201
## hdd
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool2201 -s 3 -P 3 -i 2201 -m 10.245.245.201
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool2202 -s 3 -P 3 -i 2202 -m 10.245.245.201

```

修改配置文件

```bash
vi /etc/beegfs/beegfs-storage.conf
```

- 配置不使用认证

```ini
connDisableAuthentication = true
```

- 配置网卡

```ini
connInterfacesFile = /etc/beegfs/conn-inf.conf

# /etc/beegfs/conn-inf.conf 内容如下
# 
# ib0
#
```

## Client 节点配置

Client 节点配置 Client（BeeGFS 默认会挂载到 /mnt/beegfs，可以自行在配置文件 `/etc/beegfs/beegfs-mounts.conf` 中修改）

```bash
# 所有节点相同
/opt/beegfs/sbin/beegfs-setup-client -m 10.245.245.201
```

修改配置文件

```bash
vi /etc/beegfs/beegfs-helperd.conf
vi /etc/beegfs/beegfs-client.conf
```

- 配置不使用认证

```ini
connDisableAuthentication = true
```

- 配置网卡

```ini
connInterfacesFile = /etc/beegfs/conn-inf.conf
connRDMAInterfacesFile = /etc/beegfs/conn-inf.conf

# /etc/beegfs/conn-inf.conf 内容如下
# 
# ib0
#
```

## 监控节点

监控节点修改配置文件：

```bash
vi /etc/beegfs/beegfs-mon.conf
```

- 配置管理节点地址

```ini
sysMgmtdHost = 10.245.245.201
```

- 配置不使用认证

```ini
connDisableAuthentication = true
```

- 配置网卡

```ini
connInterfacesFile = /etc/beegfs/conn-inf.conf

# /etc/beegfs/conn-inf.conf 内容如下
# 
# ib0
#
```
