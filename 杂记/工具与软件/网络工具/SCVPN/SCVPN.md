## 安装 SCVPN

Ubuntu 20

```
dpkg -i SCVPN-1.2.0.deb
```

CentOS8

```
dnf localinstall scvpn-1.2.0-1.ter.x86_64.rpm
```

开启程序

```
sudo scvpn start
```

官方文档

- <https://kb.hillstonenet.com/cn/linux-sslvpn-install-use/>

网络开通：

- SSL VPN 的端口（通常是 4433）
- 还需要额外开通 UDP 协议，端口同 SSL VPN

## 稳定传输

官方文档

- <https://kb.hillstonenet.com/cn/sslvpn-communication-stability-optimization/>

开启 TCP 协议传输；当两端都配置tcp时，正常协商，使用tcp传输