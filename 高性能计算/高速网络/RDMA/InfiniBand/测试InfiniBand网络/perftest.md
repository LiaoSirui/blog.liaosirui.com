## perftest 简介

perftest 提供了很全面的 RDMA 测试工具，如下：

- Send - ib_send_bw and ib_send_lat
- RDMA Read - ib_read_bw and ib_read_lat
- RDMA Write - ib_write_bw and ib_write_lat
- RDMA Atomic - ib_atomic_bw and ib_atomic_lat
- Native Ethernet (when working with MOFED2) - raw_ethernet_bw, raw_ethernet_lat

官方代码仓库：<https://github.com/linux-rdma/perftest>

## 性能测试

### ib_read_bw

测试 RDMA 读取速度

```bash
# 在服务端执行
ib_read_bw -a -d mlx4_0 -F --report_gbits

# 在客户端执行(注意：10.244.244.164 为服务端的 IB 网络中的 IP 地址)
ib_read_bw -a -F 10.244.244.164 -d mlx4_0 --report_gbits
```

### ib_write_bw

这里测试的写带宽，如果要测试读带宽把 write 改成 read 就可以了

第一台执行

```bash
ib_write_bw
```

第二台执行

```bash
ib_write_bw <对端的 IP 地址>
```

测试 RDMA 写入速度

```bash
# 在服务端执行
ib_write_bw -a -d mlx4_0

# 在客户端执行(注意：10.244.244.164 为服务端的 IB 网络中的 IP 地址)
ib_write_bw -a -F 10.244.244.164 -d mlx4_0 --report_gbits
```

### ib_send_bw

服务端运行

```bash
ib_send_bw -a -c UD -d mlx4_0 -i 1
```

客户端运行

```bash
ib_send_bw -a -c UD -d mlx4_0 -i 1 172.16.0.102
```

## iperf3

iperf 需要用 numactl 绑定 CPUID, 以避免 NUMA 访问的性能问题

```bash
# 服务端
numactl --cpunodebind=0 iperf -s -P8 -w 256K

# 客户端
numactl --cpunodebind=0 iperf -c 10.244.244.164  -t 60 -P8 -w 512K
```

## 测试网络延迟

延迟的测试和带宽的测试差不多，只不过在命令上有点不同只要把 bw 改成 lat 就可以了

第一台执行

````bash
# 测试写延迟
ib_write_lat

# 测试读延迟
ib_read_lat
````

第二台执行

```bash
# 测试写延迟
ib_write_lat <对端的 IP 地址>

# 测试读延迟
ib_read_lat <对端的 IP 地址>
```

## 参考文档

- <https://yaohuablog.com/zh/Infiniband%E6%80%A7%E8%83%BD%E6%B5%8B%E8%AF%95>