
## 简介

Grafana 是一个监控仪表系统，它是由 Grafana Labs 公司开源的的一个系统监测工具，它可以大大帮助我们简化监控的复杂度，我们只需要提供需要监控的数据，它就可以帮助生成各种可视化仪表，同时它还有报警功能，可以在系统出现问题时发出通知。

## 数据源

Grafana 支持许多不同的数据源，每个数据源都有一个特定的查询编辑器，每个数据源的查询语言和能力都是不同的。

我们可以把来自多个数据源的数据组合到一个仪表板，但每一个面板被绑定到一个特定的数据源。

官方文档：<https://grafana.com/docs/grafana/latest/datasources/>

目前官方支持以下数据源：

- Alertmanager
- AWS CloudWatch
- Azure Monitor
- Elasticsearch
- Google Cloud Monitoring
- Graphite
- InfluxDB
- Loki
- Microsoft SQL Server (MSSQL)
- MySQL
- OpenTSDB
- PostgreSQL
- Prometheus
- Jaeger
- Zipkin
- Tempo
- Testdata

## 安装

Grafana 本身是非常轻量级的，不会占用大量资源。

此外 Grafana 需要一个数据库来存储其配置数据，比如用户、数据源和仪表盘等，目前 Grafana 支持 SQLite、MySQL、PostgreSQL 3 种数据库，默认使用的是 SQLite，该数据库文件会存储在 Grafana 的安装位置，所以需要对 Grafana 的安装目录进行持久化。

从配置文件中可以找到 Grafana 的各种数据配置路径，比如数据目录、日志目录、插件目录等等，正常启动完成后 Grafana 会监听在 3000 端口上，所以我们可以在浏览器中打开 Grafana 的 WebUI。

![grafana-login.png](.assets/grafana-login.png)

默认的用户名和密码为 admin，也可以在配置文件 `/etc/grafana/grafana.ini` 中配置 admin_user 和 admin_password 两个参数来进行覆盖。

## 高可用版本

如果想要部署一个高可用版本的 Grafana 的话，那么使用 SQLite 数据库就不行，需要切换到 MySQL 或者 PostgreSQL。

可以在 Grafana 配置的 `[database]` 部分找到数据库的相关配置，Grafana 会将所有长期数据保存在数据库中，然后部署多个 Grafana 实例使用同一个数据库即可实现高可用。

![grafana-ha.png](.assets/grafana-ha.png)

## uid 和 gid

需要注意的是 Changelog 中 v5.1.0 版本的更新介绍：

```text
Major restructuring of the container
Usage of chown removed
File permissions incompatibility with previous versions
user id changed from 104 to 472
group id changed from 107 to 472
Runs as the grafana user by default (instead of root)
All default volumes removed
```

## 使用 helm chart 进行安装

添加仓库

```bash
helm repo add grafana https://grafana.github.io/helm-charts
```

查看最新的版本

```bash
> helm search repo grafana  

grafana/grafana                                 6.52.4          9.4.3                   The leading tool for querying and visualizing t...
grafana/grafana-agent                           0.10.0          v0.32.1                 Grafana Agent                                     
grafana/grafana-agent-operator                  0.2.14          0.32.1                  A Helm chart for Grafana Agent Operator           
grafana/enterprise-logs                         2.4.3           v1.5.2                  Grafana Enterprise Logs                           
grafana/enterprise-logs-simple                  1.2.1           v1.4.0                  DEPRECATED Grafana Enterprise Logs (Simple Scal...
grafana/enterprise-metrics                      1.9.0           v1.7.0                  DEPRECATED Grafana Enterprise Metrics             
grafana/fluent-bit                              2.4.0           v2.1.0                  Uses fluent-bit Loki go plugin for gathering lo...
grafana/loki                                    4.10.0          2.7.5                   Helm chart for Grafana Loki in simple, scalable...
grafana/loki-canary                             0.11.0          2.7.4                   Helm chart for Grafana Loki Canary                
grafana/loki-distributed                        0.69.9          2.7.4                   Helm chart for Grafana Loki in microservices mode 
grafana/loki-simple-scalable                    1.8.11          2.6.1                   Helm chart for Grafana Loki in simple, scalable...
grafana/loki-stack                              2.9.9           v2.6.1                  Loki: like Prometheus, but for logs.              
grafana/mimir-distributed                       4.3.0           2.7.1                   Grafana Mimir                                     
grafana/mimir-openshift-experimental            2.1.0           2.0.0                   Grafana Mimir on OpenShift Experiment             
grafana/oncall                                  1.2.6           v1.2.6                  Developer-friendly incident response with brill...
grafana/phlare                                  0.5.3           0.5.1                   🔥 horizontally-scalable, highly-available, mul...
grafana/promtail                                6.9.3           2.7.4                   Promtail is an agent which ships the contents o...
grafana/rollout-operator                        0.4.0           v0.4.0                  Grafana rollout-operator                          
grafana/synthetic-monitoring-agent              0.1.0           v0.9.3-0-gcd7aadd       Grafana's Synthetic Monitoring application. The...
grafana/tempo                                   1.0.2           2.0.1                   Grafana Tempo Single Binary Mode                  
grafana/tempo-distributed                       1.2.7           2.0.1                   Grafana Tempo in MicroService mode                
grafana/tempo-vulture                           0.2.1           1.3.0                   Grafana Tempo Vulture - A tool to monitor Tempo...
prometheus-community/kube-prometheus-stack      45.8.1          v0.63.0                 kube-prometheus-stack collects Kubernetes manif...
prometheus-community/prometheus-druid-exporter  1.0.0           v0.11.0                 Druid exporter to monitor druid metrics with Pr...
```

拉取最新版本

```bash
helm pull grafana/grafana --version 6.52.4

# 下载并解压
helm pull grafana/grafana --version 6.52.4 --untar
```

新建 pv

```yaml
kind: PersistentVolume
apiVersion: v1
metadata:
  annotations:
    pv.kubernetes.io/provisioned-by: beegfs.csi.netapp.com
  name: grafana-data
  labels:
    app.kubernetes.io/instance: grafana
    app.kubernetes.io/name: grafana
spec:
  capacity:
    storage: 100Gi
  csi:
    driver: beegfs.csi.netapp.com
    volumeHandle: 'beegfs://10.244.244.201/app-data/grafana'
    volumeAttributes:
      storage.kubernetes.io/csiProvisionerIdentity: 1680159721626-8081-beegfs.csi.netapp.com
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  volumeMode: Filesystem
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: grafana-data
  namespace: grafana
  labels:
    app.kubernetes.io/instance: grafana
    app.kubernetes.io/name: grafana
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Gi
  volumeMode: Filesystem
  selector:
    matchLabels:
      app.kubernetes.io/instance: grafana
      app.kubernetes.io/name: grafana

```

使用如下 values.yaml

```yaml
service:
  enabled: true
  type: LoadBalancer
  loadBalancerIP: 10.244.244.151
  allocateLoadBalancerNodePorts: false # not work here
  port: 3000

tolerations:
  - operator: Exists

nodeSelector:
  kubernetes.io/hostname: devmaster

persistence:
  type: pvc
  enabled: true
  existingClaim: grafana-data
  # storageClassName: csi-beegfs-hdd

adminUser: admin
adminPassword: abcd1234!

```

安装

```yaml
helm upgrade --install grafana  \
    --namespace grafana \
    --create-namespace \
    -f ./values.yaml \
    grafana/grafana --version 6.52.4
```

查看密码

```bash
kubectl get secret --namespace grafana grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

## 参考资料

- <https://cloud.tencent.com/developer/article/2192174?from_column=20421&from=20421>
