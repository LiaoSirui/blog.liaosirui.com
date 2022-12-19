calico 在多网络接口时自动检测到错误的网络接口,导致网络无法连通，通过指定网络接口(网卡名)解决问题

增加

```
- name: IP_AUTODETECTION_METHOD
  value: "interface=enp0s3"
```

执行

```bash
kubectl set env daemonset/calico-node -n kube-system IP_AUTODETECTION_METHOD=skip-interface=enp0s8
```

IP_AUTODETECTION_METHOD 配置项默认为 first-found，这种模式中 calico 会使用第一获取到的有效网卡，虽然会排除 docker 网络，localhos t啥的，但是在复杂网络环境下还是有出错的可能。

`IP_AUTODETECTION_METHOD` 还提供了如下配置 

```
can-reach=DESTINATION

interface=INTERFACE-REGEX

skip-interface=INTERFACE-REGEX
```

`can-reach=DESTINATION` 配置可以理解为 calico 会从部署节点路由中获取到达目的 ip 或者域名的源 ip 地