对于 helm chart 部署，可以指定如下：

```yaml
servers:
  - zones:
      - zone: .
    port: 53
    plugins:
      - name: errors
      - name: log
      // ...
```

即生成配置：

```yaml
Corefile: |
    .:53 {
        errors
        log // 此处添加Log插件。
        health {
           lameduck 5s
        }
        ready
        kubernetes cluster.local in-addr.arpa ip6.arpa {
          pods insecure
          upstream
          fallthrough in-addr.arpa ip6.arpa
          ttl 30
        }
        prometheus :9153
        forward . /etc/resolv.conf
        cache 30
        loop
        reload
        loadbalance
    }
  }
```

CoreDNS 接收到请求并回复客户端后会打印一行日志，示例如下：

```plain
# 其中包含状态码 RCODE NOERROR，代表解析结果正常返回

[INFO] 172.20.2.25:44525 - 36259 "A IN redis-master.default.svc.cluster.local. udp 56 false 512" NOERROR qr,aa,rd 110 0.000116946s
```

