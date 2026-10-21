
## 简介

对于 VictoriaMetrics 官方也开发了一个对应的 Operator 来进行管理 - vm-operator，它的设计和实现灵感来自 prometheus-operator，它是管理应用程序监控配置的绝佳工具。

vm-operator 定义了如下一些 CRD：

- `VMServiceScrape`：定义从 Service 支持的 Pod 中抓取指标配置
- `VMPodScrape`：定义从 Pod 中抓取指标配置
- `VMRule`：定义报警和记录规则
- `VMProbe`：使用 blackbox exporter 为目标定义探测配置

此外该 Operator 默认还可以识别 prometheus-operator 中的 `ServiceMonitor`、`PodMonitor`、`PrometheusRule` 和 `Probe` 对象，还允许你使用 CRD 对象来管理 Kubernetes 集群内的 VM 应用。

## 部署类

| 名称           | 组                           | 最新版本 | NamespaceScoped |
| -------------- | ---------------------------- | -------- | --------------- |
| VMSingle       | `operator.victoriametrics.com` | v1beta1  | √               |
| VMCluster      | `operator.victoriametrics.com` | v1beta1  | √               |
| VMAgent        | `operator.victoriametrics.com` | v1beta1  | √               |
| VMAlertmanager | `operator.victoriametrics.com` | v1beta1  | √               |

### VMSingle

### VMCluster

### VMAgent

### VMAlertmanager

## 监控采集

| 名称            | 组                           | 最新版本 | NamespaceScoped |
| --------------- | ---------------------------- | -------- | --------------- |
| VMServiceScrape | `operator.victoriametrics.com` | v1beta1  | √               |
| VMPodScrape     | `operator.victoriametrics.com` | v1beta1  | √               |
| VMNodeScrape    | `operator.victoriametrics.com` | v1beta1  | √               |
| VMStaticScrape  | `operator.victoriametrics.com` | v1beta1  | √               |
| VMProbe         | `operator.victoriametrics.com` | v1beta1  | √               |

## 告警

| 名称                 | 组                           | 最新版本 | NamespaceScoped |
| -------------------- | ---------------------------- | -------- | --------------- |
| VMAlert              | `operator.victoriametrics.com` | v1beta1  | √               |
| VMRule               | `operator.victoriametrics.com` | v1beta1  | √               |
| VMAlertmanagerConfig | `operator.victoriametrics.com` | v1beta1  | √               |

## 认证管理

| 名称                 | 组                           | 最新版本 | NamespaceScoped |
| -------------------- | ---------------------------- | -------- | --------------- |
| VMAuth               | `operator.victoriametrics.com` | v1beta1  | √               |
| VMUser               | `operator.victoriametrics.com` | v1beta1  | √               |
