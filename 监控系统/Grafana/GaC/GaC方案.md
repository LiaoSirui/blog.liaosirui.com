## GaC

GaC(Grafana as Code, Grafana 即代码)

Grafana 即代码 (Grafana as Code, GaC) 是指通过代码而不是手动流程 / 控制台点击来管理和配置 Grafana

Grafana 是被管理对象

## 可选方案

官方 blog：

- <https://grafana.com/docs/grafana-cloud/developer-resources/infrastructure-as-code/>
- <https://grafana.com/docs/grafana/latest/observability-as-code/get-started/>

### Grafonnet

- <https://github.com/grafana/grafonnet>

### Grafana Terraform provider

基于 Terraform 的 Grafana Terraform provider

- <https://registry.terraform.io/providers/grafana/grafana/latest>

- <https://grafana.com/docs/grafana-cloud/developer-resources/infrastructure-as-code/terraform/>

示例

```jsonnet
resource "grafana_dashboard" "metrics" {
  config_json = jsonencode({
    title   = "as-code dashboard"
    uid     = "ascode"
  })
}
```

### Grafana Ansible collection

基于 Ansible 的 Grafana Ansible collection

- <https://github.com/grafana/grafana-ansible-collection>

- <https://galaxy.ansible.com/community/grafana>

安装

```bash
ansible-galaxy collection install community.grafana
```

使用示例

```yaml
- name: dashboard as code
  grafana.grafana.dashboard:
    dashboard: {
      "title": "as-code dashboard",
      "uid": "ascode"
    }
    stack_slug: "{{ stack_slug }}"
    grafana_api_key: "{{ grafana_api_key }}"
    state: present
```

### Kubernetes Grafana Operator

Grafana Operator 是一个 Kubernetes Operator，用于配置和管理 Grafana 及其使用 Kubernetes CR 的资源。它是一个由 Grafana 社区建立的 Kubernetes 原生解决方案。它还可以把在 Grafonnet 中构建的仪表盘作为仪表盘配置的来源。

- <https://github.com/grafana-operator/grafana-operator>

使用 Grafana Operator 创建仪表盘的 Kubernetes 配置示例

```yaml

apiVersion: integreatly.org/v1alpha1
kind: GrafanaDashboard
metadata:
  name: simple-dashboard
  labels:
    app: grafana
spec:
  json: >
    {
      "title": "as-code dashboard",
      “uid” : “ascode”
    }
```

### 基于 API 的定制化开发

官方 API：

- Grafana API，<https://grafana.com/docs/grafana/latest/developers/http_api/>，最底层的 API 接口
- grafana-api-golang-client，https://github.com/grafana/grafana-api-golang-client，基于 Grafana API 的低级别的 golang 客户端，也是 Grafana Terraform provider 的底层实现，示例 <https://github.com/grafana/grafana-api-golang-client/blob/master/dashboard_test.go>

如果使用 Grafana API, 创建 Dashboard 的示例如下

```bash
POST /api/dashboards/db HTTP/1.1
Accept: application/json
Content-Type: application/json
Authorization: Bearer eyJrIjoiT0tTcG1pUlY2RnVKZTFVaDFsNFZXdE9ZWmNrMkZYbk

{
  "dashboard": {
    "id": null,
    "uid": null,
    "title": "Production Overview",
    "tags": [ "templated" ],
    "timezone": "browser",
    "schemaVersion": 16,
    "version": 0,
    "refresh": "25s"
  },
  "folderId": 0,
  "folderUid": "l3KqBxCMz",
  "message": "Made changes to xyz",
  "overwrite": false
}

```
