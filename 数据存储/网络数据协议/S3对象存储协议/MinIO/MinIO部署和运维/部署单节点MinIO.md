## Helm 部署

添加 helm 仓库，源码在 <https://github.com/minio/minio/tree/master/helm/minio>

```bash
helm repo add minio https://charts.min.io
```

查看 minio 的最新版本

```bash
# helm search repo minio/

NAME       	CHART VERSION	APP VERSION                 	DESCRIPTION
minio/minio	5.3.0        	RELEASE.2024-04-18T19-09-19Z	High Performance Object Storage
```

拉取最新版本的 Chart

```bash
helm pull minio/minio --version 5.3.0

# 下载并解压
helm pull minio/minio --version 5.3.0 --untar
```

## Healthcheck

增加如下健康检查：

<https://github.com/minio/minio/blob/master/docs/metrics/healthcheck/README.md>

```yaml
livenessProbe:
  httpGet:
    path: /minio/health/live
    port: 9000
    scheme: HTTP
  initialDelaySeconds: 120
  periodSeconds: 30
  timeoutSeconds: 10
  successThreshold: 1
  failureThreshold: 3
readinessProbe:
  httpGet:
    path: /minio/health/ready
    port: 9000
    scheme: HTTP
  initialDelaySeconds: 120
  periodSeconds: 15
  timeoutSeconds: 10
  successThreshold: 1
  failureThreshold: 3
```
