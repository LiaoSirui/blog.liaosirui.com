官方文档：<https://doc.beegfs.io/7.3.2/advanced_topics/rdma_support.html>

最新版：<https://doc.beegfs.io/latest/advanced_topics/rdma_support.html>

```bash
#支持Infiniband RDMA功能，必须在元数据和存储节点安装
dnf install -y libbeegfs-ib
```

RDMA 调优

配置文件 `/etc/modprobe.d/mlx4_core.conf`

EDR 建议：

- `connRDMABufNum = 22`
- `connRDMABufSize = 32768`
