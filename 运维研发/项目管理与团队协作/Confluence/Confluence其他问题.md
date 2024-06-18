## PDF 导出中文失败

安装 PDF 导出中文字体

![Confluence PDF导出中文支持_Confluence](./.assets/Confluence其他问题/resize,m_fixed,w_1184)

- <https://github.com/chengda/popular-font>

## 开启插件上传

- 开启上传插件：<https://confluence.atlassian.com/conf85/managing-system-and-marketplace-apps-1283360882.html>

```
Option 1: Re-enable the UI upload button and API

Set the system property upm.plugin.upload.enabled to true.
Perform a restart.
Upload the app through the UPM UI.
We recommend that you disable the button once your upload is complete, using the additional steps below.

Set the system property upm.plugin.upload.enabled to false,

Perform a restart.

Option 2: Load custom plugins from your Confluence file system

 If the system property atlassian.confluence.plugin.scan.directory is not set, provide the target location of your custom plugins. We recommend a directory within the Confluence home directory, such as $CONFLUENCE_HOME/plugins/installed-plugins.

Restart Confluence.
```

修改系统属性，详见：<https://confluence.atlassian.com/conf88/configuring-system-properties-1354500668.html>
