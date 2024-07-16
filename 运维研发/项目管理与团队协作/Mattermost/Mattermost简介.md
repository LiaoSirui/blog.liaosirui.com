## Mattermost 简介

Mattermost 是一个 Slack 的开源替代品，用于跨团队和工具的安全通信、协作和工作编排。它为团队带来跨 PC 和移动设备的消息、文件分享、应用程序集成以及归档和搜索功能。

Mattermost 是为开发团队推动创新而构建的开源消息传递平台。支持私有云部署在不牺牲隐私的情况下提供了现代通信的优势。Mattermost 为企业提供了自治能力和可扩展性，使他们能够在满足需求的同时提高生产力 IT 和安全团队的要求

## 部署文档

Mattermost 是服务器端命令，mmctl 基于 API 的客户端命令

Docker 部署：<https://docs.mattermost.com/install/install-docker.html#>

部署文件：

- <https://github.com/mattermost/docker/blob/main/docker-compose.yml>

初始化：

- 系统控制台 【SITE CONFIGURATION】>【Users and Teams】> 【Max Users Per Team】值来设置团队人数
- 登录 Mattermost 控制台，打开：【ENVIRONMENT】>【Web Server】，修改 【Site URL】值
- 配置 SMTP，登录 Mattermost控制台，打开【ENVIROMENT】>【SMTP】
- 支持多语言（包含中文），可以登录控制台，通过【SITE CONFIGURATION】>【Localization】设置语言

推荐的插件：

- jitmi

## Hack

参考：<https://i.urox.cn/2020-05-10-i-learned-assembly-language.html>

![image-20240715155703006](./.assets/Mattermost简介/image-20240715155703006.png)

![image-20240715155713178](./.assets/Mattermost简介/image-20240715155713178.png)

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