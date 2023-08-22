查看索引

```bash
curl -XGET -u 'bigai:bigai@2023!' http://10.237.102.14:9200/_cat/indices
```

删除索引

```bash
curl -XDELETE -u 'bigai:bigai@2023!' http://10.237.102.14:9200/_cat/indices/bigaiv2test-container-log-2023.08.11
```

按照 namespace 统计

```bash
curl -XGET \
-H 'Content-Type: application/json' \
-u 'bigai:bigai@2023!' 'http://10.237.102.14:9200/bigaiv2test-container-log-2023.08.20/_search' \
-d '{
  "size": 0,
  "aggs": {
    "namespace_stats": {
      "terms": {
        "field": "kubernetes.pod_namespace.keyword"
      }
    }
  }
}' | jq .
```

