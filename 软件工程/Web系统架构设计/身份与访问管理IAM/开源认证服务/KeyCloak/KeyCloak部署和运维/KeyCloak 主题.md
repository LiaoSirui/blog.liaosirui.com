## 自定义登录页面

Keycloak 将前端页面分为四类：按类设置主题

- Account - Account management
- Admin - Admin console
- Email - Emails
- Login - Login forms，包含注册

## 主题 Themes 配置

可以为不同的 Realm（域） 分别设置主题

1. 进入keycloak管理控制台
2. 选择要配置主题的 Realm
3. 进入Realm Settings 页面
4. 选择 Themes 选项卡

keycloak 默认提供了两套主题，base 和 keycloak

- Base 是没有加入任何样式的。

- Keycloak 加入了个性化的样式

## 创建自己的主题

一个主题由以下文件组成：

```bash
HTML templates (Freemarker Templates)
Images
Message bundles -- 国际化使用
Stylesheets
Scripts
Theme properties  （每种主题类型都需要一个theme.properties文件，用于设置主题的属性）
```

主题属性有：

- parent - Parent theme to extend
- import - Import resources from another theme
- styles - Space-separated list of styles to include
- locales - Comma-separated list of supported locales

继承一个主题后，可以重写父主题的所有资源

## 其他

keycloakify: 提供一种自定义 Keycloak 登录并使用 React 注册页面的方法，官方：<https://github.com/keycloakify/keycloakify>