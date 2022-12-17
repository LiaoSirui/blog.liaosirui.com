
## 元数据查询

### Metrics Name

Prometheus 查询所有的 metrics，limit 限制查询的数量， querying-metric-metadata：

<https://prometheus.io/docs/prometheus/latest/querying/api/#querying-metric-metadata>

```bash
curl "127.0.0.1:9090/api/v1/metadata?limit=2" |jq

{
  "status": "success",
  "data": {
    "prometheus_tsdb_head_min_time": [
      {
        "type": "gauge",
        "help": "Minimum time bound of the head block. The unit is decided by the library consumer.",
        "unit": ""
      }
    ],
    "prometheus_tsdb_vertical_compactions_total": [
      {
        "type": "counter",
        "help": "Total number of compactions done on overlapping blocks.",
        "unit": ""
      }
    ]
  }
}
```

VictoriaMetrics 当前不支持。

### Series

Prometehus 查询 Series Value，注意这个方法只是查询满足条件的时间序列，没有数值：

```bash
curl -g 'http://127.0.0.1:9090/api/v1/series' --data-urlencode 'match[]=vm_rows{}'  --data-urlencode 'start=2020-03-02T00:00:00Z'|jq

{
  "status": "success",
  "data": [
    {
      "__name__": "vm_rows",
      "instance": "vmstorage:8482",
      "job": "victoria",
      "type": "indexdb"
    },
    {
      "__name__": "vm_rows",
      "instance": "vmstorage:8482",
      "job": "victoria",
      "type": "storage/big"
    },
    {
      "__name__": "vm_rows",
      "instance": "vmstorage:8482",
      "job": "victoria",
      "type": "storage/small"
    }
  ]
}
```

VictoriaMetrics 支持：

```bash
curl 'http://127.0.0.1:8481/select/0/prometheus/api/v1/series' --data-urlencode 'match[]=vm_rows{}' |jq
```

### Labels & Label Value

Prometeus：

```bash
curl 127.0.0.1:9090/api/v1/labels |jq

{
  "status": "success",
  "data": [
    "GOARCH",
    "GOOS",
    "GOROOT",
    "__name__",
    "accountID",
    "action",
    ...
```

```bash
curl 127.0.0.1:9090/api/v1/label/job/values | jq

{
  "status": "success",
  "data": [
    "prometheus",
    "victoria"
  ]
}
```

VictoriaMetrics 支持:

```bas
curl 127.0.0.1:8481/select/0/prometheus/api/v1/labels |jq

curl 127.0.0.1:8481/select/0/prometheus/api/v1/label/job/values | jq
```

## 数值查询

Prometheus 当前值查询：

```bash
curl 'http://localhost:9090/api/v1/query?query=vm_rows' |jq

{
  "status": "success",
  "data": {
    "resultType": "vector",
    "result": [
      {
        "metric": {
          "__name__": "vm_rows",
          "instance": "vmstorage:8482",
          "job": "victoria",
          "type": "indexdb"
        },
        "value": [
          1583123606.056,
          "14398"
        ]
      },
...
```

VictoriaMetrics 支持：

```bash
curl 'http://localhost:8481/select/0/prometheus/api/v1/query?query=vm_rows' |jq
```
