## DNS Zone

DNS 被划分为多个不同的 Zone。这些 Zone（区域）在 DNS 命名空间中以不同方式进行管理。DNS Zone 是 DNS 命名空间的一部分，由特定组织或管理员进行管理。DNS Zone 是一个管理空间，可以实现对权威名称服务器等 DNS 组件的精细控制。域名空间是一个分层的树状结构，DNS 根域位于其顶部。DNS 区域从树中的一个域开始，可以向下扩展到子域中，以便一个组织可以管理多个子域。一个 DNS Zone 包含了该子域中所有 DNS 记录。每个 DNS Zone 由一个（组） DNS 服务器负责管理，该服务器被称为主 DNS 服务器或权威 DNS 服务器。DNS Zone 可以包含各种类型的记录，如：A、MX、CNAME、NS、TXT 等。

一种常见的误区是将 DNS Zone 与域名或单一 DNS 服务器相混淆。实际上，DNS Zone 可以包含多个子域，并且多个 Zone 可以存在于同一服务器上。DNS Zone 并不一定要分离，而必须严格使用 Zone 来分配控制权。

一个 DNS Zone 主要包含以下内容：

- 区域文件：存储区域信息的文本文件，包括所有的 DNS 记录。
- SOA 记录：Start of Authority 记录，定义了区域的权威 DNS 服务器和其他管理信息。
- NS 记录：Name Server 记录，定义了负责该区域的 DNS 服务器。
- 其他记录：如 A 记录、AAAA 记录、MX 记录等，分别定义了主机名到 IP 地址的映射、邮件服务器等。

## AXFR 和 IXFR

因为在主从 DNS Zone 同步过程中，会用到 AXFR、IXFR 两种方式，所以这里简单介绍一下两者之间的区别。

AXFR（全区域传输，Full Zone Transfer） 和 IXFR（增量区域传输，Incremental Zone Transfer） 是两种用于 DNS 服务器之间同步 Zone 数据的方法。

### AXFR

AXFR 用于在主 DNS 服务器和从 DNS 服务器之间进行全区域传输。它将整个 DNS 区域文件从主服务器传输到从服务器。这种方法适用于以下情况：

- 初次设置从服务器时。
- 区域文件发生了大的变化，需要完全重新传输。

优点：

- 简单易用。
- 确保从服务器与主服务器的数据完全一致。

缺点：

- 数据传输量大，效率低。
- 对带宽和服务器性能有较高的要求。

### IXFR

IXFR 用于在主 DNS 服务器和从 DNS 服务器之间进行增量区域传输。它只传输自上次同步以来发生变化的记录。这种方法适用于以下情况：

- 区域文件发生了小的变化。
- 需要频繁同步区域数据。

优点：

- 数据传输量小，效率高。
- 对带宽和服务器性能要求较低。

缺点：

- 实现较为复杂。
- 需要主服务器和从服务器都支持 IXFR。

## 资源类型

Resource Record,RR

```plain
# 常用 DNS 服务器管理的记录类型，假设 zone 为 domain
[domain]   IN  [[RR type]  [RR data]]
domain.    IN  SOA         管理 domain 的 7 个参数（下文详细说明）
domain.    IN  NS          管理这个 Zone 的 DNS 服务器主机名称
 
# 管理 DNS 标准规范内的所有正向解析记录
[domain]   IN  [[RR type]  [RR data]]
hostname.  IN  A           hostname. 的 IPv4 的 IP 位址
hostname.  IN  AAAA        hostname. 的 IPv6 的 IP 位址
domain.    IN  MX          接收 domain. 邮件服务器主机名
hostname.  IN  CNAME       hostname. 别名类型
hostname.  IN  TXT         一串代表 hostname. 的解释资料，主要用于域名归属权验证、邮件服务等
 
# 管理 DNS 标准规范内的所有反向解析记录
[domain]   IN  [[RR type]  [RR data]]
hostname.  IN  PTR         代表 hostname.
```

## Zone 配置

在配置 Zone 的过程中，会用到三个插件：file 、transfer、secondary。

- File 插件：主要用于 Zone 配置文件加载管理，`reload` 如果 SOA 版本号发生变化，则执行区域重新加载的间隔。默认值为 `1` 分钟。当值为 `0` 时，表示不扫描更改并重新加载。例如：`reload 30s` 每 30 秒检查一次区域文件，并在 SOA 版本号发生变化时重新加载区域。
- Transfer 插件：主要用于将对应的 Zone 配置同步至指定的 DNS 服务器从节点。Transfer 会回答完整区域传输 (AXFR) 请求和增量区域传输 (IXFR) 请求，如果 Zone 发生变化时，则会使用 AXFR 请求。
- Secondary 插件：主要用于 DNS 服务器从节点，可以通过 AXFR 从另一台 DNS 服务器同步 Zone 信息。同步到的 Zone 信息并不会保存至文件（因为这违反了 RFC。这与 Bind DNS 是不同的，Bind DNS 从节点接收到的 Zone 文件会存放在 `/var/named/slaves/` 目录）。这就意味着重启从节点 DNS 服务，将导致从节点 DNS 缓存数据丢失，需要从主节点重新检索所有 Zone 信息。如果主节点 CoreDNS 启动后未响应从节点 AXFR 请求，则 AXFR 将每 `10` 秒无限期重试一次。此插件仅支持 AXFR。

### 主节点配置

```corefile
# 定义 Zone
rockylinux.lan {
  # 指定 Zone 配置文件路径
  file /etc/coredns/zones/db.rockylinux.lan
  reload 30s
  # 配置 Zone 传输参数
  transfer {
    # 使用 Transfer 插件，允许 IP 地址 192.168.1.2 请求该区域的传输，可以使用 * 表示所有允许所有IP。
    to 192.168.1.2
  }
  log
  errors
}
```

创建 `/etc/coredns/zones/db.rockylinux.lan` Zone 文件，写入以下配置

```corefile
# 指定该区域文件的根域名，这里根域名是rockylinux.lan.
ORIGIN rockylinux.lan.

# 设置默认的生存时间（Time To Live），单位为秒，这里设置为 3600 秒（1小时）
$TTL 3600
 
@   IN  SOA ns1.rockylinux.lan. admin.rockylinux.lan. (
    2024070806 ; Serial
    3600       ; Refresh
    1800       ; Retry
    1209600    ; Expire
    3600       ; Minimum TTL
  )

  # 定义 DNS 服务器信息
  IN  NS  ns1.rockylinux.lan.
  IN  NS  ns2.rockylinux.lan.

# A 记录定义主机名映射到IPv4地址
ns1 IN  A   192.168.1.1
ns2 IN  A   192.168.1.2
 
api IN  A   192.168.4.1
bbs IN  A   192.168.4.2
```

相关配置参数说明：

- `$ORIGIN rockylinux.lan.` 指定该区域文件的根域名，这里根域名是 `rockylinux.lan.`。
- `$TTL 3600` 设置默认的生存时间（Time To Live），单位为秒，这里设置为 3600 秒（1 小时）。
- `IN NS ns1.rockylinux.lan.` 定义 DNS 服务器信息 NS 记录信息。
- `ns1 IN A 192.168.1.1` 定义 DNS 服务器 A 记录信息。

区域起始授权记录（Start of Authority, SOA）定义：

- `@` 表示当前 Zone 区域（这里是 `rockylinux.lan.`）。
- `IN` 是 Internet 缩写，表示互联网类记录。
- `SOA` 是 start of authority 缩写，表示起始授权记录。
- `ns1.rockylinux.lan.` 是主 DNS 服务器的完全限定域名（FQDN）即 `hostname.domain`，这里定义了主 DNS 服务器的名称。
- `admin.rockylinux.lan.` 是负责该域的管理员邮箱地址，通常会将 `@` 替换成 `.`，实际邮箱地址为：`admin@rockylinux.lan`。
- `.` 在域名的后面都带有一个 `.`，即根区域 （root zone）。
- `2024070806` 是序列号，用于标识区域文件的版本号，每次更新配置文件都需要手动新增序列号，采用递增模式，常用格式为：`YYYYMMDDNN`（年/月/日/版本号）。
- `3600` 是刷新时间，从 DNS 服务器多久检查主 DNS 服务器是否有更新（单位为秒）。
- `1800` 是重试时间，如果从 DNS 服务器尝试连接主 DNS 服务器刷新失败，等待多长时间再试（单位为秒）。
- `1209600` 是过期时间，从 DNS 服务器在多长时间内如果仍连接主 DNS 服务器刷新失败，则停止提供该区域的查询请求（单位为秒）, `1209600` 秒（即 `14` 天）。
- `3600` 在新的 DNS 标准中，`Minimum TTL` 字段实际上被更准确地称为 Negative TTL ，意思是这个域名的负面缓存时间（Negative Caching TTL）。具体来说，当一个 DNS 查询没有找到对应的资源记录（例如，一个查询结果是 NXDOMAIN，表示该域名不存在时），这个负面结果会被缓存一段时间，`Negative TTL` 就是指缓存该负面结果的时间。`3600` 表示在 DNS 查询没有找到对应的资源记录时，负面缓存的时间是 3600 秒，或者 1 个小时。在这段时间内，重复的查询将直接返回缓存的负面结果，而不会再次查询 DNS 服务器以减少查询数量和负载。

### 从节点配置

```corefile
rockylinux.lan {
  # 配置 CoreDNS 从节点通过 CoreDNS 主节点获取 Zone 信息
  secondary {
    transfer from 192.168.1.1
  }
  log
  errors
}
```

因为从节点从主节点获取 Zone 信息进行缓存，所以不需要单独创建 `/etc/coredns/zones/db.rockylinux.lan` Zone 文件。

从节点每隔 3600 秒，从主节点检查一次 Zone 是否有更新

### 同步过程

通过新增一条 A 记录解析，来看看 `file` 与 `transfer` 插件是怎么工作的。

新增主节点对应 Zone A 记录，并修改对应 `Serial` 序列号（递增），`file` 插件默认每隔 `1` 分钟（通过 `reload 30s` 可以修改检查间隔时间）检测一次 Zone 文件，发现 `Serial` 发生变化，进行 `reload` 重载。

主节点重载配置，并通过 `transfer` 插件发送通知给从节点 192.168.1.2，告诉从节点 `rockylinux.lan.` 区域已更新。并通过 `transfer` 插件将区域 `rockylinux.lan.` 的 9 条记录传输给 `192.168.1.2`，来自 `2024070813` SOA 序列。

从节点接收来自主节点的检查传输，并接收来自主节点的区域解析记录。

### 子域名转发配置

```corefile
rockylinux.lan:53 {
  file /etc/coredns/zones/db.rockylinux.lan
  transfer {
    to 192.168.1.2
  }
  log
  errors
}
 
# 新增配置
web.rockylinux.lan:53 {
  forward . 192.168.1.3
  log
  errors
}
```

## 反向解析

在设置反向解析区域（Zone）时，需要特别注意以下几点：

1. IP 地址信息需要倒序书写。
2. 反向解析区域必须以 `.in-addr.arpa` 结尾。

例如，对于 `192.168.{1,2,3,4}.0/24` 子网，反向解析区域的设置如下：

- 1.168.192.in-addr.arpa.
- 2.168.192.in-addr.arpa.
- 3.168.192.in-addr.arpa.
- 4.168.192.in-addr.arpa.

例如

```corefile
$ORIGIN 4.168.192.in-addr.arpa.
$TTL 3600

@ IN SOA ns1.rockylinux.lan. admin.rockylinux.lan. (
        2024070818 ; Serial
        3600       ; Refresh
        1800       ; Retry
        1209600    ; Expire
        3600       ; Minimum
    )

    IN  NS  ns1.rockylinux.lan.
    IN  NS  ns2.rockylinux.lan.

1   IN  PTR api.rockylinux.lan.
2   IN  PTR bbs.rockylinux.lan.
3   IN  PTR www.rockylinux.lan.
```
