```bash
# xfs_info /mnt/nvme1n1
meta-data=/dev/nvme0n1           isize=512    agcount=4, agsize=15628694 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=1, sparse=1, rmapbt=0
         =                       reflink=1    bigtime=1 inobtcount=1 nrext64=0
data     =                       bsize=4096   blocks=62514774, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0, ftype=1
log      =internal log           bsize=4096   blocks=30524, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0

# xfs_info /dev/vda2
1    meta-data=/dev/vda2     isize=256    agcount=4, agsize=65536 blks
2             =              sectsz=512   attr=2, projid32bit=1
3             =              crc=0        finobt=0
4    data     =              bsize=4096   blocks=262144, imaxpct=25
5             =              sunit=0      swidth=0 blks
6    naming   =version 2     bsize=4096   ascii-ci=0 ftype=0
7    log      =internal      bsize=4096   blocks=2560, version=2
8             =              sectsz=512   sunit=0 blks, lazy-count=1
9    realtime =none          extsz=4096   blocks=0, rtextents=0
```

- 第 1 行里面的 isize 指的是 inode 的容量，每个有 256bytes 这么大。至于 agcount 则是储存区群组 (allocation group) 的个数，共有 4 个， agsize 则是指每个储存区群组具有 65536 个 block 。配合第 4 行的 block 设定为 4K，因此整个档案系统的容量应该就是 `4*65536*4K` 这么大
- 第 2 行里面 sectsz 指的是逻辑磁区 (sector) 的容量设定为 512bytes 这么大的意思
- 第 4 行里面的 bsize 指的是 block 的容量，每个 block 为 4K 的意思，共有 262144 个 block 在这个档案系统内
- 第 5 行里面的 sunit 与 swidth 与磁碟阵列的 stripe 相关性较高
- 第 7 行里面的 internal 指的是这个登录区的位置在档案系统内，而不是外部设备的意思。且占用了 `4K * 2560` 个 block，总共约 10M 的容量
- 第 9 行里面的 realtime 区域，里面的 extent 容量为 4K。不过目前没有使用