## 阵列管理工具介绍

MegaCLI 和 StorCLI 是 Broadcom（原 LSI）提供的两种命令行工具，主要用于管理和监控 RAID 阵列卡。两者的适用场景有所不同，虽然都能管理 RAID 控制器，但在使用体验和功能覆盖上存在一些差异。以下是这两种工具的比较和适用场景

### MegaCLI

- 简介: MegaCLI 是较早的命令行工具，专门用于管理 LSI 的 MegaRAID 控制器。
- 支持: 它广泛支持旧版 LSI 阵列卡，如 MegaRAID 92xx 和 3108 等。
- 功能: MegaCLI 功能强大，但命令语法较为复杂，且不易记忆。它能够执行诸如创建 RAID 阵列、查看驱动器状态、配置缓存策略、检查或修复 RAID 阵列等任务。
- 适用场景:
  - 老系统的管理: 对于较早的 LSI RAID 控制器和系统，MegaCLI 是首选工具。
  - 批量操作: MegaCLI 适合用于脚本化的批量管理任务。
  - 现有环境中的兼容性: 如果已有管理工具或自动化脚本基于 MegaCLI，继续使用它会更为简便。

### StorCLI

- 简介: StorCLI 是 MegaCLI 的继任者，旨在提供更现代化和用户友好的 RAID 管理工具。它主要支持最新的 MegaRAID 阵列卡，如 LSI 93xx 和部分新型号如 3580。
- 支持: StorCLI 支持新一代 MegaRAID 控制器（例如 SAS 3.0 系列的阵列卡），并能与较新的操作系统和硬件兼容。
- 功能: StorCLI 提供了更直观、简洁的命令结构，并且与 MegaCLI 功能相似，支持创建、管理和监控 RAID 阵列，还可以生成详细的控制器状态报告。
- 适用场景:
  - 现代硬件和系统: 如果你的系统使用的是较新的 Broadcom/LSI 阵列卡（如 9361、9362 系列），StorCLI 是更合适的工具。
  - 易用性和学习成本: StorCLI 的命令结构更直观，降低了操作复杂性，更适合日常维护和管理。
  - 复杂环境管理: 在复杂的数据中心环境中，StorCLI 提供了与新系统更好的兼容性和更高的稳定性。

## StorCLI 安装

安装完成后二进制在目录 `/opt/MegaRAID/storcli/`

找到官方最新版本：<https://www.broadcom.com/site-search?page=1&per_page=10&q=storcli&sort_direction[pages]=desc&sort_field[pages]=sort_date>

```bash
update-alternatives --install /usr/bin/storcli64 storcli64 /opt/MegaRAID/storcli/storcli64 1
update-alternatives --set storcli64 /opt/MegaRAID/storcli/storcli64
```

## StorCLI 使用

### 基础语法

storcli 基础语法为：`storcli <[object identifier]> <verb><[adverb | attributes | properties] > <[key=value]></verb>`

| object identifier | description                                                  |
| ----------------- | ------------------------------------------------------------ |
| 空                | 当参数为空时，该命令为系统命令                               |
| `/cx`             | 控制器（RAID卡）特定指令（`/controller x`），当服务器存在多张raid卡时，可通过指定不同控制器ID切换不同raid卡配置 |
| `/cx/vx`          | 虚拟磁盘特定指令（`/controller x/virtual driver x`），可以选择指定控制器下的指定虚拟磁盘 |
| `/cx/ex`          | 机箱面板特定指令（`/controller x/enclosure x`），可以选择指定控制器下的指定机箱面板 如36盘位服务通常有两个机箱面板，前面板一根SAS线拖24块盘，后面板一根SAS线拖12块盘 |
| `/cx/ex/sx`       | 插槽/物理磁盘特定指令( `/controller x/enclosure x/slot x`)，可以选择指定控制器下的指定机箱面板的指定磁盘 |
| `/cx/fx`          | 外部配置特定指令（`/controller x/foreign configuration x`），可以选择指定控制器下的指定外部配置 如磁盘残留有之前的RAID配置信息，可以选择对应磁盘进行配置清理或者导入操作 |

`x` 代表数字编号，当 x 为 all 时表示所有，如`/c0/vall`表示控制器 0 下所有的虚拟磁盘

| verb    | description                                   |
| ------- | --------------------------------------------- |
| add     | 增加配置，如虚拟磁盘（VD）、热备盘（spare）等 |
| del     | 删除配置，如虚拟磁盘（VD）、热备盘（spare）等 |
| set     | 为属性设置特定值                              |
| show    | 查看选定对象所有的属性信息                    |
| start   | 开始一个操作                                  |
| pause   | 暂停正在进行的操作                            |
| resume  | 恢复已暂停的操作                              |
| suspend | 中止正在进行的操作，已中止的操作不能恢复      |
| compare | 比较输入值与系统值差异                        |
| flush   | 下刷控制器或者磁盘缓存                        |
| import  | 将外部配置导入到驱动器                        |
| expand  | 扩展虚拟磁盘容量                              |

### 设置硬盘直通功能

查看是否支持

```bash
storcli64 /c0 show all|grep -i jbod
```

可以看到 `support JBOD = Yes` , 也就是说raid卡支持 jbod 模式
但是 `Enable JBOD = No` , 说明当前 raid 卡没有开启 jbod 模式,此时需要开启

设置RAID卡的硬盘直通功能的使能情况，并指定直通硬盘

命令格式

```bash
storcli64 /c<controller_id> set jbod=<state>

storcli64 /c<controller_id>/e<enclosure_id>/s<slot_id> set JBOD
```

| 参数          | 参数说明                   | 取值        |
| ------------- | -------------------------- | ----------- |
| controller_id | 硬盘所在 RAID 卡的 ID      | –           |
| enclosure_id  | 硬盘所在 Enclosure 的 ID   | –           |
| slot_id       | 硬盘槽位号                 | –           |
| state         | RAID 卡 JBOD功能的使能情况 | on 或者 off |

例如使能 RAID 卡的硬盘直通功能，并设置 slot 7 硬盘为直通盘

```
storcli64 /c0 set jbod=on

storcli64 /c0/e252/s7 set JBOD
```

### 常用命令

查看阵列和磁盘状态

```bash
storcli /c0 show
```

其他查看信息

``` bash
storcli show             # 查询阵列卡信息
storcli /call show       # 查询所有阵列卡基本信息
storcli /call show all   # 查询所有阵列卡所有信息
storcli /c0 show all     # 查询 0 号控制器阵列信息
storcli /c0 /v0 show all # 查询 0 号控制器 0 号卷信息
storcli /call /eall /sall show all  # 查看所有硬盘的详细信息
storcli /c0/e0/s23 start locate     # 开启 /c0/e0/s23 的硬盘灯
storcli /c0/e0/s23 stop locate      # 关闭 /c0/e0/s23 的硬盘灯
```



创建阵列

```bash
storcli /c0 add vd r10 size=all drives=251:2-13 pdperarray=2 Strip=128 wb
```

参数解释：

- 在 c0 控制上（add vd）创建一个虚拟驱动器（阵列组）
- （r10） 阵列级别 10， （size=all）使用所有空间
- （drives=251:2-13） 使用 251 控制上的 Slot 2 到 13 槽位的磁盘
- （pdperarray=2 ） 每个阵列子组中的磁盘数量，创建 RAID10、RAID50、RAID60 时，需要设置此参数，创建其他级别的 RAID 组时，不需要设置此参数
- （Strip=128）设置 RAID 组条带大小，单位为 KB
- （wb）WriteBack wb：控制卡 Cache 收到所有的传输数据后，将给主机返回数据传输完成信号；wt：当硬盘子系统接收到所有传输数据后，控制卡将给主机返回数据传输完成信号

## 参考资料

- <https://www.cnblogs.com/luxf0/p/17630732.html>

- <https://www.cnblogs.com/zhangxinglong/p/9771967.html>