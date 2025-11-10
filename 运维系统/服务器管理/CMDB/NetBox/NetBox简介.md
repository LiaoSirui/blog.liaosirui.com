## NetBox 简介

NetBox 是一个 IP 地址管理（IP address management，IPAM）和数据中心基础设施管理（data center infrastructure management，DCIM）工具， NetBox 为推动网络自动化提供了理想的“事实来源”

代码仓库：

- 代码仓库：<https://github.com/netbox-community/netbox>
- 镜像构建：<https://github.com/netbox-community/netbox-docker>

- 自动发现 Agent：<https://github.com/netboxlabs/orb-agent>
- 升级指引：<https://github.com/netbox-community/netbox-docker/wiki/Updating>

文档：

- Awesome NetBox：<https://github.com/netbox-community/awesome-netbox>

- 文档中心：<https://docs.netboxlabs.com/>
- 社区版文档：<https://netboxlabs.com/docs/netbox/en/stable/>

- 快速入门：<https://github.com/netbox-community/netbox-zero-to-hero>

- 官方提供的 Demo：<https://demo.netbox.dev/>（the demo instance can be accessed using the username `admin` and password `admin`）

## NetBox 插件

| 插件名称       | 插件功能                                                     | 源码地址                                                    |
| -------------- | ------------------------------------------------------------ | ----------------------------------------------------------- |
| netbox-qrcode  | 用于为对象生成二维码：机架、设备、线缆                       | <https://github.com/netbox-community/netbox-qrcode>         |
| Prometheus SD  | 旨在通过 HTTP Service Discovery（SD）方式，将 Netbox 中存储的设备信息、虚拟机、IP 地址和服务转换成 Prometheus 所理解的格式。这一整合使得基于 Netbox 管理的信息能够无缝对接至 Prometheus，大大简化了监控配置流程，提升了自动化水平 | <https://github.com/FlxPeters/netbox-plugin-prometheus-sd>  |
| Documents      |                                                              | <https://github.com/jasonyates/netbox-documents>            |
| Reorder Rack   |                                                              | <https://github.com/netbox-community/netbox-topology-views> |
| Topology views |                                                              | <https://github.com/netbox-community/netbox-reorder-rack>   |
| IP Calculator  | IP 地址计算器                                                | <https://github.com/PieterL75/netbox_ipcalculator>          |
| Access Lists   |                                                              | <https://github.com/netbox-community/netbox-acls>           |
| NextBox-UI     | 带有 topoSphere 的 NextBox-UI                                | <https://github.com/iDebugAll/nextbox-ui-plugin>            |
| inventory      | 库存插件                                                     | <https://github.com/ArnesSI/netbox-inventory>               |
|                |                                                              |                                                             |

## 其他

NetBox 设备类型库导入工具是专为 NetBox 用户设计的一个社区驱动的 Python 脚本，它简化了从 NetBox 社区设备类型库批量导入设备类型的流程。此工具检查重复项，并允许用户选择性地导入制造商的设备类型定义，无需手动在 NetBox 界面中逐一创建。请注意，尽管这个工具为 NetBox 用户提供便利，但它并非官方支持的产品

- <https://github.com/netbox-community/devicetype-library>
- <https://github.com/netbox-community/Device-Type-Library-Import>

## 参考资料

- <https://songxwn.com/NetBox-PLUGINS-QR-CN/>
- <https://songxwn.com/netbox4-CN/>
- <https://songxwn.com/NetBox-use1-dcim/>

- Netbox 使用 <https://zhuanlan.zhihu.com/p/656805361>
