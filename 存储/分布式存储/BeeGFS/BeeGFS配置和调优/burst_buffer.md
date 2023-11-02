beegfs 当中的一项 burst buffer 技术，发布于 2015 年 3 月。目的是利用计算节点上的 SSD 能力，加速 IO 访问能力，为云计算场景提供更好的存储能力。

### burst buffer 技术

burst buffer 是超算领域内的一个概念（类似于 cache tire），burst buffer 是后端存储和前端计算之间的夹心层。旨在利用计算节点上的存储能力，通常是 SSD 或者 NVME 等设备，在 IO 时提供比后端存储更大的带宽，从而避免后端存储过度负载。burst buffer 的出现主要来自超算场景中，计算和存储两个阶段存在明显的分割，当计算结束之后，数据需要写入存储。如果存储速度不理想，则下一轮计算将会受到影响。

使用 burst buffer IO 路径更短，加速存储的响应能力。此外，burst buffer 缓存的数据会异步的刷入到后端存储，这个过程可以控制，可以利用这一点提高向后端进行存储效率，如将小 IO 合并成较大的 IO。

burst buffer 存在两种架构一种是 node-local，另外一种是 remote shared

- node-local 顾名思义即使用本地的存储，其性能总体性能随计算节点的增加而线性增长
- Remote shared 则需要通过网络使用共享的存储设备

## Beeond

回到 beeond，它带来的便利有：和其他业务的隔离，更好的 IOPS、带宽、更低的延迟，充分利用已有的节点的存储能力。beeond 实际上并不关注后端的存储一定是 beegfs。

beeond 的设计思路采用 remote shared 模式，计算节点启动一个 beegfs 的实例。其中 nodefile 中记录了实例相关的配置。实例通过 start 和 stop 命令快速的启动和停止。通过内置的 beeond-cp 将文件系统实例中的数据存入 / 读出（stageout/stagein）后端的持久化存储（其他如 rsync 也可以完成类似的工作），其并发在指定的多个节点上同时执行。beeond-cp 使用的是 GNU parallel 组件，该组件可以并行执行任务。 

![img](.assets/3841733-8fb3f584cb00a2cd.png)

beeond-copy 提供并行拷贝的能力，最大速度在 29 小时内传输了 1PB 的数据。 

官方文档：

- <https://git.beegfs.io/pub/v7/tree/master/beeond>
- <https://www.beegfs.io/docs/PressReleaseBurstBufferWorldRecord.pdf>
