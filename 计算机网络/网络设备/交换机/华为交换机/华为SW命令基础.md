## 命令视图 

![img](./.assets/华为SW命令基础/20171207094721990.png)

![img](./.assets/华为SW命令基础/20171207094302474.png)

用户视图：

- `<HUAWEI>` 查看交换机简单的运行状态和统计信息
- 建立连接就能进入
- `quit` 断开与交换机的连接

系统视图：

- `[HUAWEI]` 配置系统参数
- 在用户视图下输入 `system-view`
- `quit` 返回用户视图

以太网端口视图：

- `[HUAWEI-Ethernet0/0/1]`配置以太网端口
- 系统视图下键入 `interface ethernet0/0/1`
- `quit`返回用户视图

NULL 接口视图：

- `[HUAWEI-NULL0]` 配置 NULL 接口视图参数（转发到 null 接口的网络数据报文会被丢弃）
- 系统视图下键入 `interface null 0`

Tunnel 接口视图：

- `[HUAWEI-Tunnel0]` 配置隧道接口视图参数
- 系统视图下键入 `interface tunnel 0`

