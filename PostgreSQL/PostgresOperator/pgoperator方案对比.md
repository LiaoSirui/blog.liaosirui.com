## 目前主流的方案

- https://github.com/zalando/postgres-operator   Start 2.8k

- https://github.com/CrunchyData/postgres-operator    Start 3k

- https://github.com/percona/percona-postgresql-operator     Star 119

- https://github.com/radondb/radondb-postgresql-operator    Star 43

参考文档：https://blog.51cto.com/coderaction/5139303 （更新时间 2022-03-23）

原文：https://portworx.com/blog/choosing-a-kubernetes-operator-for-postgresql/

## 参考资料

postgres-operator 官方文档：https://postgres-operator.readthedocs.io/en/latest/

There is a browser-friendly version of this documentation at [postgres-operator.readthedocs.io](https://postgres-operator.readthedocs.io/)

* [How it works](https://github.com/zalando/postgres-operator/blob/master/docs/index.md)
* [Installation](https://github.com/zalando/postgres-operator/blob/master/docs/quickstart.md#deployment-options)
* [The Postgres experience on K8s](https://github.com/zalando/postgres-operator/blob/master/docs/user.md)
* [The Postgres Operator UI](https://github.com/zalando/postgres-operator/blob/master/docs/operator-ui.md)
* [DBA options - from RBAC to backup](https://github.com/zalando/postgres-operator/blob/master/docs/administrator.md)
* [Build, debug and extend the operator](https://github.com/zalando/postgres-operator/blob/master/docs/developer.md)
* [Configuration options](https://github.com/zalando/postgres-operator/blob/master/docs/reference/operator_parameters.md)
* [Postgres manifest reference](https://github.com/zalando/postgres-operator/blob/master/docs/reference/cluster_manifest.md)
* [Command-line options and environment variables](https://github.com/zalando/postgres-operator/blob/master/docs/reference/command_line_and_environment.md)

postgres 官方文档：https://www.postgresql.org/docs/

wal 官方文档：https://www.postgresql.org/docs/13/wal-intro.html

spilo 官方文档：https://github.com/zalando/spilo

| 术语、简写 | 含义                                                         |
| ---------- | ------------------------------------------------------------ |
| pg         | PostgreSQL 的缩写                                            |
| WAL        | Write-Ahead Logging，预写式日志，常用于数据恢复和数据副本，参考文档 |

## 功能简述

Postgres Operator 通过 Patroni 能够简单地在 Kubernetes(K8s) 上运行高可用的 PostgreSQL 集群。仅通过 Postgres 清单文件（CRD）对其进行配置，以简化与自动CI / CD管道的集成，无需直接访问Kubernetes API，从而很简单地集成进自动化 CI/CD 流水线。

Spilo is currently evolving: Its creators are working on a Postgres operator that would make it simpler to deploy scalable Postgres clusters in a Kubernetes environment, and also do maintenance tasks. Spilo would serve as an essential building block for this. There is already a [Helm chart](https://github.com/kubernetes/charts/tree/master/incubator/patroni) that relies on Spilo and Patroni to provision a five-node PostgreSQL HA cluster in a Kubernetes+Google Compute Engine environment. (The Helm chart deploys Spilo Docker images, not just "bare" Patroni.)


Here is a diagram, that summarizes what would be created by the operator, when a new Postgres cluster CRD is submitted:

下图概述了当提交一个新的 Postgres CRD时，operator 将创建什么。