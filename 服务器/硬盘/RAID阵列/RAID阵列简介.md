## RAID 级别

### RAID 0

![img](./.assets/RAID阵列简介/422bfffd169292c5fe40c72e894032ad.png)

### RAID 1

![img](./.assets/RAID阵列简介/53806304a8bc83582226ae809e9df47c.png)

### RAID 5

![img](./.assets/RAID阵列简介/67170f56ee80de0415ecbe3ac1a506a8.png)

### RAID 6

![img](./.assets/RAID阵列简介/e35c085a520de5e63adfda77c286cfd2.png)

### RAID 10

![img](./.assets/RAID阵列简介/f0425e984e8946c4182e978de7df40c1.png)

### RAID 50

![img](./.assets/RAID阵列简介/93576d7e782d2424202dbd3d4e4f8fb7.png)

### RAID 60

![img](./.assets/RAID阵列简介/ef8d0ad730e3733ba012a4a50a1181ef.png)

## RAID 对比

| RAID 等级   | 冗余能力 | 读性能 | 写性能 | 存储效率 | 适用场景           |
| ----------- | -------- | ------ | ------ | -------- | ------------------ |
| **RAID 0**  | 无       | 最高   | 最高   | 100%     | 高性能、非关键数据 |
| **RAID 1**  | 单盘冗余 | 高     | 低     | 50%      | 高读性能需求       |
| **RAID 5**  | 单盘冗余 | 高     | 中     | N-1      | 平衡性能与容错     |
| **RAID 6**  | 双盘冗余 | 高     | 低     | N-2      | 高可靠性需求       |
| **RAID 10** | 单盘冗余 | 非常高 | 中     | 50%      | 高读写性能和容错   |
| **RAID 50** | 单盘冗余 | 高     | 中     | (N×K)-K  | 大规模存储         |
| **RAID 60** | 双盘冗余 | 高     | 低     | (N×K)-2K | 超大规模存储       |

以上几个磁盘阵列：

- 从读的能力来说：`RAID 5 ≈ RAID 6 ≈ RAID 60 > RAID 0 ≈ RAID 10 > RAID 3 ≈ RAID 1`
- 从写的能力来说：`RAID 10 > RAID 50 > RAID 1 > RAID 3 > RAID 5 ≈ RAID 6 ≈ RAID 60`

比较 8 块硬盘的 RAID 10 & 8 块硬盘的 RAID 60

- 重建时间：RAID 10

- 可靠性（假设冗余）：RAID 60

- 数据完整性：取决于文件系统，而不是 RAID

- 镜像 RAID 的重建速度往往比 RAID 6 快，但快不了多少。

RAID 60 具有更好的冗余，因为有两组四块硬盘，并且可以丢失每组中的任意两块硬盘，总共四个故障，数据仍然存在。如果在任何镜像对中丢失了两块硬盘，数据就没了。对于生产和备份，更倾向于选择 RAID 60。