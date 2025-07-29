## 配置过程

Mattermost 是为开发团队推动创新而构建的开源消息传递平台。支持私有云部署在不牺牲隐私的情况下提供了现代通信的优势。Mattermost 为企业提供了自治能力和可扩展性，使他们能够在满足需求的同时提高生产力 IT 和安全团队的要求

Mattermost 减少了在 Jira 进行项目合作的开发团队的摩擦。无缝集成使您可以在团队需要的地方发布 Jira 信息，以简化协作并快速解决问题。Mattermost 能够自定义用户希望查看的 Jira 通知，并让他们对这些通知采取行动，从而节省了时间和金钱。 Mattermost Jira 集成可确保在正确的时间将通知发送给正确的团队和人员，使他们能够在不离开 Mattermost 的情况下进行项目管理配置

配置：

- MatterMost 安装配置 Jira 插件

- 需要生成一个 webhook secret 用于后期触发配置

在 MatterMost 频道中输入 `/jira install server http://192.168.1.200:8050/` 会出现操作步骤说明

## 参考资料

- <https://cloud.tencent.com/developer/article/1639840>

- <https://support.atlassian.com/jira-service-management-cloud/docs/integrate-with-mattermost/>