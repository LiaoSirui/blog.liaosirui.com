## 数据模型

数据模型的作用是用来描述一组具有统一标准的数据，并用明确的参数和模型来将数据的呈现标准化、规范化。举个例子，不同厂商之间对一些行业术语的规范及具体参数存在较大差异，比如用来区分路由协议优先级，在思科这边被称作管理距离（Administrative Distance）的东西到了 Juniper 那边被改叫做 Route Preference，并且它们分配给各个路由协议的 AD 和 RP 值也不一样，比如 RIP 在思科的 AD 为 120，在 Juniper 的 RP 为 100， 又比如 OSPF 在思科的 AD 为 110，而在 Juniper 这边 OSPF 还被分为 OSPF Interal（RP 值为 10），OSPF External（RP 值为 150）。虽然不同厂商之间对某些技术标准存在这样那样的差异，但是对于绝大部分技术它们还是遵守统一标准的，比如 VLAN。

用来描述 VLAN 的数据无外乎如下几点：

1. VLAN ID （1-4096 的整数，rw 类型）
2. VLAN Name （用字符串代表的 VLAN 名称，rw 类型）
3. VLAN State （用枚举表示的 down/up 或 shutdown/no shutdown 表示的 VLAN 状态，ro 类型）

可以看到类似于这种明确定义了数据内容及其数据类型和范围，以及 rw、ro 类型的一套模型，就被叫做数据模型。

## YANG

YANG 是一种 “以网络为中心的数据模型语言”（Network-centric data modeling language），由 IETF 于 2010 年 10 月（也就是 NETCONF 终稿发布之前的一年）在 RFC 6020 中被提出，其诞生之初的目的很明确， 是专门为 NETCONF 量身打造的建模语言，不过现在也被 REST 和其他协议所采用

### YANG 模型（Model）

YANG 的模型分为标准（Open 或者 Standard）和私有（Native）两种类型，其中标准类型中比较著名的有 IETF, IEEE, OpenConfig 等国际知名组织制定的模型（IETF 制定的 YANG 模型最常见）。除标准 YANG 模型之外，各家厂商又根据自家产品的不同设计了私有的 YANG 模型，比如思科、Juniper、华为、Fujitsu、诺基亚等都有自家的 YANG 模型。

其中思科的 YANG 模型又分为 Cisco Common 和 Cisco Platform Specific，其中前者为思科所有 OS（IOS - XE, IOS - XR, NX - OS）通用的 YANG 模型，后者为一些 OS 上独占的 YANG 模型。

### YANG 模块（Module）

模块（Module）是 YANG 定义的基本单位，一个模块可以用来定义一个单一的数据类型，也可以增加一个现有的数据模型和其他节点：

下面是一个叫做 ietf-interfaces，由 IETF 制定，用来描述设备端口参数的 YANG 模块：

<https://github.com/YangModels/yang/blob/main/standard/ietf/RFC/ietf-interfaces%402018-02-20.yang>

```YANG
module ietf-interfaces {
  yang-version 1.1;
  namespace "urn:ietf:params:xml:ns:yang:ietf-interfaces";
  prefix if;

  import ietf-yang-types {
    prefix yang;
  }

...
```

## 获取 YANG 模块

在 Github <https://github.com/YangModels/yang> 上存放着大部分标准（standard）和私有（vendor）的 YANG 模型，截止 2020 年 9 月，标准模型中包含 IETF，IEEE，ETSI 等国际知名组织和协会制定的 YANG 模块，私有模型中包含思科，Juniper，华为，诺基亚，富士通在内的厂商自己制定的 YANG 模块。

```bash
git clone https://github.com/YangModels/yang.git
```

## pyang

Pyang 是 Python 专为 YANG 开发的一个开源模块，主要功能：

- 用来验证 YANG 模块代码的准确性
- 将 YANG 模块转换成其他格式（比如树形格式）
- 从 YANG 模块中生成代码

以树形格式（Tree View Format）展开 ietf-interfaces 模块，可以用 pyang 这个 Python 模块来以树形格式的形式查看一个 YANG 模块的具体结构。

```bash
pyang -f tree libs/yang/standard/ietf/RFC/ietf-interfaces.yang
```

输出

```bash
pyang -f tree libs/yang/standard/ietf/RFC/ietf-interfaces.yang
module: ietf-interfaces
  +--rw interfaces
  |  +--rw interface* [name]
  |     +--rw name                        string
  |     +--rw description?                string
  |     +--rw type                        identityref
  |     +--rw enabled?                    boolean
  |     +--rw link-up-down-trap-enable?   enumeration {if-mib}?
  |     +--ro admin-status                enumeration {if-mib}?
  |     +--ro oper-status                 enumeration
  |     +--ro last-change?                yang:date-and-time
  |     +--ro if-index                    int32 {if-mib}?
  |     +--ro phys-address?               yang:phys-address
  |     +--ro higher-layer-if*            interface-ref
  |     +--ro lower-layer-if*             interface-ref
  |     +--ro speed?                      yang:gauge64
  |     +--ro statistics
  |        +--ro discontinuity-time    yang:date-and-time
# ...
```

