## 安装

```bash
go install github.com/grafana/grafanactl/cmd/grafanactl@latest
```

## 配置 context

```bash
grafanactl config set contexts.staging.grafana.server http://127.0.0.1:3000
grafanactl config set contexts.staging.grafana.org-id 1
```

可选认证

```bash
# Authenticate with a service account token
grafanactl config set contexts.staging.grafana.token service-account-token

# Or use basic authentication
grafanactl config set contexts.staging.grafana.user admin
grafanactl config set contexts.staging.grafana.password changme
```

查看 context

```bash
grafanactl config list-contexts
```

切换 context

```bash
grafanactl config use-context staging
```

检查配置

```bash
grafanactl config check
```

查看配置

```bash
grafanactl config view
```

## 管理资源

获取资源

```bash
grafanactl resources pull -p ./resources/ -o yaml  # or json
```

推送资源

```bash
grafanactl resources push -p ./resources/
```

使用 Gac

```bash
grafanactl resources serve --script 'go run scripts/generate-dashboard.go' --watch './scripts'
```

