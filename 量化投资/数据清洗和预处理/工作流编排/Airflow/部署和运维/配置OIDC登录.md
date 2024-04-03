使用 OIDC 登录

参考文档：<https://airflow.apache.org/docs/apache-airflow/stable/security/webserver.html>

```python
from airflow.auth.managers.fab.security_manager.override import FabAirflowSecurityManagerOverride
from flask_appbuilder.security.manager import AUTH_OAUTH
import os

AUTH_TYPE = AUTH_OAUTH
AUTH_ROLES_SYNC_AT_LOGIN = True  # Checks roles on every login
AUTH_USER_REGISTRATION = True  # allow users who are not already in the FAB DB to register

AUTH_ROLES_MAPPING = {
    "Viewer": ["Viewer"],
    "Admin": ["Admin"],
}
# If you wish, you can add multiple OAuth providers.
OAUTH_PROVIDERS = [
    {
        "name": "github",
        "icon": "fa-github",
        "token_key": "access_token",
        "remote_app": {
            "client_id": os.getenv("OAUTH_APP_ID"),
            "client_secret": os.getenv("OAUTH_APP_SECRET"),
            "api_base_url": "https://api.github.com",
            "client_kwargs": {"scope": "read:user, read:org"},
            "access_token_url": "https://github.com/login/oauth/access_token",
            "authorize_url": "https://github.com/login/oauth/authorize",
            "request_token_url": None,
        },
    },
]


class CustomSecurityManager(FabAirflowSecurityManagerOverride):
    pass


# Make sure to replace this with your own implementation of AirflowSecurityManager class
SECURITY_MANAGER_CLASS = CustomSecurityManager
```

