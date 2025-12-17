- 特定 IP

`spec.loadBalancerIP` 指定具体的 IP

- 特定的 IP 地址池

如果你想使用特定的类型的 IP, 但是不在乎具体是什么地址, MetalLB 同样也支持请求一个特定的 IP 地址池

为能能使用特定的地址池, 需要在 Service 中添加一个 annotation: `metallb.universe.tf/address-pool`, 来指定IP地址池的名称
