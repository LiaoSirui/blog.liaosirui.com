## PrometheusAlert

项目列表：

- <https://github.com/feiyu563/PrometheusAlert>

### API 发送信息

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

### 模板

- 钉钉模板

```tpl
{{ range $k,$v:=.alerts -}}
{{- if eq $v.status "resolved" -}}
### [Prometheus恢复信息]({{$v.generatorURL}})

##### <font color="#02b340">告警名称</font>：{{$v.labels.alertname}}
##### <font color="#02b340">告警级别</font>：{{$v.labels.severity}}
##### <font color="#02b340">触发时间</font>：{{GetCSTtime $v.startsAt}}
##### <font color="#02b340">结束时间</font>：{{GetCSTtime $v.endsAt}}
##### <font color="#02b340">主机名称</font>：{{$v.labels.instance}} {{$v.labels.nodename}} {{$v.labels.hostname}}
##### <font color="#02b340">告警内容：**{{$v.annotations.summary}}**</font>

{{ else }}
### [Prometheus告警信息]({{$v.generatorURL}})

##### <font color="#FF0000">告警名称</font>：{{$v.labels.alertname}}
##### <font color="#FF0000">告警级别</font>：{{$v.labels.severity}}
##### <font color="#FF0000">触发时间</font>：{{GetCSTtime $v.startsAt}}
##### <font color="#FF0000">主机名称</font>：{{$v.labels.instance}} {{$v.labels.nodename}} {{$v.labels.hostname}}
##### <font color="#FF0000">告警内容：**{{$v.annotations.summary}}**</font>

**{{ $v.annotations.description }}**
{{- end -}}
{{- end }}

```

- 企业微信

```
{{ range $k,$v:=.alerts -}}
{{- if eq $v.status "resolved" -}}
[PROMETHEUS-恢复信息]({{$v.generatorURL}})

> <font color="info">告警名称:</font> {{$v.labels.alertname}}
> <font color="info">告警级别:</font> {{$v.labels.severity}}
> <font color="info">触发时间:</font> {{GetCSTtime $v.startsAt}}
> <font color="info">结束时间:</font> {{GetCSTtime $v.endsAt}}
> <font color="info">主机名称:</font> {{$v.labels.instance}} {{$v.labels.nodename}} {{$v.labels.hostname}}
> <font color="info">**{{$v.annotations.description}}**</font>

{{- else -}}

[PROMETHEUS-告警信息]({{$v.generatorURL}})

> <font color="warning">告警名称:</font> {{$v.labels.alertname}}
> <font color="warning">告警级别:</font> {{$v.labels.severity}}
> <font color="warning">开始时间:</font> {{GetCSTtime $v.startsAt}}
> <font color="warning">主机名称:</font> {{$v.labels.instance}} {{$v.labels.nodename}} {{$v.labels.hostname}}
> <font color="warning">**{{$v.annotations.description}}**</font>

**{{ $v.annotations.description }}**

{{- end -}}
{{- end }}

```

