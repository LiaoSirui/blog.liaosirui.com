## NGinx 简介

nginx 官方网站 <https://nginx.org/>

## 二进制安装 nginx

nginx 官方下载 <https://nginx.org/download/>

rpm 包下载(官方 rpm 包下载地址) <http://nginx.org/packages/rhel/7/x86_64/RPMS/>

### SELinux

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

