## lvmcache

`lvmcache` 是由逻辑卷 (LV) 组成的超速缓存机制。它使用 `dm-cache` 内核驱动程序，支持直写（默认）和写回超速缓存模式

`lvmcache` 可将大型慢速 LV 的部分数据动态迁移到更快、更小的 LV，从而提高其性能

- 大型慢速 LV 称为源 LV

- LVM 将小型快速 LV 称为超速缓存池 LV。由于 dm-cache 的要求，LVM 进一步将超速缓存池 LV 分割成两个设备：
  - 超速缓存数据 LV 。来自源 LV 的数据块副本保存在超速缓存数据 LV 中，以提高速度
  - 超速缓存元数据 LV。超速缓存元数据 LV 保存记帐信息，这些信息指定数据块的储存位置

## 配置 `lvmcache`

创建源 LV。创建新 LV，或使用现有 LV 作为源 LV

```bash
lvcreate -n ORIGIN_LV -L 100G vg /dev/SLOW_DEV
```

创建超速缓存数据 LV。此 LV 将保存来自源 LV 的数据块。此 LV 的大小是超速缓存的大小，将报告为超速缓存池 LV 的大小

```bash
lvcreate -n CACHE_DATA_LV -L 10G vg /dev/FAST
```

建超速缓存元数据 LV。此 LV 将保存超速缓存池元数据。此 LV 的大小应该比超速缓存数据 LV 大约小 1000 倍，其最小大小为 8MB

```bash
lvcreate -n CACHE_METADATA_LV -L 12M vg /dev/FAST
```

列出目前为止所创建的卷

```bash
lvs -a vg
LV                VG   Attr        LSize   Pool Origin
cache_data_lv     vg   -wi-a-----  10.00g
cache_metadata_lv vg   -wi-a-----  12.00m
origin_lv         vg   -wi-a----- 100.00g
```

创建超速缓存池 LV。将数据 LV 和元数据 LV 组合成一个超速缓存池 LV。同时还可以设置超速缓存池 LV 的行为

- `CACHE_POOL_LV` 与 `CACHE_DATA_LV `同名
- `CACHE_DATA_LV` 重命名为 `CACHE_DATA_LV_cdata`，并且会隐藏起来
- `CACHE_META_LV` 重命名为 `CACHE_DATA_LV_cmeta`，并且会隐藏起来

```bash
lvconvert \
    --type cache-pool \
    --poolmetadata vg/cache_metadata_lv \
    vg/cache_data_lv

> lvs -a vg
LV                     VG   Attr       LSize   Pool Origin
cache_data_lv          vg   Cwi---C---  10.00g
[cache_data_lv_cdata]  vg   Cwi-------  10.00g
[cache_data_lv_cmeta]  vg   ewi-------  12.00m
origin_lv              vg   -wi-a----- 100.00g
```

创建超速缓存 LV。通过将超速缓存池 LV 链接到源 LV 来创建超速缓存 LV

- 用户可访问的超速缓存 LV 与源 LV 同名，源 LV 将变成重命名为 ORIGIN_LV_corig 的隐藏 LV

- CacheLV 与 ORIGIN_LV 同名

- ORIGIN_LV 重命名为 ORIGIN_LV_corig，并且会隐藏起来

```bash
lvconvert \
    --type cache \
    --cachepool vg/cache_data_lv \
    vg/origin_lv

> lvs -a vg
LV              VG   Attr       LSize   Pool   Origin
cache_data_lv          vg   Cwi---C---  10.00g
[cache_data_lv_cdata]  vg   Cwi-ao----  10.00g
[cache_data_lv_cmeta]  vg   ewi-ao----  12.00m
origin_lv              vg   Cwi-a-C--- 100.00g cache_data_lv [origin_lv_corig]
[origin_lv_corig]      vg   -wi-ao---- 100.00g
```

## 去除超速缓存池

### 从超速缓存 LV 分离超速缓存池 LV

从超速缓存 LV 断开与超速缓存池 LV 的连接，留下一个未使用的超速缓存池 LV 和一个未超速缓存的源 LV。数据将根据需要从超速缓存池写回到源 LV

```bash
lvconvert --splitcache vg/origin_lv
```

### 去除超速缓存池 LV 但不去除其源 LV

以下命令会根据需要将数据从超速缓存池写回到源 LV，然后去除超速缓存池 LV，留下未超速缓存的源 LV

```bash
lvremove vg/cache_data_lv
```

也可以使用以下替代命令从超速缓存 LV 断开与超速缓存池的连接，并删除超速缓存池

```bash
lvconvert --uncache vg/origin_lv
```

### 去除源 LV 和超速缓存池 LV

去除超速缓存 LV 会同时去除源 LV 和链接的超速缓存池 LV

```bash
lvremove vg/origin_lv
```

## 参考资料

- <https://docs.redhat.com/zh-cn/documentation/red_hat_enterprise_linux/8/html/system_design_guide/enabling-caching-to-improve-logical-volume-performance_system-design-guide#enabling-dm-cache-caching-with-a-cachepool-for-a-logical-volume_enabling-caching-to-improve-logical-volume-performance>