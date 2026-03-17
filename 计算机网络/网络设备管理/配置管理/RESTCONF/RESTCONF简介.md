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