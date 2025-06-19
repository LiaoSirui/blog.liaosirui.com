从 k8s 中连接 RedPanda 集群：

```bash
export RPK_USER=redpanda
export RPK_PASS=changeme
export RPK_SASL_MECHANISM="SCRAM-SHA-512"

kubectl exec redpanda-0 --namespace redpanda-system -c redpanda -- rpk cluster info \
    -X user=${RPK_USER} \
    -X pass=${RPK_PASS} \
    -X sasl.mechanism=${RPK_SASL_MECHANISM}

```

查看集群状态

```bash
rpk cluster info
```

