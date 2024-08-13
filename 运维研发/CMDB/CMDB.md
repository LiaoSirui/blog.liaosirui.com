## CMDB 简介

CMDB 平台又叫 IT 资产配置管理中心，是运维过程中对物理资源、虚拟资源、标签、物理位置等进行统一管理，为监控、自动化等场景提供可靠的资源对象和数据支持。

CMDB 提供手动录入功能并可批量录入，将资源信息进行标准化处理和整合，准确地维护资源信息及资源间的关联关系，并记录资源信息的变化过程及实时生命状态。遵循灵活、可扩展、开放性的原则，平台预置部分资源模型，支持自定义资源模型，开放数据字典的设计和编排能力给用户，并对外提供 API 接口，为其他平台提供基础数据。

当前 CMDB 提供的主要服务包括：

- 支持计算、存储、网络设备等物理资源基础设施的管理，实时抓取服务器状态，跟踪资源全生命周期。

- 支持模型管理，支持用户自定义模型扩展。

- 为告警平台、资源编排纳管、配置管理提供基础数据。

- 支持机房机柜全生命周期管理。

- 拉通监控、流程、智能分析平台数据，实现运维数据一体化消费场景，提高运维效率。

可参考项目：

- NetBox <https://github.com/netbox-community/netbox>

- iTop <https://github.com/Combodo/iTop>

- 蓝鲸智云配置平台(BlueKing CMDB) <https://github.com/TencentBlueKing/bk-cmdb>

```bash
docker run -d -p 8090:8090 ccr.ccs.tencentyun.com/bk.io/cmdb-standalone:v3.13.7

user: admin
pass: admin
```

- CMDB: configuration and management of IT resources | 运维的权威数据库 <https://github.com/veops/cmdb>

- WeCMDB（Configuration Management Database 配置管理数据库），是源自微众银行运维管理实践的的一套配置管理数据库系统：<https://github.com/WeBankPartners/we-cmdb>

```bash
docker run -d -p 8096:8096 wecmdb:{{version}}

user: super_admin
pass: Abcd1234
```
