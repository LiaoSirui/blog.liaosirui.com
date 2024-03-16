Mellanox 固件工具(MFT)包是一组固件管理工具

MFT 固件下载地址：<https://network.nvidia.com/products/adapter-software/firmware-tools/>

通过命令可以查看 esxi 主机上的网卡

```bash
esxcli network nic list
```

安装 mft 工具

```bash
esxcli software vib install -v /tmp/nmst-4.17.0.106-1OEM.650.0.0.4598673.x86_64.vib

esxcli software vib install -v /tmp/mft-4.17.0.106-10EM-650.0.0.4598673.x86_64.vib
```

如果安装过程中遇到认证签名问题，在末尾添加 `–no-sig-check` 参数

开启 mst driver

```bash
cd /opt/mellanox/bin

./mst start

./mst status
```

