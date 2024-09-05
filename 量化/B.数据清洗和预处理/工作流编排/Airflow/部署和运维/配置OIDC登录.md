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

其他参考 <https://github.com/apache/airflow/discussions/35939>

```python
import os
from flask_appbuilder.security.manager import AUTH_OAUTH
from oauth_authorizer import KeycloakRoleAuthorizer


basedir = os.path.abspath(os.path.dirname(__file__))

WTF_CSRF_ENABLED = True
WTF_CSRF_TIME_LIMIT = None

AUTH_TYPE = AUTH_OAUTH
AUTH_ROLES_SYNC_AT_LOGIN = True  # Checks roles on every login
AUTH_USER_REGISTRATION = True  # allow users who are not already in the FAB DB to register
SECURITY_MANAGER_CLASS = KeycloakRoleAuthorizer
AUTH_ROLES_MAPPING = {
    "Admin": ["Admin"],
    "User": ["User"],
    "Viewer": ["Viewer"],
}
oauth_client_secret = os.getenv("OAUTH_CLIENT_SECRET")
# this allows mounting from k8s secret in helm config
oauth_client_secret_fn = os.getenv("OAUTH_CLIENT_SECRET_FILE", '/var/tmp/ocs')
if os.path.isfile(oauth_client_secret_fn):
    with open(oauth_client_secret_fn, 'r') as ocs: oauth_client_secret = ocs.read()
OAUTH_PROVIDERS = [
    {
        "name": "kc2fa",
        "icon": "fa-key",
        "token_key": "access_token",
        "remote_app": {
            "client_id": os.getenv("OAUTH_CLIENT_ID"),
            "client_secret": oauth_client_secret,
            "api_base_url": os.getenv("OAUTH_CLIENT_API_BASE_URL"),
            "access_token_url": os.getenv("OAUTH_ACCESS_TOKEN_URL"),
            "authorize_url": os.getenv("OAUTH_AUTHORIZE_URL"),
            "jwks_uri": os.getenv("OAUTH_JWKS_URL"),
            "request_token_url": None,
            "client_kwargs": {
                "scope": "email profile"
            },
        },
    },
]

# ----------------------------------------------------
# Theme CONFIG
# ----------------------------------------------------
# Flask App Builder comes up with a number of predefined themes
# that you can use for Apache Airflow.
# http://flask-appbuilder.readthedocs.io/en/latest/customizing.html#changing-themes
# Please make sure to remove "navbar_color" configuration from airflow.cfg
# in order to fully utilize the theme. (or use that property in conjunction with theme)
# APP_THEME = "bootstrap-theme.css"  # default bootstrap
# APP_THEME = "amelia.css"
# APP_THEME = "cerulean.css"
# APP_THEME = "cosmo.css"
# APP_THEME = "cyborg.css"
APP_THEME = "darkly.css"
# APP_THEME = "flatly.css"
# APP_THEME = "journal.css"

---
from flask import redirect
from flask_appbuilder import expose
from flask_appbuilder.security.views import AuthOAuthView
from flask_login import logout_user
from airflow.auth.managers.fab.security_manager.override import FabAirflowSecurityManagerOverride
from typing import Any, List, Union
import logging
import os
import jwt


log = logging.getLogger(__name__)
log.setLevel(os.getenv('AIRFLOW__LOGGING__FAB_LOGGING_LEVEL', 'INFO'))

FAB_ADMIN_ROLE = 'Admin'
FAB_USER_ROLE = 'User'
FAB_VIEWER_ROLE = 'Viewer'
FAB_PUBLIC_ROLE = 'Public'  # The 'Public' role is given no permissions

KC_ADMIN_ROLE = 'AirflowAdmin'
KC_USER_ROLE = 'AirflowUser'
KC_VIEWER_ROLE = 'AirflowViewer'


def map_roles(team_list: list) -> list:
    team_role_map = {
        KC_ADMIN_ROLE: FAB_ADMIN_ROLE,
        KC_USER_ROLE: FAB_USER_ROLE,
        KC_VIEWER_ROLE: FAB_VIEWER_ROLE,
    }
    return list(set(team_role_map.get(team, FAB_PUBLIC_ROLE) for team in team_list))


class KeycloakAuthRemoteUserView(AuthOAuthView):

    @expose("/logout/")
    def logout(self):
        logout_user()
        return redirect(os.getenv("OAUTH_LOGOUT_REDIRECT_URL"))
# OAUTH_LOGOUT_REDIRECT_URL = "https://kc.example.com/realms/myrealm/protocol/openid-connect/logout?client_id=airflow&post_logout_redirect_uri=https%3A%2F%2Fairflow.example.com%2F"

class KeycloakRoleAuthorizer(FabAirflowSecurityManagerOverride):

    authoauthview  = KeycloakAuthRemoteUserView

    def get_oauth_user_info(self, provider: str, resp: Any) -> dict:
        access_token = resp.get('access_token')
        #log.info(f"Token: {access_token}")
        token_data = jwt.decode(access_token, options={"verify_signature": False})
        #log.info(f"Token data: {token_data}")
        roles = map_roles(token_data['realm_access']['roles'])
        return {'username': token_data.get('preferred_username'),
                'first_name': token_data.get('given_name'),
                'last_name': token_data.get('family_name'),
                'email': token_data.get('email'),
                'role_keys': roles}
```

用于调试，提高日志等级

```python
# Flask appbuilder's info level log is very verbose,
# so it's set to 'WARN' by default.
FAB_LOG_LEVEL: str = conf.get_mandatory_value("logging", "FAB_LOGGING_LEVEL").upper()
```

- <https://github.com/apache/airflow/blob/2.8.2/airflow/config_templates/airflow_local_settings.py#L34>
