## compose 部署 netbox

按照官方 compose 部署即可，详见：<https://github.com/netbox-community/netbox-docker/blob/release/docker-compose.yml>

修改后的参考：

```yaml
#...
```

手动生成一个加密密钥

```bash
docker run -it --rm \
    harbor.alpha-quant.tech/3rd_party/docker.io/netboxcommunity/netbox:v4.4.6-3.4.2 \
    /opt/netbox/venv/bin/python3 /opt/netbox/netbox/generate_secret_key.py
```

创建 admin 账号

```bash
docker compose exec -it netbox \
    /opt/netbox/venv/bin/python3 /opt/netbox/netbox/manage.py createsuperuser
```

## 其他问题处理

### csv 导出编码问题

NetBox 在导出 CSV 的时候，会是使用 UTF-8 编码，而不是 UTF-8-SIG 编码。这样会导致导出的文件，在微软的 Excel 打开中会乱码

直接修改 Netbox 虚拟环境的 django_tables2 库的默认编码，这样只要不升级或重装此库就不会失效

```bash
vim /opt/netbox/venv/lib/python3.12/site-packages/django_tables2/export/export.py

# 修改库文件，路径看自己的实际情况
# line 37

    FORMATS = {
        CSV: "text/csv; charset=utf-8-sig",
        JSON: "application/json",
        LATEX: "text/plain",
        ODS: "application/vnd.oasis.opendocument.spreadsheet",
        TSV: "text/tsv; charset=utf-8",
        XLS: "application/vnd.ms-excel",
        XLSX: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        YAML: "text/yaml; charset=utf-8",
    }
```

等效

```bash
sed -i 's#text/csv; charset=utf-8#text/csv; charset=utf-8-sig#g' \
/opt/netbox/venv/lib/python3.12/site-packages/django_tables2/export/export.py
```

### OIDC 登录

增加以下 Python 依赖

```
python-jose[cryptography]
```

增加以下配置

```python
REMOTE_AUTH_BACKEND = "social_core.backends.open_id_connect.OpenIdConnectAuth"
SOCIAL_AUTH_OIDC_OIDC_ENDPOINT = "https://alpha-quant.tech/idp"
SOCIAL_AUTH_OIDC_KEY = "oidc-key"
SOCIAL_AUTH_OIDC_SECRET = "oidc-secret-here"

SOCIAL_AUTH_PROTECTED_USER_FIELDS = [
    "groups"
]
SOCIAL_AUTH_REDIRECT_IS_HTTPS = True

```

