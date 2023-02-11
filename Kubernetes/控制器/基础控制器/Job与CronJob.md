Job 负责处理任务，即仅执行一次的任务，它保证批处理任务的一个或多个 Pod 成功结束，CronJob 则就是在 Job 上增加时间调度



手动触发 CronJob

```bash
kubectl create job --from=cronjob/<name of cronjob> <name of job>
```

例如：

```bash
kubectl create job --from=cronjob/pgdump pgdump-manual-001
```

