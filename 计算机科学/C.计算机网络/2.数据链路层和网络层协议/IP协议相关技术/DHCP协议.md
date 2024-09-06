## DHCP 协议

DHCP(DynamicHost ConfigurationProtocol)，动态主机配置协议，是一个应用层协议

DHCP 的几个概念：

- DHCPClient：DHCP客户端，通过DHCP协议请求IP地址的客户端。DHCP客户端是接口级的概念，如果一个主机有多个以太接口，则该主机上的每个接口都可以配置成一个DHCP客户端。交换机上每个Vlan接口也可以配置成一个DHCP客户端

- DHCPServer：DHCP服务端，负责为DHCP客户端提供IP地址，并且负责管理分配的IP地址

- DHCPRelay：DHCP中继器，DHCP客户端跨网段申请IP地址的时候，实现DHCP报文的转发功能

- DHCPSecurity：DHCP安全特性，实现合法用户IP地址表的管理功能

- DHCPSnooping：DHCP监听，记录通过二层设备申请到IP地址的用户信息

## DHCP 工作原理

DHCP 使用 UDP 协议工作，采用 67 (DHCP 服务器端) 和 68 (DHCP 客户端) 两个端口号

546 号端口用于 DHCPv6Client，而不用于 DHCPv4，是为 DHCPfailover 服务

![img](./.assets/DHCP协议/a2d194ef33a7a1a64d9b3ded6d3af95d.jpg)

DHCP 客户端向 DHCP 服务器发送的报文称之为 DHCP 请求报文，而 DHCP 服务器向 DHCP 客户端发送的报文称之为 DHCP 应答报文

DHCP 交互过程共分为 4 步：

- 第一步，Client 端在局域网内发起一个 DHCP Discover 包，目的是想发现能够给它提供 IP 的 DHCPServer（当前的网络连接处于断开状态，主机 IP 变为 `0.0.0.0`）

- 第二步，可用的 DHCPServer 接收到 Discover 包之后，通过发送 DHCPOffer 包给予 Client 端应答，意在告诉 Client 端它可以提供 IP 地址

- 第三步，Client 端接收到 Offer 包之后，发送 DHCPRequest 包请求分配 IP

- 第四步，DHCPServer 发送 ACK 数据包，确认信息

### DHCP Discover数据包

在 Discover 阶段，可以看出客户端发出的是广播复制。从下图也可以看出 DHCP 是基于 UDP 协议的，采用 67 (DHCP 服务器端) 和 68 (DHCP 客户端) 两个端口号，这个上文讲过了，在抓包文件中证实了。DHCP 报文格式基于 BOOTP 的报文格式，DHCP 具体的报文格式并不是本文重点，本文并不会详细讲解 DHCP 报文中每个字节的含义

![img](./.assets/DHCP协议/7f3b5a3827b8dc88602f023257f168e0.jpg)

### DHCP Offer 包

当 DHCP 服务器收到一条 DHCPDiscover 数据包时，用一个 DHCPOfferr 包给予客户端响应。 这一数据报中客户客户端获取到了最重要的 IP 地址信息。除此之外，服务器还发送了子网掩码，路由器，DNS，域名，IP 地址租用期等信息

DHCP 服务器仍然使用广播地址作为目的地址，因为此时请求分配 IP 的 Client 并没有自己 ip, 而可能有多个 Client 在使用 0.0.0.0 这个 IP 作为源 IP 向 DHCP 服务器发出 IP 分配请求，DHCP 也不能使用 0.0.0.0 这个 IP 作为目的 IP 地址，于是依然采用广播的方式，告诉正在请求的 Client 们，这是一台可以使用的 DHCP 服务器

![img](./.assets/DHCP协议/432090a61dfc43cd71c644710853c12d.jpg)

### DHCP Request 包

当 Client 收到了 DHCPOffer 包以后 (如果有多个可用的 DHCP 服务器，那么可能会收到多个 DHCPOffer 包)，确认有可以和它交互的 DHCP 服务器存在，于是 Client 发送 Request 数据包，请求分配 IP

此时的源 IP 和目的 IP 依然是 0.0.0.0 和 255.255.255.255

![img](./.assets/DHCP协议/b2cb8edc69667c7363fc5b30b3b6bcf5.jpg)

### DHCP ACK 包

服务器用 DHCPACK 包对 DHCP 请求进行响应

![img](./.assets/DHCP协议/0a12b28063629f6a34cb542eba99d1ac.jpg)