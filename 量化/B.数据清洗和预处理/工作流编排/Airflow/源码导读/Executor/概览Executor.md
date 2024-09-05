文件路径：`/airflow/executors/executor_constants.py`，源码位置：<https://github.com/apache/airflow/blob/main/airflow/executors/executor_constants.py>

```python
LOCAL_EXECUTOR = "LocalExecutor"
LOCAL_KUBERNETES_EXECUTOR = "LocalKubernetesExecutor"
SEQUENTIAL_EXECUTOR = "SequentialExecutor"
CELERY_EXECUTOR = "CeleryExecutor"
CELERY_KUBERNETES_EXECUTOR = "CeleryKubernetesExecutor"
KUBERNETES_EXECUTOR = "KubernetesExecutor"
DEBUG_EXECUTOR = "DebugExecutor"
MOCK_EXECUTOR = "MockExecutor"
```

文档：<https://airflow.apache.org/docs/apache-airflow/stable/core-concepts/executor/index.html#executor-types>