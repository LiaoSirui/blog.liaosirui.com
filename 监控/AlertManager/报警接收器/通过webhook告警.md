告警信息，其结构如下

```json
{
    "receiver":"web\\.hook",
    "status":"firing",
    "alerts":[
        {
            "status":"firing",
            "labels":{
                "alertname":"Nacos Down",
                "instance":"localhost:8848",
                "job":"nacos",
                "severity":"emergency",
                "target":"nacos"
            },
            "annotations":{
                "description":"description",
                "summary":"localhost:8848 已停止运行超过 1 分钟！"
            },
            "startsAt":"2021-09-22T02:23:24.38636357Z",
            "endsAt":"0001-01-01T00:00:00Z",
            "generatorURL":"http://DESKTOP-GQBQ1GQ:9090/graph?g0.expr=up%7Bjob%3D%22nacos%22%7D+%3D%3D+0\u0026g0.tab=1",
            "fingerprint":"451c9ca7ae1697e6"
        }
    ],
    "groupLabels":{
        "target":"nacos"
    },
    "commonLabels":{
        "alertname":"Nacos Down",
        "instance":"localhost:8848",
        "job":"nacos",
        "severity":"emergency",
        "target":"nacos"
    },
    "commonAnnotations":{
        "description":"description",
        "summary":"localhost:8848 已停止运行超过 1 分钟！"
    },
    "externalURL":"http://DESKTOP-GQBQ1GQ:9093",
    "version":"4",
    "groupKey":"{}:{target=\"nacos\"}",
    "truncatedAlerts":0
}

```

项目列表：

- <https://github.com/feiyu563/PrometheusAlert>