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

### CS 标准服务器

选择标准服务器，IPV4。后期做 HA 高可用可以安装副本服务器

![image-20240801090046296](./.assets/Horizon安装/image-20240801090046296.png)

依次执行：

- 输入用于恢复的密码和提示
- 自动配置防火墙
- 默认使用授权用户
- 不要加入客户提升计划（纯内网部署）

安装完成后在桌面上会有 Connection 的图标，双击图标运行。最好使用 Edge 或者 Chrome 浏览器。然后添加许可证

在服务器登录后台，修改安全登录网址

![Horizon Connection Server 访问提示登录失败](./.assets/Horizon安装/Pasted-78-20240805151212650.png)

在左侧设置中找到服务器，然后在 vCenter Server 添加；输入 VCenter 的地址登录用户名和密码

### 部署副本 CS 节点

同标准 CS 服务器一样，直接运行安装程序，按照向导提示进行配置

第二台 CS 节点类型为“Horizon 副本服务器”

填写主 CS 节点的完整域名

其他配置保持默认即可。副本服务器创建完后，也需要进行证书替换，方法与主 CS 一致

## 配置 Horizon

### 替换证书

CS 部署完成后默认使用自签名证书，一般建议部署 CA 签发一个证书

将导出后的 pfx 文件上传到 CS 服务器，运行 certlm.msc

选择“个人>证书”，导入新证书

![img](./.assets/Horizon安装/16150708_62d2639c8cc2295745.png)

### 配置事件数据库

Horizon 8 支持使用 PostgreSQL 存放事件



## 参考文档

- <https://blog.51cto.com/sparkgo/5478576>