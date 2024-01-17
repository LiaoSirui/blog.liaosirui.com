## 参数

| 参数名          | 说明                                                         | 取值样例 |
| :-------------- | :----------------------------------------------------------- | :------: |
| name            | 定义测试任务名称                                             |   N/A    |
| filename        | 测试对象，即待测试的磁盘设备名称                             |   N/A    |
| bs              | 每次请求的块大小。取值包括4k、8k 及 16k 等                   |    4k    |
| bsrange         | `bsrange=512-2048` 数据块的大小范围                          |   N/A    |
| size            | I/O 测试的寻址空间。也可是百分数，比如size=20%，表示读/写的数据量占该设备总文件的20%的空间 |  100GB   |
| ioengine        | I/O 引擎。推荐使用 Linux 的异步 I/O 引擎                     |  libaio  |
| iodepth         | 请求的 I/O 队列深度。此处定义的队列深度是指每个线程的队列深度，如果有多个线程测试，意味着每个线程都是此处定义的队列深度。fio 总的 I/O 并发数 = iodepth * numjobs |    1     |
| numjobs         | 定义测试的并发线程数                                         |    1     |
| direct          | 定义是否使用direct I/O，可选值如下：值为0，表示使用buffered I/O值为1，表示使用direct I/O |    1     |
| rw              | 读写模式。取值包括顺序读（read）、顺序写（write）、随机读（randread）、随机写（randwrite）、混合随机读写（randrw）和混合顺序读写（rw，readwrite） |   read   |
| rwmixwrite      | rwmixwrite=30 在混合读写的模式下，写占30%                    |          |
| time_based      | 指定采用时间模式。无需设置该参数值，只要 FIO 基于时间来运行  |   N/A    |
| runtime         | 指定测试时长，即 FIO 运行时长                                |   600    |
| refill_buffers  | FIO 将在每次提交时重新填充 I/O 缓冲区。默认设置是仅在初始时填充并重用该数据 |   N/A    |
| norandommap     | 在进行随机 I/O 时，FIO 将覆盖文件的每个块。若给出此参数，则将选择新的偏移量而不查看 I/O 历史记录 |   N/A    |
| randrepeat      | 随机序列是否可重复，True（1）表示随机序列可重复，False（0）表示随机序列不可重复。默认为 True（1） |    0     |
| group_reporting | 多个 job 并发时，打印整个 group 的统计值                     |   N/A    |

## 示例

测试命令

```bash
#!/usr/bin/env bash
#
 
# 4k 顺序读
fio -directory=/data/input -direct=1 -iodepth 1 -thread -rw=read -ioengine=psync -bs=4k -size=200G -numjobs=10 -runtime=1000 -group_reporting -name=fiotest -output=sqe_100read_4k
  
# 4k 顺序写
fio -directory=/data/input -direct=1 -iodepth 1 -thread -rw=write -ioengine=psync -bs=4k -size=200G -numjobs=10 -runtime=1000 -group_reporting -name=fiotest -output=sqe_100write_4k
  
# 4k 顺序混合读写
fio -directory=/data/input -direct=1 -iodepth 1 -thread -rw=rw -rwmixread=70 -ioengine=psync -bs=4k -size=200G -numjobs=10 -runtime=1000 -group_reporting -name=fiotest -output=sqe_70read_4k
 
# 1024k 顺序读
fio -directory=/data/input -direct=1 -iodepth 1 -thread -rw=read -ioengine=psync -bs=1024k -size=200G -numjobs=10 -runtime=1000 -group_reporting -name=fiotest -output=sqe_100read_1024k
  
# 1024k 顺序写
fio -directory=/data/input -direct=1 -iodepth 1 -thread -rw=write -ioengine=psync -bs=1024k -size=200G -numjobs=10 -runtime=1000 -group_reporting -name=fiotest -output=sqe_100write_1024k
  
# 1024k 混合读写
fio -directory=/data/input -direct=1 -iodepth 1 -thread -rw=rw -rwmixread=70 -ioengine=psync -bs=1024k -size=200G -numjobs=10 -runtime=1000 -group_reporting -name=fiotest -output=sqe_70read_1024k
 
# 4k 顺序读 128 iodepth
fio -directory=/data/input -direct=1 -iodepth 128 -thread -rw=read -ioengine=psync -bs=4k -size=200G -numjobs=10 -runtime=1000 -group_reporting -name=fiotest -output=sqe_100read_4k_128depth
  
# 4k 顺序写 128 iodepth
fio -directory=/data/input -direct=1 -iodepth 128 -thread -rw=write -ioengine=psync -bs=4k -size=200G -numjobs=10 -runtime=1000 -group_reporting -name=fiotest -output=sqe_100write_4k_128depth
  
# 4k 混合读写 128 iodepth
fio -directory=/data/input -direct=1 -iodepth 128 -thread -rw=rw -rwmixread=70 -ioengine=psync -bs=4k -size=200G -numjobs=10 -runtime=1000 -group_reporting -name=fiotest -output=sqe_70read_4k_128depth
 
# 1024k 顺序读 128 iodepth
fio -directory=/data/input -direct=1 -iodepth 128 -thread -rw=read -ioengine=psync -bs=1024k -size=200G -numjobs=10 -runtime=1000 -group_reporting -name=fiotest -output=sqe_100read_1024k_128depth
  
# 1024k 顺序写 128 iodepth
fio -directory=/data/input -direct=1 -iodepth 128 -thread -rw=write -ioengine=psync -bs=1024k -size=200G -numjobs=10 -runtime=1000 -group_reporting -name=fiotest -output=sqe_100write_1024k_128depth
  
# 1024k 混合读写 128 iodepth
fio -directory=/data/input -direct=1 -iodepth 128 -thread -rw=rw -rwmixread=70 -ioengine=psync -bs=1024k -size=200G -numjobs=10 -runtime=1000 -group_reporting -name=fiotest -output=sqe_70read_1024k_128depth
 
# 4k 随机读
fio -directory=/data/input -direct=1 -iodepth 1 -thread -rw=randread -ioengine=psync -bs=4k -size=200G -numjobs=10 -runtime=1000 -group_reporting -name=fiotest -output=rand_100read_4k
  
# 4k 随机写
fio -directory=/data/input -direct=1 -iodepth 1 -thread -rw=randwrite -ioengine=psync -bs=4k -size=200G -numjobs=10 -runtime=1000 -group_reporting -name=fiotest -output=rand_100write_4k
  
# 4k 混合随机读写
fio -directory=/data/input -direct=1 -iodepth 1 -thread -rw=randrw -rwmixread=70 -ioengine=psync -bs=4k -size=200G -numjobs=10 -runtime=100 -group_reporting -name=fiotest -output=randrw_70read_4k
 
#1024k 随机读
fio -directory=/data/input -direct=1 -iodepth 1 -thread -rw=randread -ioengine=psync -bs=1024k -size=200G -numjobs=10 -runtime=1000 -group_reporting -name=fiotest -output=rand_100read_1024k
  
#1024k 随机写
fio -directory=/data/input -direct=1 -iodepth 1 -thread -rw=randwrite -ioengine=psync -bs=1024k -size=200G -numjobs=10 -runtime=1000 -group_reporting -name=fiotest -output=rand_100write_1024k
  
#1024k 混合随机读写
fio -directory=/data/input -direct=1 -iodepth 1 -thread -rw=randrw -rwmixread=70 -ioengine=psync -bs=1024k -size=200G -numjobs=10 -runtime=100 -group_reporting -name=fiotest -output=randrw_70read_1024k
 
#4k 随机读 128 oidepth
fio -directory=/data/input -direct=1 -iodepth 128 -thread -rw=randread -ioengine=psync -bs=4k -size=200G -numjobs=10 -runtime=1000 -group_reporting -name=fiotest -output=rand_100read_4k_128depth
  
#4k 随机写 128 oidepth
fio -directory=/data/input -direct=1 -iodepth 128 -thread -rw=randwrite -ioengine=psync -bs=4k -size=200G -numjobs=10 -runtime=1000 -group_reporting -name=fiotest -output=rand_100write_4k_128depth
  
#4k 混合随机读写 128 oidepth
fio -directory=/data/input -direct=1 -iodepth 128 -thread -rw=randrw -rwmixread=70 -ioengine=psync -bs=4k -size=200G -numjobs=10 -runtime=100 -group_reporting -name=fiotest -output=randrw_70read_4k_128depth
 
#1024k 随机读 128 oidepth
fio -directory=/data/input -direct=1 -iodepth 128 -thread -rw=randread -ioengine=psync -bs=1024k -size=200G -numjobs=10 -runtime=1000 -group_reporting -name=fiotest -output=rand_100read_1024k_128depth
  
#1024k 随机写 128 oidepth
fio -directory=/data/input -direct=1 -iodepth 128 -thread -rw=randwrite -ioengine=psync -bs=1024k -size=200G -numjobs=10 -runtime=1000 -group_reporting -name=fiotest -output=rand_100write_1024k_128depth
  
#1024k 混合随机读写 128 oidepth
fio -directory=/data/input -direct=1 -iodepth 128 -thread -rw=randrw -rwmixread=70 -ioengine=psync -bs=1024k -size=200G -numjobs=10 -runtime=100 -group_reporting -name=fiotest -output=randrw_70read_1024k_128depth
```



顺序读测试 (任务数：1):

```bash
fio --name=sequential-read --directory=${TEST_DIR} --rw=read --refill_buffers --bs=4M --size=4G
```

顺序写测试 (任务数：1):

```bash
fio --name=sequential-write --directory=${TEST_DIR} --rw=write --refill_buffers --bs=4M --size=4G --end_fsync=1
```

顺序读测试 (任务数：16):

```bash
fio --name=big-file-multi-read --directory=${TEST_DIR} --rw=read --refill_buffers --bs=4M --size=4G --numjobs=16
```

顺序写测试 (任务数：16):

```bash
fio --name=big-file-multi-write --directory=${TEST_DIR} --rw=write --refill_buffers --bs=4M --size=4G --numjobs=16 --end_fsync=1
```

## 参考文档

- <https://www.cnblogs.com/hiyang/p/12764088.html>
- <https://cloud.tencent.com/document/product/362/6741>