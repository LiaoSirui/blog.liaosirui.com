NUMA（Non-Uniform Memory Access，非一致性内存访问）绑核工具，主要为了防止 CPU 资源争抢引发性能降低的问题

`numactl` 通过将 `CPU` 划分多个 `node` 减少 `CPU` 对总线资源的竞争，一般使用在高配置服务器部署多个 `CPU` 消耗性服务使用