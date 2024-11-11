## PAM

管理密码忘记了或者重置管理员密码

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