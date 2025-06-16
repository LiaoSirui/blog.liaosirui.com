## Grafana Operator

- <https://github.com/grafana/grafana-operator>

## CRD

| 名称           | 组                           | 最新版本 | NamespaceScoped |
| -------------- | ---------------------------- | -------- | --------------- |
| Grafana | `integreatly.org` | v1alpha1 | √              |
| GrafanaDashboard | `integreatly.org` | v1alpha1 | √              |
| GrafanaDataSource | `integreatly.org` | v1alpha1 | √              |
| GrafanaFolder | `integreatly.org` | v1alpha1 | √              |
| GrafanaNotificationChannel | `integreatly.org` | v1alpha1 | √ |

### GrafanaDataSource

在创建面板之前我们需要指定我们的面板数据来源，也就是数据源，Grafana 支持多种数据源

在 HTTP 项中配置 URL 地址为 `http://vmselect-vmcluster:8481/select/10001/prometheus`，其实就是 Prometheus 的地址（这里是使用 VictoriaMetrics）

```yaml
apiVersion: integreatly.org/v1alpha1
kind: GrafanaDataSource
metadata:
  name: vm-datasource
  namespace: grafana
  labels:
    grafana.enable: "true"
spec:
  name: middleware.yaml
  datasources:
    - name: Prometheus
      type: prometheus
      access: proxy
      url: http://vmselect-vmcluster:8481/select/10001/prometheus
      isDefault: true
      version: 1
      editable: true
      jsonData:
        tlsSkipVerify: true
        timeInterval: "5s"

```
