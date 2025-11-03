## PAM

重置管理员密码

```bash
source /opt/py3/bin/activate
cd /opt/jumpserver/apps

python manage.py changepassword <user_name>
```

新建超级用户的命令如下命令

```bash
source /opt/py3/bin/activate
cd /opt/jumpserver/apps

python manage.py createsuperuser --username=user --email=user@domain.com
```

## 重置 MFA

```python
# python manage.py shell
from users.models import User
u = User.objects.get(username='admin')
u.mfa_level='0'
u.otp_secret_key=''
u.save()
```

## Win 远程

### 远程计算机接收到非预期的服务器身份验证证书

使用 WEB GUI 方式连接 Windows 资产时，弹窗显示“远程计算机接收到非预期的服务器身份验证证书”。此问题出现的原因可能是通过 https 访问 JumpServer 页面时，负载均衡配置的 SSL 证书与 JumpServer 节点的证书不一致。

修改负载均衡节点的 SSL 证书或者 JumpServer 节点的 SSL 证书，使得负载均衡节点的证书与 JumpServer 节点的证书一致。

修改配置文件 `/opt/jum/server/config/config.txt` 添加下面两个参数

```bash
SSL_CERTIFICATE=test.jumpserver.crt      # /opt/jumpserver/config/nginx/cert 目录下你的证书文件
SSL_CERTIFICATE_KEY=test.jumpserver.key  # /opt/jumpserver/config/nginx/cert 目录下你的 key 文件
```

### Razor 证书错误导致连接被终止

<img src="./.assets/JMS运维/image-woun.png" alt="img" style="zoom:33%;" />

颁发证书的 dev 机构是代码自动生成

可以通过配置 `"SSL_CERTIFICATE=your_cert"` 和 `"SSL_CERTIFICATE_KEY=your_cert_key"` 参数启用企业信任的证书来解决该问题

```bash
if [ -n "${SSL_CERTIFICATE}" ] && [ -n "${SSL_CERTIFICATE_KEY}" ]; then
  cp -rf /opt/razor/cert/${SSL_CERTIFICATE} /opt/razor/server.crt
  cp -rf /opt/razor/cert/${SSL_CERTIFICATE_KEY} /opt/razor/server.key
  chmod 644 /opt/razor/server.crt /opt/razor/server.key
fi
```

## 参考资料

- <https://kb.fit2cloud.com/?p=8eddffc7-23a3-4bde-a067-c78e72faffc0>

- <https://kb.fit2cloud.com/?p=116>