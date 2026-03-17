## RESTCONF 简介

RestConf 中 URI 的标准格式如下：

```bash
https://<ADDRESS>/<ROOT>/data/<[YANG_MODULE:]CONTAINER>/<LEAF>[?<OPTIONS>]
```

- ADDRESS 为设备（路由器、交换机）的 IP 地址。
- ROOT 是所有 RestConf 请求的入口，在接入任何 RestConf 服务器之前必须指定 ROOT。根据 RFC 8010 的定义，所有 RestConf 服务器必须启用一个叫做 `/.well-known/host-meta` 的资源用以开启 ROOT。
- data，顾名思义是 RestConf API 中用来指定数据（data）的资源类型（resource type），用以 RPC 协议的运行。
- `[YANG_MODULE:] CONTAINER`，其中 YANG_MODULE（可选）为 YANG 模型，CONTAINER 为使用的基础模式容器。
- `LEAF` 则为 YANG 模型里的分支元素，比如 hostname，version，interface, vlan 等等。
- 最后 `[?<OPTIONS>]` 则是可选的参数来对 HTTP 响应的内容做各种额外的过滤处理（不是所有厂商的设备都支持）

`RESTCONF`操作如何与`NETCONF`协议操作对比

| RESTCONF | NETCONF                                                 |
| :------- | :------------------------------------------------------ |
| OPTIONS  | none                                                    |
| HEAD     | `<get-config>`, `<get>`                                 |
| GET      | `<get-config>`, `<get>`                                 |
| POST     | `<edit-config>` (nc:operation="create")                 |
| POST     | invoke an RPC operation                                 |
| PUT      | `<copy-config>` (PUT on datastore)                      |
| PUT      | `<edit-config>` (nc:operation="create/replace")         |
| PATCH    | `<edit-config>` (nc:operation depends on PATCH content) |
| DELETE   | `<edit-config>` (nc:operation="delete")                 |

## 开启 RESTCONF

开启过程

```bash
system-view
  restful http port [port-number]
  restful http enable
  local-user user-name [ class manage ]
    password [ { hash | simple } password ]
    authorization-attribute user-role [user-role]
    service-type http
    quit
  restful https ssl-server-policy [policy-name]
  restful https port [port-number]
  restful https enable
  local-user user-name [ class manage ]
    password [ { hash | simple } password ]
    authorization-attribute user-role [user-role]
    service-type https
    quit
```

简单验证

```bash
# 获取 YANG 模块列表 (验证 RESTCONF 入口)
curl -k -u admin:password https://<设备IP>/restconf/data/ietf-yang-library:modules-state

# 或者获取设备信息
curl -k -u admin:password https://<设备IP>/restconf/data/h3c-system:system/state
```

## 根资源发现

`RESTCONF`使部署能够指定`RESTCONF API`的位置。当第一次连接到`RESTCONF`服务器时，`RESTCONF`客户端必须确定`RESTCONF API`的根。必须正好有一个由设备返回的 “`restconf`” 链接关系。



```bash
GET /.well-known/host-meta HTTP/1.1
Host: example.com
Accept: application/yang-data+json
```

## H3C RESTful

- <https://www.h3c.com/cn/d_202109/1465787_30005_0.htm>

- <https://www.h3c.com/cn/Service/Document_Software/Document_Center/Home/Wlan/00-Public/Developer_Guides/Development_Guide/H3C_RESTful-28619/>

## 参考资料

- <https://aristanetworks.github.io/openmgmt/examples/restconf/python/>

- <https://nxos-devops-lab.ciscolive.com/lab/pod10/yang/restconf-python>

- <https://zhuanlan.zhihu.com/p/484179889>