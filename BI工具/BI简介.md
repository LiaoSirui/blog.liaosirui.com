## BI 简介

BI（BusinessIntelligence）即商业智能，它是一套完整的解决方案，用来将企业中现有的数据进行有效的整合，快速准确的提供报表并提出决策依据，帮助企业做出明智的业务经营决策

商业智能 BI 在数据架构中处于前端分析的位置，其核心作用是对获取数据的多维度分析、数据的切片、数据的上钻和下钻、cube 等。通过 ETL 数据抽取、转化形成一个完整的数据仓库、然后对数据仓库的数据进行抽取，而后是商业智能的前端分析和展示

BI 对个人来说就是个数据分析工具

## 主流开源 BI 产品对比

| 产品 \ 指标 | 定位                 | 数据源支持程度 | 可视化能力 | 文档质量 | 社区活跃度 | 什么场景下选择该产品        |
| ----------- | -------------------- | -------------- | ---------- | -------- | ---------- | --------------------------- |
| Superset    | BI 平台              | 丰富           | 很好       | 差       | 强         | 注重可视化效果              |
| Grafana     | BI 平台              | 一般           | 好         | 高       | 强         | 监控与日志分析              |
| Metabase    | BI 平台              | 一般           | 好         | 很差     | 强         | 业务人员探索数据            |
| Redash      | BI 平台              | 丰富           | 好         | 高       | 强         | 快速数据查询与可视化        |
| BIRT        | 报表工具             | 差             | 一般       | 很差     | 弱         | 简单报表需求                |
| CBoard      | BI 平台              | 一般           | 好         | 一般     | 一般       | 常规 BI 需求                |
| 润乾报表    | BI 平台 / 可集成组件 | 丰富           | 好         | 高       | 强         | 复杂报表 / 快速数据查询分析 |

### Superset

由 Airbnb 贡献的轻量级 BI 产品

Superset 提供了 Dashboard 和多维分析两大类功能，后者可以将制作的结果发布到 Dashboard 上也可以单独使用

数据源方面，Superset 支持 CSV、MySQL、Oracle、Redshift、Drill、Hive、Impala、Elasticsearch 等 27 种数据源，并深度支持 Druid

### Grafana

它的适用范围跟大多数 BI 产品不太一样，Grafana 主要用于对接时序数据库，分析展示监控数据。目前支持的数据源包括 InfluxDB、Elasticsearch、Graphite、Prometheus 等，同时也支持 MySQL、MSSQL、PG 等关系数据库

### Metabase

Metabase 也是一个完整的 BI 平台，Metabase 非常注重非技术人员（如产品经理、市场运营人员）在使用这个工具时的体验，让他们能自由地探索数据，回答自己的问题。而在 Superset 里，非技术人员基本上只能看预先建好的 Dashboard，不懂 SQL 或是数据库结构的他们，很难自己去摸索

数据源方面，Metabase 支持 Redshift、Druid、Google BigQuery、MongoDB、MySQL、PG 等 15 种数据源

### Redash

Redash 目标就是更纯粹地做好数据查询结果的可视化。Redash 支持很多种数据源，除了最常用的 SQL 数据库，也支持 MongoDB, Elasticsearch, Google Spreadsheet 甚至是一个 JSON 文件。目前 Redash 支持超过 35 种 SQL 和 NoSQL 数据源

### CBoard

国内由楚果主导的开源 BI 产品，分社区版和商业版。CBoard 提供了一个 BI 系统，包括 Dashboard、多维分析、任务调度等方面

数据源方面支持 JDBC 数据源、ElasticSearch、文本文件（文本需要存放于 CBoard 应用服务器上面，读取本地文件）、Saiku2.x 等

