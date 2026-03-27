参考文档：

- <https://www.cnblogs.com/dier-gaohe/p/17304707.html>

## vSAN 管理

ESXi 的 VSAN 命名空间包括配置并维护 VSAN 的很多命令，包括数据存储、网络、默认域名以及策略配置

```
esxcli vsan
```

本地主机脱离/加入VSAN集群

```
# esxcli vsan cluster
esxcli vsan cluster leave
```

配置 VSAN 使用的本地存储，包括增加、删除物理存储并修改自动声明

```
esxcli vsan storage
```

