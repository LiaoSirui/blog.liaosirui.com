## 基本设置

当前站点

- 站点链接：按实际配置

- 文档链接：按实际配置

- 支持链接：<https://mattermost.alpha-quant.tech/alpha-quant/channels/jumpserver>

## 认证设置

LDAP

- 服务端地址：`ldap://ldap.alpha-quant.tech:389`

- 绑定 DN：`administrator@alpha-quant.tech`

- 用户 OU：`DC=alpha-quant,DC=tech`

- 用户过滤器：`(&(objectCategory=Person)(sAMAccountName=%(user)s)(memberOf=CN=lk-group-ops,OU=View Users,OU=View Group,DC=alpha-quant,DC=tech))`

- 属性映射
  ```json
  {
    "username": "cn",
    "name": "sn",
    "email": "mail"
  }
  
  # or
  
  {
    "username": "sAMAccountName",
    "name": "cn",
    "email": "mail"
  }
  ```

  