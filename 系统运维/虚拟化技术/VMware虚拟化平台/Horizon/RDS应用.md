RDS（全称 Remote Desktop Services）是微软 Windows Server 上提供的一项服务，该服务允许多个用户同时登陆并使用 Windows Server，相比 VDI 能节省更多的资源，也更加轻量。在 Horizon 中可以用 RDS 来发布两种类型的服务，一种是发布共享桌面，另一种则是直接发布 RDS 主机中已经安装好的应用，即虚拟应用

为了使得用户可以正常登陆共享的 Windows Server 使用 RDS 服务，需要编辑域控的组策略

```
gpmc.msc
```

允许用户远程登陆（需要同时添加管理员和普通用户）：

![img](./.assets/RDS应用/16153914_62d26b22c8b8a20224.png)

- <https://blog.51cto.com/sparkgo/5478585>