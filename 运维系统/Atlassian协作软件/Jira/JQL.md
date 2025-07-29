## 特定周内已解决的工单数量

使用 Jira 的 JQL 语言，可以通过以下代码语句来查询特定周内已解决的工单数量：

```jql
project = "项目名称" AND resolutiondate >= "起始时间" AND resolutiondate <= "结束时间" AND status = "已解决"
```

其中，需要将"项目名称"替换为对应项目的名称，"起始时间"替换为查询的特定周的起始时间，"结束时间"替换为查询的特定周的结束时间。

例如，查询2019年第1周（1月1日至1月6日）已解决的工单数量：

```jql
project = "项目名称" AND resolutiondate >= "2019-01-01" AND resolutiondate <= "2019-01-06" AND status = "已解决"
```

