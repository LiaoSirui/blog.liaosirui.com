配置文件 `/etc/squid/squid.conf`

增加安全验证

- 修改默认端口

```conf
http_port 3129
```

- 添加密码验证

```bash
# 生成密码文件，指定文件路径，其中 squid 是用户名，密码不能超过 8 个字符??
htpasswd -cd /etc/squid3/passwords squid
```

测试生成的密码文件

```bash
> /usr/lib64/squid/basic_ncsa_auth /etc/squid3/passwords                
squid 123456
ok
```

配置 Squid 文件

```bash
> vim /etc/squid/squid.conf
# And finally deny all other access to this proxy
auth_param basic program /usr/lib64/squid/basic_ncsa_auth /etc/squid3/passwords # 账户密码文件
auth_param basic realm proxy
auth_param basic children 50 # 最多 50 个账户同时运行
auth_param basic realm CoolTube Proxy Server # 密码框描述
auth_param basic credentialsttl 2 hours # 认证持续时间
acl authenticated proxy_auth REQUIRED # 对 authenticated 进行外部认证
http_access allow authenticated # 允许 authenticated 中的成员访问
http_access deny all # 拒绝所有其他访问
visible_hostname squid.CoolTube # 代理机名字
```

