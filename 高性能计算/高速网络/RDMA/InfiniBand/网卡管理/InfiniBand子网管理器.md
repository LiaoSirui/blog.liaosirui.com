## 配置 InfiniBand 子网管理器

所有 InfiniBand 网络都必须运行子网管理器才能正常工作。即使两台机器没有使用交换机直接进行连接，也是如此。

有可能有一个以上的子网管理器。在这种情况下，一个 master 充当一个主子网管理器，另一个子网管理器充当从属子网管理器，当主子网管理器出现故障时将接管。

大多数 InfiniBand 交换机都包含一个嵌入式子网管理器。但是，如果您需要更新的子网管理器，或者您需要更多控制，请使用 Red Hat Enterprise Linux 提供的 `OpenSM` 子网管理器。

### 安装

```bash
dnf install -y opensm
```

启用并启动 `opensm` 服务：

```bash
systemctl enable --now opensm
```

参考文档

- <https://docs.nvidia.com/networking/display/mlnxofedv461000/opensm>

### 配置 

使用 `ibstat` 程序获取端口的 GUID：

```
> ibstat -d
CA 'mlx4_0'
	CA type: MT4103
	Number of ports: 2
	Firmware version: 2.42.5700
	Hardware version: 0
	Node GUID: 0x480fcffffff09140
	System image GUID: 0x480fcffffff09143
	Port 1:
		State: Active
		Physical state: LinkUp
		Rate: 40
		Base lid: 2
		LMC: 0
		SM lid: 4
		Capability mask: 0x0259486a
		Port GUID: 0x480fcffffff09141
		Link layer: InfiniBand
	Port 2:
		State: Down
		Physical state: Polling
		Rate: 10
		Base lid: 0
		LMC: 0
		SM lid: 0
		Capability mask: 0x02594868
		Port GUID: 0x480fcffffff09142
		Link layer: InfiniBand
```

> 有些 InfiniBand 适配器在节点、系统和端口中使用相同的 GUID。

编辑 `/etc/sysconfig/opensm` 文件并在 `GUIDS` 参数中设置 GUID：

```bash
GUIDS="GUID_1 GUID_2"
```

如果子网中有多个子网管理器，可以设置 `PRIORITY` 参数。例如：

```
PRIORITY=15
```

### 配置日志

配置文件 `/etc/rdma/opensm.conf`

```bash
# Maximum size of the log file in MB. If overrun, log is restarted.
log_max_size 100
```

