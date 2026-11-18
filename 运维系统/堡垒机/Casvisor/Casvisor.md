Casvisor 把 SSH、RDP、VNC、Telnet 四种协议、权限控制、会话录像和命令审计做在一个 Go 二进制里，被管理的服务器不用装 agent

- 源码：<https://github.com/casvisor/casvisor>
- 官网和文档：<https://casvisor.org/>
- 在线演示：<https://door.casvisor.com>

快速启动

```bash
docker run -it -d --name casvisor \
  -p 19000:19000 \
  -p 2222:2222 \
  -v casvisor-db:/db \
  -v casvisor-recordings:/recordings \
  docker.io/casbin/casvisor:v1.111.0
```

启动后看初始密码：

```bash
docker logs casvisor
```

Casvisor 本身不直接提供独立的 LDAP 配置项，而是通过接入 Casdoor 实现 LDAP 登录与用户组权限映射