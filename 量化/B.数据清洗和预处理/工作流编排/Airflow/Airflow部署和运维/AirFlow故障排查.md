## Airflow 任务假死

可能是 Airflow 中的 task_instance 表的 state 字段缺少索引, 导致查询很慢导致的,

```
SHOW PROCESSLIST;
```

## SCARF_ANALYTICS 导致页面加载缓慢

airflow 界面卡顿，内网请求失败：<https://apacheairflow.gateway.scarf.sh/webserver/2.10.2/3.12/Linux/x86_64/postgresql/13.16/CeleryExecutor/1-5/1-5/1/1/0/0> 

 `SCARF_ANALYTICS=false` 环境变量关闭

Airflow integrates Scarf to collect basic platform and usage data during operation. This data assists Airflow maintainers in better understanding how Airflow is used. Insights gained from this telemetry are critical for prioritizing patches, minor releases, and security fixes. Additionally, this information supports key decisions related to the development road map. Check the FAQ doc for more information on what data is collected.

