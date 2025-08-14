示例

```bash
export RD_ADDR=127.0.0.1
export RD_TOPIC=test-topic
curl -k "https://${RD_ADDR}:9644/v1/partitions/kafka/${RD_TOPIC}" | jq .

```

