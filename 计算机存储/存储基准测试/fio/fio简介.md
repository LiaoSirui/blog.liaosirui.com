## 参数

| **参数**        | **说明**                                                     |
| --------------- | ------------------------------------------------------------ |
| direct          | 表示是否使用direct I/O。默认值：1。值为1：表示使用direct I/O，忽略I/O缓存，数据直写。值为0：表示不使用direct I/O。 |
| iodepth         | 表示测试时的IO队列深度。例如`-iodepth=128`表示FIO控制请求中的I/O最大个数为128。 |
| rw              | 表示测试时的读写策略。您可以设置为：**randwrite**：随机写。**randread**：随机读。**read**：顺序读。**write**：顺序写。**randrw**：混合随机读写。 |
| ioengine        | 表示测试时FIO选择哪种I/O引擎，通常选择libaio，更符合日常应用模式，更多的选择请查阅FIO官方文档。 |
| bs              | 表示I/O单元的块大小（block size）。默认值：4 KiB。读取和写入的值可以以read、write格式单独指定，其中任何一个都可以为空以将该值保留为其默认值。 |
| size            | 表示测试文件大小。FIO会将指定的文件大小全部读/写完成，然后才停止测试，除非受到其他选项（例如运行时）的限制。如果未指定该参数，FIO将使用给定文件或设备的完整大小。也可以将大小作为1到100之间的百分比给出。例如指定size=20%，FIO将使用给定文件或设备完整大小的20%空间。 |
| numjobs         | 表示测试的并发线程数。默认值：1。                            |
| runtime         | 表示测试时间，即FIO运行时长。如果未指定该参数，则FIO会持续将上述**size**指定大小的文件，以每次**bs**值为块大小读/写完。 |
| group_reporting | 表示测试结果显示模式。如果指定该参数，测试结果会汇总每个进程的统计信息，而不是以不同任务来统计信息。 |
| filename        | 表示待测试的对象路径，路径可以是云盘设备名称或者一个文件地址。本文中的FIO测试全部是以整盘为测试对象，不含文件系统，即裸盘测试。同时为了避免误测试到其他盘导致数据被破坏，本示例地址为/dev/your_device，请您正确替换。 |
| name            | 表示测试任务名称，可以随意设定。例如本示例的Rand_Write_Testing。 |

## 示例

安装 libaio

```bash
dnf install -y libaio libaio-devel
```

测试命令

```bash
#!/usr/bin/env bash

set -e

export FIO_TEST_CMD=(
    "fio"
    "-direct=1"
    "-ioengine=libaio"
    "-group_reporting"
    "-name=fiotest"
    "-directory=/data/input"
    "-size=1G"
    "-runtime=1000"
    "-time_based=1"
)

# 随机写 IOPS
"${FIO_TEST_CMD[@]}" \
    -iodepth=128 -numjobs=1 \
    -bs=4k -rw=randwrite \
    -output=Rand_Write_Testing

# 随机读 IOPS
"${FIO_TEST_CMD[@]}" \
    -iodepth=128 -numjobs=1 \
    -bs=4k -rw=randread \
    -output=Rand_Read_Testing

# 顺序写吞吐量
"${FIO_TEST_CMD[@]}" \
    -iodepth=64 -numjobs=1 \
    -bs=1024k -rw=write \
    -output=Write_PPS_Testing

# 顺序读吞吐量
"${FIO_TEST_CMD[@]}" \
    -iodepth=64 -numjobs=1 \
    -bs=1024k -rw=read \
    -output=Read_PPS_Testing

# 随机写时延
"${FIO_TEST_CMD[@]}" \
    -iodepth=1 -numjobs=1 \
    -bs=4k -rw=randwrite \
    -output=Rand_Write_Latency_Testing

# 随机读时延
"${FIO_TEST_CMD[@]}" \
    -iodepth=1 -numjobs=1 \
    -bs=4k -rw=randread \
    -output=Rand_Read_Latency_Testing

```

## 参考文档

- <https://www.cnblogs.com/hiyang/p/12764088.html>
- <https://cloud.tencent.com/document/product/362/6741>