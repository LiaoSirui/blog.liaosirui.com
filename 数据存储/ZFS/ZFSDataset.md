## ZFS Dataset

Dataset(数据集) 是 ZFS 中的核心管理单元,是 zpool 内部的逻辑存储对象。

## 层级关系

```
zpool(存储池)← 物理层:由磁盘/vdev 组成
  └── dataset(数据集)← 逻辑层:实际使用存储的单元
```

可以这样理解:

- zpool 像一个大的"存储资源池",把所有磁盘的容量聚合起来
- dataset 是从池里划出来的逻辑单元,不需要预先指定大小,所有 dataset 共享整个池的空间

## Dataset 的四种类型

Filesystem(文件系统)—— 最常用

```bash
zfs create tank/home
zfs create tank/home/alice
```

- 表现为一个可挂载的文件系统(自动挂载到 `/tank/home`)
- 类似传统的"分区 + 文件系统",但创建瞬间完成,大小弹性伸缩

Volume(zvol,块设备)

```bash
zfs create -V 100G tank/vm-disk
```

- 表现为块设备(`/dev/zvol/tank/vm-disk`)
- 可以格式化成 ext4、给虚拟机当磁盘、做 iSCSI 导出等
- 这就是 ZFS 替代 LVM 逻辑卷的方式

Snapshot(快照)

```bash
zfs snapshot tank/home@2024-01-15
```

- 某个 dataset 的只读时间点副本,名字用 `@` 分隔

Clone(克隆)

```bash
zfs clone tank/home@2024-01-15 tank/home-test
```

- 基于快照创建的**可写**副本,初始不占额外空间

## 为什么要划分多个 Dataset?

这是 ZFS 的最佳实践,因为每个 dataset 可以独立设置属性和管理:

```bash
# 每个 dataset 独立配置
zfs set compression=lz4 tank/home        # 开启压缩
zfs set quota=50G tank/home/alice        # 配额限制
zfs set recordsize=1M tank/media         # 大文件优化
zfs set recordsize=16K tank/database     # 数据库优化
zfs set atime=off tank/backup            # 关闭访问时间

# 独立做快照/备份
zfs snapshot tank/database@before-upgrade
zfs send tank/home@snap | ssh remote zfs receive backup/home
```

## 重要特性

| 特性         | 说明                                                         |
| ------------ | ------------------------------------------------------------ |
| 共享空间     | 所有 dataset 动态共享池容量,无需预分配                       |
| 属性继承     | 子 dataset 自动继承父级属性(如 tank/home 开压缩,tank/home/alice 也压缩) |
| 嵌套层级     | 可以像目录树一样无限嵌套                                     |
| 独立管理     | 快照、配额、压缩、加密等都以 dataset 为粒度                  |
| 创建成本极低 | 创建一个 dataset 只是元数据操作,可以创建成百上千个           |

