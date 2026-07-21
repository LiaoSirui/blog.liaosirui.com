## SELinux 简介

SELinux的策略与规则管理相关命令：seinfo 命令、sesearch 命令、getsebool 命令、setsebool 命令、semanage 命令

## 实例

- nginx 端口

```bash
# 放行监听端口
semanage port -l | grep http_port_t
semanage port -a -t http_port_t -p tcp 8088

# 放行上游
setsebool -P httpd_can_network_connect 1
setsebool -P httpd_can_network_relay 1

# 放行阻止的调用
cat /var/log/audit/audit.log | grep nginx | grep denied | audit2allow -M nginx
semodule -i nginx.pp
```

- node_exporter

```bash
semanage fcontext -a -t bin_t "/usr/sbin/node_exporter"
restorecon -r -v /usr/sbin/node_exporter
```

## 参考资料

- <https://wangchujiang.com/linux-command/c/semanage.html>
- <http://c.biancheng.net/view/1147.html>
- <https://eonun.com/%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0/Linux/SELinux%E4%B8%8A%E4%B8%8B%E6%96%87%E7%AD%96%E7%95%A5%E7%AE%A1%E7%90%86/>
