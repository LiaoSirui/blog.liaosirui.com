## Netconf 简介

网络配置协议 NETCONF（Network Configuration Protocol）提供一套管理网络设备的机制，用户可以使用这套机制增加、修改、删除网络设备的配置，获取网络设备的配置和状态信息。通过 NETCONF 协议，网络设备可以提供规范的应用程序编程接口 API（Application Programming Interface），应用程序可以直接使用这些 API，向网络设备发送和获取配置

## Netconf 编程实现

### 可选框架

- Python ncclient
- Golang go-netconf <https://github.com/Juniper/go-netconf>

### NETCONF 配置

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
uv add ncclient pyang xmltodict logbook
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



## 参考资料

- <https://info.support.huawei.com/info-finder/encyclopedia/zh/NETCONF.html>

- <https://cshihong.github.io/2019/12/29/Netconf%E5%8D%8F%E8%AE%AE%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0/>