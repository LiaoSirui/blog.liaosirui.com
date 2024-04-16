单论 URL, 总结起来，Blackbox Exporter 有以下探测场景：

1. 探测外部 URL
2. 探测 K8S 集群内部 service
3. 探测 K8S 集群内部 Ingress
4. 探测 K8S 集群内部 Pod

## 场景一：探测外部 URL

### 监控证书

### ICMP 测试（主机探活）

```yaml
modules:
  icmp:
    prober: icmp

```

示例

```yaml
 - job_name: 'blackbox-ping'
    metrics_path: /probe
    params:
      modelus: [icmp]
    static_configs:
    - targets:
      - 172.16.106.208  #被监控端ip
      - 172.16.106.80
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: IP:9115  #blackbox-exporter 所在的机器和端口
```

### TCP 测试（监控主机端口存活状态）

```yaml
modules:
  tcp_connect:
    prober: tcp
```

示例

```yaml
  - job_name: 'blackbox-tcp'
    metrics_path: /probe
    params:
      modelus: [tcp_connect]
    static_configs:
    - targets:
      - 172.16.106.208:6443
      - 172.16.106.80:6443
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: IP:9115
```

### HTTP检测（监控网站状态）

```yaml
modules:
  http_2xx:
    prober: http
    http:
      method: GET
  http_post_2xx:
    prober: http
    http:
      method: POST

```

示例

```yaml
  - job_name: 'blackbox-http'
    metrics_path: /probe
    params:
      modelue: [http_2xx]
    static_configs:
    - targets:
      - https://i4t.com
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: IP:9115  #blackbox-exporter 所在的机器和端口
```



## 场景二：探测 K8S 集群内部 service

在 Kubernetes 系统中，资源和 Endpoint 会随着时间的推移而出现和消失，可以非常有用的探测是对资源的动态探测，包括 pods、service 和 ingress

可以实现 Endpoint 的动态探测。Kubernetes 服务发现配置允许从 Kubernetes 的 API 中获取刮削目标，并始终与集群状态保持同步。你可以在文档的 kubernetes_sd_config 部分找到可以配置为发现目标的可用角色列表

## 场景三：探测 K8S 集群内部 Ingress

## 场景四：探测 K8S 集群内部 Pod