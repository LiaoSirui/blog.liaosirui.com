## 简介

- 查看 numa 状态

```bash
numactl --show

numactl --hardware
```

详情

```
> numactl --show
policy: default
preferred node: current
physcpubind: 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31
cpubind: 0
nodebind: 0
membind: 0
preferred:

> numactl --hardware
available: 1 nodes (0)
node 0 cpus: 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31
node 0 size: 128172 MB
node 0 free: 82387 MB
node distances:
node   0
  0:  10
```

此系统共有 1 个 node，node0 有全部 CPU 和内存

还可以通过下面的命令查看

```bash
numastat
```

详情

```
> numastat
                           node0
numa_hit              1984974541
numa_miss                      0
numa_foreign                   0
interleave_hit              1923
local_node            1984967448
other_node                     0
```

说明：

- `numa_hit`：该节点成功分配本地内存访问的内存大小
- `numa_miss`：内存访问分配到另一个 node 的大小，该值和另一个 node 的 numa_foreign 相对应
- `local_node`：该节点的进程成功在本节点上分配内存访问的大小
- `other_node`：该节点进程在其它节点上分配的内存访问的大小

注意：`miss` 和 `foreign` 的值越高，就考虑 `CPU` 绑定

## 使用示例

### 内存交织分配模式

使用 `--interleave` 参数，如占用内存的 mongodb 程序，共享所有 node 内存：

```bash
numactl --interleave=all mongod -f /etc/mongod.conf
```

### 内存绑定

```bash
numactl --cpunodebind=0 --membind=0 python param
numactl --physcpubind=0 --membind=0 python param
```

### CPU绑定

```bash
numactl -C 0-1 ./test
```

将应用程序 test 绑定到 0~1 核上运行