## API 访问

文档：<https://docs.ansible.com/projects/awx/en/latest/rest_api/>

具体的站点可以访问：<https://awx.alpha-quant.tech/api/>

## 安装 cli 工具

```bash
pipx install awxkit
```

## 访问

文档地址：<https://github.com/ansible/awx/blob/devel/awxkit/awxkit/cli/docs/source/usage.rst>

登录到对应的 awx 实例

```bash
awx --conf.host https://awx.alpha-quant.tech \
    --conf.username sirui.liao --conf.password secret \
    --conf.insecure \
    users list
```

使用环境变量

```bash
export CONTROLLER_HOST=https://awx.alpha-quant.tech
export CONTROLLER_USERNAME=sirui.liao
export CONTROLLER_PASSWORD=secret
export CONTROLLER_VERIFY_SSL=False

awx users list
```

使用 Python 调用

```python
import awxkit
import os

AWX_USER = "sirui.liao"
AWX_PASS = "secret"
JOB_ID = 12345

# 设置认证
awxkit.config.base_url = os.environ.get("AWX_URL", "https://awx.alpha-quant.tech")
awxkit.config.credentials = awxkit.utils.PseudoNamespace(
    {
        "default": {
            "username": os.environ.get("AWX_USERNAME", AWX_USER),
            "password": os.environ.get("AWX_PASSWORD", AWX_PASS),
        }
    }
)
connection = awxkit.api.Api()
connection.load_session().get()
client = connection.available_versions.v2.get()

awxjob = client.jobs.get(id=JOB_ID).results[0]
print(awxjob.status)

```

