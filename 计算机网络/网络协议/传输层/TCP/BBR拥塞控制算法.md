## BBR 简介

BBR (Bottleneck Bandwidth and Round-trip propagation time)是 Google 在 2016 年发布的一套拥塞控制算法。它尤其适合在存在一定丢包率的弱网环境下使用，在这类环境下，BBR 的性能远超 CUBIC 等传统的拥塞控制算法

BBRv2 是一种基于模型的拥塞控制算法，旨在降低队列、低损耗和（有界的）Reno/CUBIC 共存。维护一个模型网络路径，它使用带宽和 RTT 的测量值，以及（如果发生）数据包丢失和/或 DCTCP/L4S 样式的 ECN 信号

BBR2 比 BBR 更 "公平"，在有延迟和丢包的情况下，它的速度会远慢于 BBR，有时比默认的 CUBIC 还慢

## 参考资料

- <https://luckymrwang.github.io/2022/10/09/BBR%E6%8B%A5%E5%A1%9E%E6%8E%A7%E5%88%B6%E7%AE%97%E6%B3%95/>

- <https://cloud.tencent.com/developer/article/1482633>

- <https://blog.csdn.net/alex_yangchuansheng/article/details/122314660>
- <https://kaimingwan.com/2022/09/22/ffgp8o/>

- <https://queue.acm.org/detail.cfm?id=3022184>

- <https://github.com/0voice/cpp_backend_awsome_blog/blob/main/%E3%80%90NO.519%E3%80%91TCP%20BBR%E6%8B%A5%E5%A1%9E%E6%8E%A7%E5%88%B6%E7%AE%97%E6%B3%95%E6%B7%B1%E5%BA%A6%E8%A7%A3%E6%9E%90.md>