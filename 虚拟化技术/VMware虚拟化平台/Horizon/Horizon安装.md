## 前置准备

兼容性查询：

- 硬件要求 <https://docs.vmware.com/cn/VMware-Horizon/2312/horizon-installation/GUID-332CFB83-784A-4578-9354-888C0538909A.html>

建议 4Core/16Gi

- 操作系统 <https://kb.vmware.com/s/article/78652>

| **Operating System**   | **Supported Editions** | **Supported Horizon versions**                         |
| :--------------------- | :--------------------- | :----------------------------------------------------- |
| Windows Server 2012 R2 | Standard Datacenter    | Horizon 8 2006 - 2309.Not supported from 2309 onwards. |
| Windows Server 2016    | Standard Datacenter    | Horizon 8 2006 and later                               |
| Windows Server 2019    | Standard Datacenter    | Horizon 8 2006 and later                               |
| Windows Server 2022    | Standard Datacenter    | Horizon 8 2111 and later                               |

安装前准备：

- Horizon 安装需要提前加入 AD 域

- 修改计算机名（不超过 15 字符）
- 设置静态 IP

## 开始安装 Horizon

选择标准服务器

![image-20240801090046296](./.assets/Horizon安装/image-20240801090046296.png)

不要加入客户提升计划（纯内网部署）

## 配置 Horizon