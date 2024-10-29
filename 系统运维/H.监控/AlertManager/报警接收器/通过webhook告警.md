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

示例发送

```python
import json
from datetime import datetime
import requests
 
 
access_token = (
    "25fcbdc3b09c5ac1e76bb911bb17d2a0d748397f9d958cc98a4bffa4032e996c"
)
 
url = (
    "http://192.168.16.185:18081/prometheusalert?"
    "type=dd&tpl=prometheus-dd&"
    f"ddurl=https://oapi.dingtalk.com/robot/send?access_token={access_token}"
)
 
labels = {
    "alertname": "测试告警",
    "instance": "localhost:8848",
    "job": "test",
    "severity": "veryCritical",
}
 
annotations = {
    "description": "测试告警详情 description",
    "summary": "测试告警详情 summary",
}
 
payload = json.dumps(
    {
        "receiver": "webhook",
        "status": "firing",
        "alerts": [
            {
                "status": "firing",
                "labels": labels,
                "annotations": annotations,
                "startsAt": f"{datetime.now().isoformat()}",
                "endsAt": "0001-01-01T00:00:00Z",
                "fingerprint": "451c9ca7ae1697e6",
            }
        ],
        "groupLabels": labels,
        "commonLabels": labels,
        "commonAnnotations": annotations,
        "externalURL": "https://platform.liangkui.co/platform/alertmanager",
        "version": "4",
        "groupKey": "{}:" + str(labels),
        "truncatedAlerts": 0,
    }
)
headers = {"Content-Type": "application/json"}
 
response = requests.request("POST", url, headers=headers, data=payload)
 
print(response.text)
```

项目列表：

- <https://github.com/feiyu563/PrometheusAlert>