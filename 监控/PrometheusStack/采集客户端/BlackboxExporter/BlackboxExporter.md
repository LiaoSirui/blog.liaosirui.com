## Blackbox Exporter 简介

Blackbox Exporter 是 Prometheus 的一个可选组件，像其他 Exporter 一样， 主要用于将监控数据转换为 Prometheus 可理解的指标格式

### Endpoint 监控

Endpoint 监控是指监控内部和外部 Endpoint（HTTP/S、DNS、TCP、ICMP 和 grpc）的各种参数，包括 HTTP 响应时间、DNS 查询延迟、SSL 证书过期信息、TLS 版本等等

在 Kubernetes 中，不仅仅是外部 Endpoint 需要被监控，内部 Endpoint 也需要被监控响应时间和其他参数。这些指标是基础设施的一个重要部分，以确保服务的连续性、可用性和符合一些安全认证

### 白盒（WhiteBox）与黑盒（Blackbox）监控

白盒监控是指对系统内部的监控，包括应用 logging、handlers、tracing 和 metrics。与之相对，黑盒监控主要从外部发起探测，探测影响用户的行为，如服务器停机、页面不工作或网站性能下降

### Blackbox Exporter

Blackbox Exporter 用于探测 HTTPS、HTTP、TCP、DNS、ICMP 和 grpc 等 Endpoint。在你定义 Endpoint 后，Blackbox Exporter 会生成指标，可以使用 Grafana 等工具进行可视化。Blackbox Exporter 最重要的功能之一是测量 Endpoint 的可用性

![img](./.assets/BlackboxExporter/3a8aac9195094d4dd586eb0b2c404003-exporter.png)

## Blackbox 基本配置

下面是 Blackbox Exporter 配置中定义的一个默认模块：

```yaml
modules:
  http_2xx:
    prober: http
    timeout: 15s  
    http:
      fail_if_not_ssl: true
      ip_protocol_fallback: false
      method: GET
      follow_redirects: true
      preferred_ip_protocol: ip4
      valid_http_versions:
        - HTTP/1.1
        - HTTP/2.0
      valid_status_codes:
        - 200
        - 204
```

`module` 和 `http` probe 的配置：

- `prober`: 探测的协议（可以是：http, tcp, dns, icmp, grpc）。
- `timeout`: 探测超时时间。
- `http`: http probe

http probe 的配置：

- `valid_status_codes: <int>, ... | default = 2xx`: 该 Probe 可接受的状态码。默认为 2xx。建议使用默认值。
- `valid_http_versions`: 该 Probe 接受的 http 版本。可选值：`HTTP/1.1` `HTTP/2.0`
- `method: <string> | default = "GET"`: probe 使用的 http method
- `headers:` probe 使用的 header, 比如可以加一些 `user-agent` 之类的 header 避免被 WAF 拦截
- `body_size_limit: <size> | default = 0` 将被处理的最大未压缩的主体长度（字节）。值为 0 意味着没有限制。
- `compression`: 用于解压响应的压缩算法（gzip、br、deflate、ident）。
- `follow_redirects: <boolean> | default = true`: 是否 follow 重定向
- `fail_if_ssl`: 如果存在 SSL，则探测失败
- `fail_if_not_ssl`: 如果不存在 SSL, 则探测失败
- `fail_if_body_matches_regexp`: 如果返回的 body 匹配该正则则失败
- `fail_if_body_not_matches_regexp`: 如果返回的 body 不匹配该正则则失败
- `fail_if_header_matches`: 如果返回的 header 匹配该正则，则失败。对于有多个值的 header，如果 **至少有一个** 符合，则失败。
- `fail_if_header_not_matches`: 如果返回的 header 不匹配该正则，则失败。
- `tls_config`: HTTP probe 的 TLS 协议配置，常用于私人证书。
- `basic_auth`: 目标的 HTTP basic auth 凭证。
- `bearer_token: <secret>`: 模板的 bearer token.
- `proxy_url` 用于连接到目标的 proxy server 的配置
- `skip_resolve_phase_with_proxy` 当设置了 HTTP 代理（proxy_url）时，跳过 DNS 解析和 URL 变更。
- `oauth2` 用于连接到模板的 OAuth 2.0 配置
- `enable_http2` 是否启用 http2
- `preferred_ip_protocol` HTTP probe 的 IP 协议 (ip4, ip6)
- `ip_protocol_fallback`
- `body` probe 中使用的 HTTP 请求的主体

## Prometheus 中的配置

直接通过 `probe` CRD 来配置

```yaml
apiVersion: monitoring.coreos.com/v1
kind: Probe
metadata:
  name: probe
  namespace: monitoring
spec:
  jobName: http-get
  interval: 60s
  module: http_2xx
  prober:
    url: prometheus-blackbox-exporter.monitoring:9115
    scheme: http
    path: /probe
  targets:
    staticConfig:
      static:
        - https://baidu.com
      labels:
        domain: baidu
```

## 指标

`probe_` 的指标列表

| 指标名                                  | 功能                                            |
| --------------------------------------- | ----------------------------------------------- |
| `probe_duration_seconds`                | 返回探针完成的时间（秒）。                      |
| `probe_http_status_code`                | 响应 HTTP 状态代码                              |
| `probe_http_version`                    | 返回探针响应的 HTTP 版本                        |
| `probe_success`                         | 显示探测是否成功                                |
| `probe_dns_lookup_time_seconds`         | 返回探测 DNS 的时间，单位是秒。                 |
| `probe_ip_protocol`                     | 指定探针 IP 协议是 IP4 还是 IP6                 |
| `probe_ssl_earliest_cert_expiry metric` | 返回以 unixtime 为单位的最早的 SSL 证书到期时间 |
| `probe_tls_version_info`                | 包含所使用的 TLS 版本                           |
| `probe_failed_due_to_regex`             | 表示探测是否因 regex 匹配而失败                 |
| `probe_http_content_length`             | HTTP 内容响应的长度                             |

## Dashboard

- 13230 SSL证书监控 <https://grafana.com/grafana/dashboards/13230-certificate-monitor/>
- 13659 HTTP状态监控 <https://grafana.com/grafana/dashboards/13659-blackbox-exporter-http-prober/>

- 9965 SSL TCP HTTP 综合监控图标

## AlertManager 告警

- SSL 证书小于 30 天发送告警
- HTTP 状态非 200 告警

```yaml
groups:
    - name: Blackbox 监控告警
      rules:
      - alert: BlackboxSlowProbe
        expr: avg_over_time(probe_duration_seconds[1m]) > 1
        for: 30m
        labels:
          severity: warning
        annotations:
          summary: telnet (instance {{ $labels.instance }}) 超时1秒
          description: "VALUE = {{ $value }}n  LABELS = {{ $labels }}"
      - alert: BlackboxProbeHttpFailure
        expr: probe_http_status_code <= 199 OR probe_http_status_code >= 400
        for: 30m
        labels:
          severity: critical
        annotations:
          summary: HTTP 状态码 (instance {{ $labels.instance }})
          description: "HTTP status code is not 200-399n  VALUE = {{ $value }}n  LABELS = {{ $labels }}"
      - alert: BlackboxSslCertificateWillExpireSoon
        expr: probe_ssl_earliest_cert_expiry - time() < 86400 * 30
        for: 30m
        labels:
          severity: warning
        annotations:
          summary:  域名证书即将过期 (instance {{ $labels.instance }})
          description: "域名证书30天后过期n  VALUE = {{ $value }}n  LABELS = {{ $labels }}"
      - alert: BlackboxSslCertificateWillExpireSoon
        expr: probe_ssl_earliest_cert_expiry - time() < 86400 * 7
        for: 30m
        labels:
          severity: critical
        annotations:
          summary: 域名证书即将过期 (instance {{ $labels.instance }})
          description: "域名证书7天后过期n VALUE = {{ $value }}n  LABELS = {{ $labels }}"
      - alert: BlackboxSslCertificateExpired
        expr: probe_ssl_earliest_cert_expiry - time() <= 0
        for: 30m
        labels:
          severity: critical
        annotations:
          summary: 域名证书已过期 (instance {{ $labels.instance }})
          description: "域名证书已过期n  VALUE = {{ $value }}n  LABELS = {{ $labels }}"
      - alert: BlackboxProbeSlowHttp
        expr: avg_over_time(probe_http_duration_seconds[1m]) > 10
        for: 30m
        labels:
          severity: warning
        annotations:
          summary: HTTP请求超时 (instance {{ $labels.instance }})
          description: "HTTP请求超时超过10秒n  VALUE = {{ $value }}n  LABELS = {{ $labels }}"
```

