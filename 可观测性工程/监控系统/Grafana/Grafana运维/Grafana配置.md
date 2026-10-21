## 设置主页

1. 通过单击仪表板标题旁边的星号为该仪表板加星
2. 在左侧菜单上，将光标停留在 Configuration (齿轮)图标上，然后单击 Preferences 。
3. 首选项页面有 3 个指标可以进行修改，分别是 UI 主题、Home Dashboards、Timezone（时区），我们选择 Home Dashboards 进行修改，选择之前编辑好的 Dashboards，这里只显示加星的 Dashboards ，所以第一步要对 Dashboards 进行加星。

这个页面需要提前准备好，在 `/usr/share/grafana/public/dashboards` 目录下，将之前 `home.json` 备份，将准备好的 json 文件替换成 `home.json` 即可
## run-grafana-behind-a-proxy

- run-grafana-behind-a-proxy：<https://grafana.com/tutorials/run-grafana-behind-a-proxy/>

Grafana 配置 domain

```ini
[server]
domain = example.com
```

如果需要配置子路径

```ini
[server]
domain = example.com
root_url = %(protocol)s://%(domain)s:%(http_port)s/grafana/
serve_from_sub_path = true
```

## Oauth

```ini
role_attribute_path = "contains(name, 'adm') && 'Admin' || contains(roles[*], 'admin') && 'Admin' || contains(roles[*], 'editor') && 'Editor' || 'Viewer'"
```

其他配置

```ini
[auth.generic_oauth]
# ..
# prevents the sync of org roles from the Oauth provider
skip_org_role_sync = true

```
