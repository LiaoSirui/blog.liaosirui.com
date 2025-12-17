## 简介

官方：

- GitHub 仓库：<https://github.com/kubernetes-sigs/external-dns>
- 文档：<https://kubernetes-sigs.github.io/external-dns/latest/>

Helm Chart

```bash
helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/
```

## 阿里云配置

参考文档：<https://kubernetes-sigs.github.io/external-dns/v0.20.0/docs/tutorials/alibabacloud/>

```yaml
provider:
  name: alibabacloud

secretConfiguration:
  enabled: true
  mountPath: /etc/kubernetes/alibaba-cloud.json
  subPath: alibaba-cloud.json
  data:
    alibaba-cloud.json: |
      {
        "accessKeyId": "",
        "accessKeySecret": "",
        "zoneType": "public"
      }

```

通过 Service 创建域名解析

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx
  annotations:
    external-dns.alpha.kubernetes.io/hostname: external-dns-test.alpha-quant.tech
spec:
    ...

```

示例

```yaml
kind: Service
apiVersion: v1
metadata:
  name: dns
  annotations:
    external-dns.alpha.kubernetes.io/hostname: external-dns-test.alpha-quant.tech
spec:
  type: ExternalName
  externalName: baidu.com

```

