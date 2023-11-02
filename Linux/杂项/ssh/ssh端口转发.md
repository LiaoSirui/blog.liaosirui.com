
什么是端口转发？骑士想给公主写信，却被国王禁止，骑士只得请侍女将信带到，这就是“转发”。网络通信中，IP 标识机器（城堡），端口标识应用（国王还是公主），我们可不希望侍女把信送到国王手里。

## 正向转发

local port forward

本地端口转发指的是在本机上发起请求，由 ssh client 转发到远程的机器上。它的命令如下：

```bash
ssh -L <port_a>:<remote host>:<port_b> user_b@ip_b
```

下图中，远程的机器上起了一个服务 python3 -m http.server，它监听端口 8000，现在我们想在本机访问这个服务，但由于防火墙的存在，8000 端口无法直接访问，于是我们使用 ssh 端口转发。

![img](.assets/local-port-forwarding-single.svg"  />

首先在 A 上执行 `ssh -L 1234:localhost:8000 user_b@ip_b` 建立 ssh 隧道，它表示：所有对 A:1234 端口的请求，相当于在 B 机器上对 `localhost:8000` 的请求。因此在 A 上执行 `curl localhost:1234` 就相当于访问 B 机器上的 python 服务。

上面的情况是服务部署在 ssh server 所在的机器（B）上，那么如果服务部署在其它的机器上呢？

![img](.assets/local-port-forwarding-two.svg"  />

可以看到我们只是把上例中的 localhost 换成了 C 机器的 hostname/IP 就可以了。此时，发送到 `A:1234` 的请求相当于从 B 机器上对 `remote:8000` 的请求，图中在 /etc/hosts 中设置了 hostname 和 IP 的对应关系，直接用机器 C 的 IP 也是可以的。可以看到，机器 A 由于防火墙无法访问内网的服务，但是由于

- 机器 A 可以 ssh 到内网机器 B
- 且 B 有权限访问内网的其它服务

通过本地端口转发可以实现从 A 访问内网的服务。

## 反向转发

remote port forward

本地机器 A 可以 ssh 到内网机器 B，但如果防火墙不允许呢（或者 B 没有公网的 IP）？如果机器 A 有公网的 IP，且机器 B 允许联网，则可以通过远程端口转发完成。远程端口转发的命令如下：

```bash
ssh -R <port_a>:<remote host>:<port_a> user_a@ip_a
```

与之前不同，此时 ssh server 是运行在本地机器 A 上，在内网机器 B 上执行上述命令。

![img](.assets/remote-port-forwarding.svg"  />

为什么称作“远程转发”呢？把最终请求的发起方（机器 A）为“本地”，服务所在的机器 B/C 为“远程”，在本地机器上执行 ssh 命令就称为“本地转发”，在远程机器上执行命令就称为“远程转发”。

## 路由转发

机器 A 配置好本地转发后，A:1234 只能被机器 A 访问，如果本地还有其它机器想访问这个服务怎么办？可以使用 -g 开启路由模式，命令如下：

```bash
ssh -g -L <port_a>:<remote host>:<port_b> user_b@ip_b
```

![img](.assets/local-port-forwarding-gateway.svg"  />

但要注意的是本地机器间的连接（下图中 X->A、B->C）不是安全连接，所以要谨慎使用。

要注意的是上述方法只对“本地转发”有效，如果想要在远程转发上使用路由功能，需要在“本地”机器 A 中的 /etc/sshd_config 中加入 GatewayPorts yes 并重启 sshd 服务：

![img](.assets/remote-port-forwarding-gateway.svg"  />

但默认情况下转发端口仅允许本地访问，不对局域网开放，需要修改​​ `GatewayPorts​​​` 参数位于 `​​/etc/ssh/sshd_config​​`

```plain
GatewayPorts - "Specifies whether remote hosts are allowed to connect to ports forwarded for the client. By default, sshd(8) binds remote port forwardings to the loopback address. This prevents other remote hosts from connecting to forwarded ports. GatewayPorts can be used to specify that sshd should allow remote port forwardings to bind to non-loopback addresses, thus allowing other hosts to connect."
```

取消注释​​ GatewayPorts​​ 并修改默认值 no 为 yes 后重启 sshd 服务即可生效。

该设置允许转发后的端口绑定在 0.0.0.0 上，确保从每个网卡的 ip 上都能访问到 8000 服务。

### 后台执行

即使通过​​ `ssh -Nf` ​​参数后台执行，上述方法缺点依然明显，session 断开后端口转发随之消失。

想要实现类似商用内网穿透的开机自动连接可以使用 autossh 进行自动连接并发送心跳包

### autossh

详见 autossh 部分

## 动态代理

上面的所有方法都只针对一个端口，想要转发所有端口怎么做？

```bash
ssh -D <port> user@remote_ip
```

这个模式对本地和远程转发都有效，它的工作模式和 Shadow Socks 很像，会在本地创建一个 Socks5 代理服务，监听端口 `<port>`，并将所有请求转发到远程机器上。如下图：

![img](.assets/dynamic-port-forwarding.svg"  />

图中我们通过 `curl -x socks5h://...` 来指定使用 Socks5 代理，在机器 A 上请求 `ip_c:8000` 时，相当于在 B 机器上发起对 `ip_c:8000` 的请求。
