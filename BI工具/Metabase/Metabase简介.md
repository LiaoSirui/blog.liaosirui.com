## Metabase 简介

metabase 是一款开源免费的 BI 工具，可以选择数据库进行展示，让不懂 SQL 的人员也可以很直接得了解到公司的业务数据的情况

免费 Metabase 是一个免费的开源工具，并且只要你赋予权限的人都可以自由浏览你的 Dashboards，虽然 Metabase 没有 Tableau 的功能多、支持的图表丰富

官方：

- 官网：<https://www.metabase.com/>
- 文档：<https://www.metabase.com/docs/latest/>
- GitHub 仓库：<https://github.com/metabase/metabase>

### 优缺点

优点：

- 开源免费
- 工具轻量、安装依赖的环境简单、配置简单清楚
- 容易上手，操作门槛低，不会 sql 语句也能使用
- 支持对外共享，权限控制
- Question 可以便捷地创建图表，Dashboards 界面整洁美观

缺点：

- Question 每次只能对数据库中的一张表进行查询，切换数据表已有的查询选项会重置
- 填写了 sql 语句的 sql 查询（Native query）模式不能转到点选查询（Custom）模式
- 不能在 Metabase 中自由转换数据表中字段的属性
- 可创建的图表类型较单一

## Metabase 部署

### Helm chart 部署

代码仓库：<https://github.com/pmint93/helm-charts/tree/master/charts/metabase>

其他可供参考的：<https://github.com/helm/charts/tree/master/stable/metabase>

添加仓库和安装

```bash
helm repo add pmint93 https://pmint93.github.io/helm-charts

helm install my-metabase pmint93/metabase --version 2.7.0

```

metabase 默认使用的 H2 数据库，生产环境不稳定，官方建议使用其他类型数据库，文档：<https://www.metabase.com/docs/latest/installation-and-operation/migrating-from-h2>

创建数据库

```sql
CREATE DATABASE `metabase` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
```

指定数据库类型

```bash
export MB_DB_TYPE=mysql
export MB_DB_DBNAME=metabase数据库
export MB_DB_PORT=mysql端口
export MB_DB_USER=mysql用户
export MB_DB_PASS=mysql密码
export MB_DB_HOST=mysql机器ip
```

其他推荐配置：<https://www.metabase.com/docs/latest/installation-and-operation/running-metabase-on-docker#additional-docker-maintenance-and-configuration>