初始化集群

```bash
sealos init \
  --master 10.237.113.14 \
  --version v1.18.20 \
  --pkg-url=/root/kube1.18.20.tar.gz \
  --podcidr=100.90.0.0/16

```

安装 nginx

```bash
sealos install --pkg-url=nginx-ingress_v1.20.tar
```

