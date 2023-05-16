官方：

- 官网：<https://www.metabase.com/>
- 文档：<https://www.metabase.com/docs/latest/>
- GitHub 仓库：<https://github.com/metabase/metabase>

## Metabase 部署

### Helm chart 部署

添加仓库和安装

```bash
helm repo add pmint93 https://pmint93.github.io/helm-charts

helm install my-metabase pmint93/metabase --version 2.7.0

```

代码仓库：<https://github.com/pmint93/helm-charts/tree/master/charts/metabase>