## Netconf 简介

网络配置协议 NETCONF（Network Configuration Protocol）提供一套管理网络设备的机制，用户可以使用这套机制增加、修改、删除网络设备的配置，获取网络设备的配置和状态信息。通过 NETCONF 协议，网络设备可以提供规范的应用程序编程接口 API（Application Programming Interface），应用程序可以直接使用这些 API，向网络设备发送和获取配置

## Netconf 编程实现

### 可选框架

- Python ncclient
- Golang go-netconf <https://github.com/Juniper/go-netconf>

### NETCONF 配置

开启 ssh

```bash
# 生成本地密钥对 ecdsa
public-key local create ecdsa
public-key local create rsa  # 4096

# ssh-keygen -f ~/.ssh/known_hosts -R "192.168.71.201"
# update-crypto-policies --set LEGACY
# ssh -oHostKeyAlgorithms=+ssh-rsa -oPubkeyAcceptedAlgorithms=+ssh-rsa user@ip

# 开启 SSH 服务器功能
ssh server enable

# 查看服务
display ssh server status
```

开启 NETCONF over SSH

```bash
# 开启 neconf 服务（NETCONF over SHH）
netconf ssh server enable

# 设置 netconf 的服务端口为 830(缺省端口号为：830)
netconf ssh server port 830

# 设置超时时间为 5 分钟（缺省超时间为：0 永不超时，为了安全性，建议修改超时时间）
netconf agent idle-timeout 5
```

用户

```bash
# 额外创建用户
local-user h3c class manage
  # 设置密码
	password simple 'H3c@123'
  # 允许用户使用 http 服务
  service-type http
  # 允许用户使用 https 服务
  service-type https
  # 允许用户使用 ssh 服务
  service-type ssh
  authorization-attribute user-role network-admin

# 配置 SSH 用户 h3c 的服务为 netconf，认证类型为 password
ssh user h3c service-type all authentication-type password
ssh user h3c service-type netconf authentication-type password

# 配置 VTY 界面允许 SSH 登录
line vty 0 15
  # 配置 user-interface vty 的认证模式为 scheme
  authentication-mode scheme
  protocol inbound ssh
  quit
```

查看设备侧 netconf 的连接会话信息

```bash
[RouterH3C]display netconf session 
```

查看 netconf 的服务是否开启

```bash
[RouterH3C]display netconf service
NETCONF over SOAP over HTTP: Disabled (port 80)
NETCONF over SOAP over HTTPS: Disabled (port 832)
NETCONF over SSH: Enabled (port 830)
NETCONF over Telnet: Enabled
NETCONF over Console: Enabled
SOAP timeout: 10 minutes     Agent timeout: 5 minutes
Active Sessions: 0
Service statistics:
  NETCONF start time: 2026-03-16T04:28:53
  Output notifications: 0
  Output RPC errors: 0
  Dropped sessions: 0
  Sessions: 9
  Received bad hellos: 0
  Received RPCs: 17
  Received bad RPCs: 0
```

### NETCONF 快速入门

添加依赖（uv 创建一个 Python 项目这里不再展开）

```bash
uv add ncclient pyang xmltodict logbook lxml
```

封装一个 `log.py`

```python
import sys

from logbook import Logger, StreamHandler

StreamHandler(sys.stdout).push_application()
logging = Logger("H3C Router")

```

调用 log

```python
from h3c_router.log import logging
```

增加一个 `config.py`，需要按照实际的路由器进行配置，这里是 H3C RT-MSR-3620

```python
# NETCONF 连接参数
h3c_msr3620_router = {
    "host": "192.168.71.201",
    "username": "h3c",
    "password": "H3c@123",
    "port": 830,
    "device_params": {"name": "h3c"},
    "hostkey_verify": False,
    "look_for_keys": False,
}
```

采用 NETCONF over SHH 的会话方式

调用 config 的方式

```python
from ncclient import manager
from h3c_router.config import h3c_msr3620_router

with manager.connect(**h3c_msr3620_router) as netconf_connect:
    pass
```

### 会话测试

选用该接口来做会话测试

```python
import time

from ncclient import manager

from h3c_router.config import h3c_msr3620_router
from h3c_router.log import logging

with manager.connect(**h3c_msr3620_router) as netconf_connect:
    logging.info("Server Capabilities:")
    # 通过 server_capabilities 属性获取 server capabilities
    for server_capability in netconf_connect.server_capabilities:
        logging.info("\t" + server_capability)

    logging.info("client Capabilities:")
    # 通过 client_capabilities 属性获取 client capabilities
    for client_capability in netconf_connect.client_capabilities:
        logging.info("\t" + client_capability)

    # 休眠 20 后，关闭 netconf 连接
    time.sleep(20)

```

### GET 操作获取接口信息

以获取接口信息为例， RPC 报文如下：

```xml
<top xmlns="http://www.h3c.com/netconf/data:1.0">
    <Ifmgr>
        <Interfaces>
            <Interface>
                <IfIndex></IfIndex>
                <Name></Name>
                <InetAddressIPV4></InetAddressIPV4>
                <AdminStatus></AdminStatus>
                <OperStatus></OperStatus>
            </Interface>
        </Interfaces>
    </Ifmgr>
</top>
```

完整代码：

```python
import xml.etree.ElementTree as ET

import xmltodict
from lxml import etree
from lxml.builder import ElementMaker
from ncclient import manager

from h3c_router.config import h3c_msr3620_router
from h3c_router.log import logging

NS_NETCONF = "urn:ietf:params:xml:ns:netconf:base:1.0"
NS_H3C_DATA = "http://www.h3c.com/netconf/data:1.0"
H3C = ElementMaker(namespace=NS_NETCONF, nsmap={"ns0": NS_NETCONF, None: NS_H3C_DATA})


top = H3C.top(
    H3C.Ifmgr(
        H3C.Interfaces(
            H3C.Interface(
                H3C.IfIndex(""),
                H3C.Name(""),
                H3C.InetAddressIPV4(""),
                H3C.AdminStatus(""),
                H3C.OperStatus(""),
            ),
        )
    )
)

# 直接得到符合 NETCONF 标准的 XML 字符串
get_all_interface = etree.tostring(
    top,
    encoding="unicode",
    pretty_print=True,
)
logging.info(get_all_interface)

with manager.connect(**h3c_msr3620_router) as netconf_connect:
    result = netconf_connect.get(("subtree", get_all_interface))
    interfaces = result.data.findall(".//{http://www.h3c.com/netconf/data:1.0}Interface")
    for index in range(len(interfaces)):
        data = xmltodict.parse(ET.tostring(interfaces[index]))
        logging.info(data)

```

调用对应 NETCONF XML API 接口，发送 get 报文到设备端， 获取设备接口信息，构造出的 XML

```xml
<ns0:top xmlns:ns0="urn:ietf:params:xml:ns:netconf:base:1.0" xmlns="http://www.h3c.com/netconf/data:1.0">
  <ns0:Ifmgr>
    <ns0:Interfaces>
      <ns0:Interface>
        <ns0:IfIndex></ns0:IfIndex>
        <ns0:Name></ns0:Name>
        <ns0:InetAddressIPV4></ns0:InetAddressIPV4>
        <ns0:AdminStatus></ns0:AdminStatus>
        <ns0:OperStatus></ns0:OperStatus>
      </ns0:Interface>
    </ns0:Interfaces>
  </ns0:Ifmgr>
</ns0:top>
```

响应的 XML 信息用 xmltodict 将数据解析为字典形式

## EDIT-CONFIG 操作下发配置

构造 XML 使用下面的语句

```python
from lxml.builder import ElementMaker


NS_XC = "urn:ietf:params:xml:ns:netconf:base:1.0"
NS_H3C = "http://www.h3c.com/netconf/config:1.0"

E = ElementMaker(nsmap={"xc": NS_XC})
H3C = ElementMaker(namespace=NS_H3C)
```

### 创建 vlan 及 vlanif

构造 edit-config 操作的 RPC 请求报文， 本例为创建新的 vlan、vlanif 接口 ip、access 端口划分 vlan、及 trunk 端口放行 vlan

构造如下的报文

```xml
<config xmlns:xc="urn:ietf:params:xml:ns:netconf:base:1.0">
    <top xmlns="http://www.h3c.com/netconf/config:1.0">
        <VLAN xc:operation="create">
            <VLANs>
                <VLANID>
                    <ID>10</ID>
                    <Name>172.31.10.0</Name>
                    <Description>create_vlan_by_netconf</Description>
                    <Ipv4>
                        <Ipv4Address>172.31.10.254</Ipv4Address>
                        <Ipv4Mask>255.255.255.0</Ipv4Mask>
                    </Ipv4>
                </VLANID>
                <VLANID>
                    <ID>20</ID>
                    <Name>172.31.20.0</Name>
                    <Description>create_vlan_by_netconf</Description>
                    <Ipv4>
                        <Ipv4Address>172.31.20.254</Ipv4Address>
                        <Ipv4Mask>255.255.255.0</Ipv4Mask>
                    </Ipv4>
                </VLANID>
            </VLANs>
        </VLAN>
    </top>
</config>

```

使用代码进行构造

```python
def create_vlan_entry(v_id, name, desc, ip, mask):  # noqa: D103
    return H3C.VLANID(
        H3C.ID(str(v_id)),
        H3C.Name(name),
        H3C.Description(desc),
        H3C.Ipv4(
            H3C.Ipv4Address(ip),
            H3C.Ipv4Mask(mask),
        ),
    )


create_vlan_config = E.config(
    H3C.top(
        H3C.VLAN(
            {f"{{{NS_XC}}}operation": "create"},  # 对应 xc:operation="create"
            H3C.VLANs(
                create_vlan_entry(
                    10,
                    "172.31.10.0",
                    "create_vlan_by_netconf",
                    "172.31.10.254",
                    "255.255.255.0",
                ),
                create_vlan_entry(
                    20,
                    "172.31.20.0",
                    "create_vlan_by_netconf",
                    "172.31.20.254",
                    "255.255.255.0",
                ),
            ),
        )
    )
)

create_vlan_xml = etree.tostring(
    create_vlan_config,
    encoding="unicode",
    pretty_print=True,
)
```

### access 端口划分 vlan

构造 XML

```xml
<config xmlns:xc="urn:ietf:params:xml:ns:netconf:base:1.0">
    <top xmlns="http://www.h3c.com/netconf/config:1.0">
        <VLAN>
            <AccessInterfaces>
                <Interface>
                    <IfIndex>341</IfIndex>
                    <PVID>10</PVID>
                </Interface>
                <Interface>
                    <IfIndex>342</IfIndex>
                    <PVID>10</PVID>
                </Interface>
                <Interface>
                    <IfIndex>343</IfIndex>
                    <PVID>20</PVID>
                </Interface>
                <Interface>
                    <IfIndex>344</IfIndex>
                    <PVID>20</PVID>
                </Interface>
            </AccessInterfaces>
        </VLAN>
    </top>
</config>

```

代码为

```python
access_interfaces_config = E.config(
    H3C.top(
        H3C.VLAN(
            H3C.AccessInterfaces(
                H3C.Interface(
                    H3C.IfIndex("341"),
                    H3C.PVID("10"),
                ),
                H3C.Interface(
                    H3C.IfIndex("342"),
                    H3C.PVID("10"),
                ),
                H3C.Interface(
                    H3C.IfIndex("343"),
                    H3C.PVID("20"),
                ),
                H3C.Interface(
                    H3C.IfIndex("344"),
                    H3C.PVID("20"),
                ),
            ),
        ),
    ),
)

access_interfaces_xml = etree.tostring(
    access_interfaces_config,
    encoding="unicode",
    pretty_print=True,
)
logging.info(access_interfaces_xml)
```

### 设置 link-type 为 trunk

构造 XML

```xml
<config xmlns:xc="urn:ietf:params:xml:ns:netconf:base:1.0">
    <top xmlns="http://www.h3c.com/netconf/config:1.0">
        <Ifmgr>
            <Interfaces>
                <Interface>
                    <IfIndex>341</IfIndex>
                    <Description>up_link</Description>
                    <AdminStatus>1</AdminStatus>
                    <ConfigSpeed>32</ConfigSpeed>
                    <ConfigDuplex>1</ConfigDuplex>
                    <LinkType>2</LinkType>
                </Interface>
            </Interfaces>
        </Ifmgr>
    </top>
</config>

```

代码为

```python
link_type_config = E.config(
    H3C.top(
        H3C.Ifmgr(
            H3C.Interfaces(
                H3C.Interface(
                    H3C.IfIndex("341"),
                    H3C.Description("up_link"),
                    H3C.AdminStatus("1"),
                    H3C.ConfigSpeed("32"),
                    H3C.ConfigDuplex("1"),
                    H3C.LinkType("2"),
                ),
            ),
        ),
    ),
)

link_type_xml = etree.tostring(
    link_type_config,
    encoding="unicode",
    pretty_print=True,
)
logging.info(link_type_xml)
```

### trunk 口放行 vlan

RPC 报文为

```xml
<config xmlns:xc="urn:ietf:params:xml:ns:netconf:base:1.0">
    <top xmlns="http://www.h3c.com/netconf/config:1.0">
        <VLAN>
            <TrunkInterfaces>
                <Interface>
                    <IfIndex>7</IfIndex>
                    <PermitVlanList>10,20</PermitVlanList>
                </Interface>
            </TrunkInterfaces>
        </VLAN>
    </top>
</config>

```

代码为

```python
trunk_interfaces_config = E.config(
    H3C.top(
        H3C.VLAN(
            H3C.TrunkInterfaces(
                H3C.Interface(
                    H3C.IfIndex("341"),
                    H3C.PermitVlanList("10,20"),
                ),
            ),
        ),
    ),
)

trunk_interfaces_xml = etree.tostring(
    trunk_interfaces_config,
    encoding="unicode",
    pretty_print=True,
)
logging.info(trunk_interfaces_xml)
```

### 配置下发

核心代码

```python
with manager.connect(**h3c_msr3620_router) as netconf_connect:
    # for 循环遍历 xml 做配置下发
    for config_xml in [
        create_vlan_xml,
        access_interfaces_xml,
        link_type_xml,
        trunk_interfaces_xml,
    ]:
        rpc_obj = netconf_connect.edit_config(target="running", config=config_xml)
        logging.info(rpc_obj)

    # 保存配置
    netconf_connect.save("startup.cfg")

```

响应

```bash
[2026-03-17 02:56:26.172013] INFO: H3C Router: <?xml version="1.0" encoding="UTF-8"?><rpc-reply xmlns="urn:ietf:params:xml:ns:netconf:base:1.0" message-id="urn:uuid:2dbd5418-f34c-42b5-bab3-66d4116a2ae2"><ok/></rpc-reply>
```

### 其他操作

`operation`：`<config>`子树中的元素可以包含一个 “`operation`” 属性，它属于`NETCONF`名称空间。该属性标识配置中的要执行该操作的点，并可以在整个`<config>`子树中的多个元素上出现。如果未指定 “`operation`” 属性，则配置将合并到配置数据存储中。 “`operation`” 属性具有以下值之一：

- `merge`：由包含此属性的元素标识的配置数据与由`<target>`参数标识的配置数据存储中对应级别的配置合并。这是默认行为。
- `replace`：由包含此属性的元素标识的配置数据将替换由`<target>`参数标识的配置数据存储区中的任何相关配置。如果配置数据存储中不存在此类配置数据，则会创建它。与替换整个目标配置的`<copy-config>`操作不同，只有实际存在于`<config>`参数中的配置受到影响。
- `create`：当且仅当配置数据存在于配置数据存储中时，才将包含此属性的元素标识的配置数据添加到配置中。如果配置数据存在，则返回一个`<error-tag>`值为 “`data-exists`” 的`<rpc-error>`元素。
- `delete`：当且仅当配置数据当前存在于配置数据存储中时，才从配置中删除由包含此属性的元素标识的配置数据。如果配置数据不存在，则返回一个`<error-tag>`值为 “`data-missing`” 的`<rpc-error>`元素。
- `remove`：如果配置数据当前存在于配置数据存储中，则从配置中删除由包含此属性的元素标识的配置数据。如果配置数据不存在，服务器会自动忽略 “`remove`” 操作。

## 参考资料

- <https://info.support.huawei.com/info-finder/encyclopedia/zh/NETCONF.html>

- <https://cshihong.github.io/2019/12/29/Netconf%E5%8D%8F%E8%AE%AE%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0/>