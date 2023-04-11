## Docker 环境下 lxcfs 使用

开启方式：

```bash
modprobe fuse
```

开启 FUSE 模块支持

```bash
> lsmod | grep fuse

fuse                  172032  1
```

安装 lxcfs 的 RPM 包

``` bash
dnf install lxcfs
```

启动服务

```bash
systemctl start lxcfs
```

查看状态

```bas
systemctl status lxcfs
```

默认的启动命令是

```bash
/usr/bin/lxcfs /var/lib/lxcfs
```

测试

```bash
docker run -it --rm \
	--cpus 2 --memory 4g --memory-swap 4g \
  -v /var/lib/lxcfs/proc/cpuinfo:/proc/cpuinfo:rw \
  -v /var/lib/lxcfs/proc/diskstats:/proc/diskstats:rw \
  -v /var/lib/lxcfs/proc/loadavg:/proc/loadavg:rw \
  -v /var/lib/lxcfs/proc/meminfo:/proc/meminfo:rw \
  -v /var/lib/lxcfs/proc/stat:/proc/stat:rw \
  -v /var/lib/lxcfs/proc/slabinfo:/proc/slabinfo:rw \
  -v /var/lib/lxcfs/proc/swaps:/proc/swaps:rw \
  -v /var/lib/lxcfs/proc/uptime:/proc/uptime:rw \
  -v /var/lib/lxcfs/sys/devices/system/cpu:/sys/devices/system/cpu \
  --security-opt seccomp=unconfined \
  rockylinux/rockylinux:9.1.20221123 bash

```

在容器中安装工具集

```bash
dnf install -y epel-release
dnf install -y procps-ng htop util-linux-core
```

测试效果

```bash
[root@5cbb01cecd60 /]# free -g
               total        used        free      shared  buff/cache   available
Mem:               4           0           3           0           0           3
Swap:              0           0           0

[root@5cbb01cecd60 /]# uptime
 05:58:40 up 2 min,  0 users,  load average: 0.18, 0.25, 0.34
```

可以看到 total 的内存为 4g，配置已经生效