Mattermost 是为开发团队推动创新而构建的开源消息传递平台。支持私有云部署在不牺牲隐私的情况下提供了现代通信的优势。Mattermost 为企业提供了自治能力和可扩展性，使他们能够在满足需求的同时提高生产力 IT 和安全团队的要求

## Jira 集成

第一步：mattermost 上开启 jira 插件

启用插件，选择 “true”

复制 webhook secret 中的文本，组成 URL，例如

```
https://SITEURL/plugins/jira/api/v2/webhook?secret=YB96EBo3lBFfcqTnGItFeSVtTLj0Cy81
```

第二步：在jira配置webhook

系统 >> 网络钩子

输入名称、第一步获取到的URL，并把勾选上需要的事件

第三步：在 jira 上安装应用程序

在 mattermost 的聊天框中，输入 `/jira install` ，可以看到下面的信息

根据提示在 JIRA上进行配置，尤其注意 PUBLIC KEY 的部分

## 参考文档

- <https://cloud.tencent.com/developer/article/1639840>