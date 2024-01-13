## 简介

Job 负责处理任务，即仅执行一次的任务，它保证批处理任务的一个或多个 Pod 成功结束，CronJob 则就是在 Job 上增加时间调度

## Job

### 参考模板

```yaml
kind: Job
apiVersion: batch/v1
metadata:
  name: sentry-sentry-cleanup-28140000
  namespace: sentry
  labels:
    app: xxx
spec:
  # 定义的是一个 Job 在任意时间最多可以启动多少个 Pod 同时运行
  parallelism: 1
  # 定义的是 Job 至少要完成的 Pod 数目，即 Job 的最小完成数
  completions: 1
  # spec.activeDeadlineSeconds 属性用于设置 Job 运行的超时时间
  # 如果 Job 运行的时间超过了设定的秒数，那么此 Job 就自动停止运行所有的 Pod，并将 Job 退出状态标记为 reason:DeadlineExceeded
  activeDeadlineSeconds: 300
  # spec.backoffLimit 用于设置 Job 的容错次数，默认值为 6
  # 当 Job 运行的 Pod 失败次数到达.spec.backoffLimit 次时，Job Controller 不再新建 Pod，直接停止运行这个 Job，将其运行结果标记为 Failure
  backoffLimit: 6
  completionMode: NonIndexed
  suspend: false
  podFailurePolicy:
    rules:
      - action: FailJob
        onExitCodes:
          containerName: runner
          operator: In
          values: [1]
  template:
    metadata:
      labels:
        app: xxx
    spec:
      volumes:
        - name: data
          emptyDir: {}
      nodeSelector:
        ready: "true"
      serviceAccountName: default
      imagePullSecrets:
        - name: image-pull-secrets
      restartPolicy: OnFailure
      # 优雅退出时间，等待进程收到退出信号后的最后处理
      terminationGracePeriodSeconds: 30
      tolerations:
        # not-ready 300s 后重新调度
        - key: node.kubernetes.io/not-ready
          operator: Exists
          effect: NoExecute
          tolerationSeconds: 300
        # 同上
        - key: node.kubernetes.io/unreachable
          operator: Exists
          effect: NoExecute
          tolerationSeconds: 300
      containers:
        - name: runner
          image: "kubernetes-job-demo:latest"
          imagePullPolicy: IfNotPresent
          volumeMounts:
            - name: data
              mountPath: /var/lib
          resources: {}
          command:
            - /bin/bash
          args:
            - -c
            - python3 test.py
          env:
            - name: JOB_NODE_NAME
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
            - name: JPB_POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: JOB_POD_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
            - name: JOB_POD_IP
              valueFrom:
                fieldRef:
                  fieldPath: status.podIP

```

## CronJob

手动触发 CronJob

```bash
kubectl create job --from=cronjob/<name of cronjob> <name of job>
```

例如：

```bash
kubectl create job --from=cronjob/pgdump pgdump-manual-001
```

