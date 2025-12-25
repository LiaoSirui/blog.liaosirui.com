系统设置页面分为：基本设置、组织管理、消息通知、功能设置、认证设置、存储设置、组件设置、远程应用、安全设置、界面设置、系统工具、系统任务和许可证页面。

## 基本设置

当前站点

- 站点链接：按实际配置

- 文档链接：按实际配置

- 支持链接：<https://mattermost.alpha-quant.tech/alpha-quant/channels/jumpserver>

## 组织管理

JumpServer 支持分组织的管理方式，即不同的组织之间用户的权限、资产、权限等信息均隔离，方便管理员根据公司组织结构创建和查看不同组织环境下的信息

## 消息设置

- 邮箱
- SMS
- 消息订阅：配置监控告警信息、危险命令告警信息、批量危险命令告警等信息的接收人；消息订阅模式中默认只拥有“站内信”

## 功能设置

### 公告

配置后可以在页面首页显示公告内容

公告内容支持显示在SSH 方法连接堡垒机时显示，Markdown 语法的公告不支持正常展示在 SSH 页面

### 工单

工单设置资产授权的默认授权时间与时间单位

建议调整为 7h 这种较小时间

### 任务中心

可以设置是否允许用户使用 ansible 执行批量命令以及设置作业中心命令黑名单

按需开启

### 账号存储

开启账号存储 Valut 功能的配置项为：`VAULT_ENABLED=true`、`VAULT_HCP_HOST=hcp`

文档见：<https://www.jumpserver.com/docs/configuration#vault_enabled>

### 虚拟应用

开启以 Linux 系统为底层的虚拟应用功能

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
    "email": "mail",
    "groups": "memberOf"
  }
  
  # or
  
  {
    "username": "sAMAccountName",
    "name": "cn",
    "email": "mail",
    "groups": "memberOf"
  }
  ```
  

OIDC 登录，官方文档：<https://docs.jumpserver.org/zh/master/admin-guide/authentication/openid/>

## 存储设置

- 对象存储
  - 外部位置存储连接资产的会话录像
  - 可以设置 SFTP 存储对账号进行备份
- 命令存储
  - 支持外部 es 存储，将 JumpServer 连接资产产生的会话存储到外部，减少数据库的存储用量

## 组件设置

### 基本设置

由于使用 LDAP，关闭密钥认证，避免账号移除后仍可以登录系统

### 组件管理

点击某个组件的<更新>按钮或选择多个组件，点击更多操作可进行更新。更新组件的命令存储与录像存储，会话录像默认存放在服务器本地；会话命令默认存放在数据库中，这里可以更改会话录像与会话命令存储到外部存储。

### 服务端点

这里可以更改 core 显示的默认端口，例如修改 ssh 端口为 22

### 服务端点

服务端点是用户访问服务的地址(端口)，当用户在连接资产时，会根据端点规则和资产标签选择服务端点，作为访问入口建立连接，实现分布式连接资产

## 远程应用

- 创建应用发布机（应用发布机即一台干净的 Windows 服务器且安装了OpenSSH服务）

- 部署应用发布机（该步骤会安装默认的远程应用即 Chrome 与其他远程应用到应用发布机中）

- 创建 Web 页面资产与账号
- 访问

## 安全设置

### 认证安全

强制全局 MFA

### 登录限制

仅一台设备登录

### 会话安全

关闭会话分享

连接最大空闲时间（调大到 2h 是否安全？）

## 主题设置

不同的环境使用不同的主题，方便区分