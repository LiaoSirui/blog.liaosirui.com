## 简介

需要安装如下包：

```bash
pip install apache-airflow-providers-cncf-kubernetes==<version>
```

通过文档可以确定兼容的 airflow 版本：

```bash
https://airflow.apache.org/docs/apache-airflow-providers-cncf-kubernetes/stable/index.html#requirements
```

使用 KubernetesPodOperator 可以是如下的 executor 类型，而不必一定是 Kubernetes executor

- Local executor
- LocalKubernetes executor
- Celery executor
- Kubernetes executor
- CeleryKubernetes executor

简单的测试

```python
from pendulum import datetime, duration
from airflow import DAG
from airflow.configuration import conf
from airflow.providers.cncf.kubernetes.operators.kubernetes_pod import (
    KubernetesPodOperator,
)

default_args = {
    "owner": "airflow",
    "depends_on_past": False,
    "start_date": datetime(2022, 1, 1),
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 1,
    "retry_delay": duration(minutes=5),
}

namespace = conf.get("kubernetes", "NAMESPACE")
# This will detect the default namespace locally and read the
# environment namespace when deployed to Astronomer.
if namespace == "default":
    config_file = "/usr/local/airflow/include/.kube/config"
    in_cluster = False
else:
    in_cluster = True
    config_file = None

with DAG(
    dag_id="example_kubernetes_pod",
    schedule="@once",
    default_args=default_args,
) as dag:
    KubernetesPodOperator(
        namespace=namespace,
        image="hello-world",
        # labels={"<pod-label>": "<label-name>"},
        labels={"kubernetes_pod": "test"},
        name="airflow-test-pod",
        task_id="task-one",
        # if set to true, will look in the cluster, if false, looks for file
        in_cluster=in_cluster,
        # is ignored when in_cluster is set to True
        cluster_context="docker-desktop",
        config_file=config_file,
        is_delete_operator_pod=True,
        get_logs=True,
    )

```

会生成如下的 pod

```yaml
kind: Pod
apiVersion: v1
metadata:
  name: airflow-test-pod-iu74io6f
  namespace: airflow-system
  labels:
    airflow_kpo_in_cluster: 'True'
    airflow_version: 2.6.2
    dag_id: example_kubernetes_pod
    kubernetes_pod: test
    kubernetes_pod_operator: 'True'
    run_id: scheduled__2022-01-01T0000000000-3ef18781b
    task_id: task-one
    try_number: '1'
spec:
  restartPolicy: Never
  serviceAccountName: default
  priority: 0
  schedulerName: default-scheduler
  enableServiceLinks: true
  affinity: {}
  terminationGracePeriodSeconds: 30
  preemptionPolicy: PreemptLowerPriority
  securityContext: {}
  containers:
    - name: base
      image: hello-world
      resources: {}
      volumeMounts:
        - name: kube-api-access-xjj2h
          readOnly: true
          mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      terminationMessagePath: /dev/termination-log
      terminationMessagePolicy: File
      imagePullPolicy: Always
  serviceAccount: default
  volumes:
    - name: kube-api-access-xjj2h
      projected:
        sources:
          - serviceAccountToken:
              expirationSeconds: 3607
              path: token
          - configMap:
              name: kube-root-ca.crt
              items:
                - key: ca.crt
                  path: ca.crt
          - downwardAPI:
              items:
                - path: namespace
                  fieldRef:
                    apiVersion: v1
                    fieldPath: metadata.namespace
        defaultMode: 420
  dnsPolicy: ClusterFirst
  tolerations:
    - key: node.kubernetes.io/not-ready
      operator: Exists
      effect: NoExecute
      tolerationSeconds: 300
    - key: node.kubernetes.io/unreachable
      operator: Exists
      effect: NoExecute
      tolerationSeconds: 300

```

## API 文档

- 官方文档：

- 源码：<https://github.com/apache/airflow/blob/main/airflow/providers/cncf/kubernetes/operators/pod.py>

可以使用 Jinja 的参数：`image`, `cmds`, `arguments`, `env_vars`, `labels`, `config_file`, `pod_template_file`, and `namespace`

### 必需参数

- `task_id`: 在 Airflow 中唯一标识任务的字符串
- `namespace`: 要分配新 Pod 的 Kubernetes 集群命名空间
- `name`: 正在创建的 Pod 的名称，每个命名空间内的每个 Pod 必须具有唯一的名称
- `image`: 要启动的 Docker 镜像

### 可选参数

- `random_name_suffix`: 如果设置为 `True`，则为 Pod 名称生成随机后缀；在运行大量 Pod 时，可以避免命名冲突
- `labels`: 键值对列表，可用于将解耦的对象逻辑分组
- `ports`: Pod 的端口
- `reattach_on_restart`: 定义在 Pod 运行时如何处理丢失的 worker；当设置为 `True` 时，现有的 Pod 会在下一次尝试时重新连接到 worker；当设置为 `False` 时，每次尝试都会创建一个新的 Pod。默认值为 `True`
- `is_delete_operator_pod`: 确定在 Pod 达到最终状态或执行被中断时是否删除该 Pod。默认值为 `True`。
- `get_logs`: 确定是否将容器的 `stdout` 用作任务日志记录到 Airflow 日志系统中
- `log_events_on_failure`: 确定在 Pod 失败时是否记录事件；默认值为 `False`
- `env_vars`: 一个包含 Pod 的环境变量的字典
- `container_resources`: 一个包含资源请求（键: `request_memory`、`request_cpu`）和限制（键: `limit_memory`、`limit_cpu`、`limit_gpu`）的字典。有关更多信息，请参阅[Kubernetes Pod 和容器资源管理文档](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
- `volumes`: 一个 `k8s.V1Volumes` 列表，也可以参考 [Airflow 文档中的 Kubernetes 示例 DAG](https://airflow.apache.org/docs/apache-airflow-providers-cncf-kubernetes/stable/_modules/tests/system/providers/cncf/kubernetes/example_kubernetes.html)
- `affinity` 和 `tolerations`: 用于 [Pod 到节点分配规则](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/)的规则字典。与 `volumes` 参数一样，这些参数也需要一个 `k8s` 对象
- `pod_template_file`: Pod 模板文件的路径
- `full_pod_spec`: 完整的 Pod 配置，格式化为 Python 的 `k8s` 对象

## `@task.kubernetes` 装饰器

Airflow 2.4 以上支持

```python
from pendulum import datetime
from airflow.configuration import conf
from airflow.decorators import dag, task
import random

# get the current Kubernetes namespace Airflow is running in
namespace = conf.get("kubernetes", "NAMESPACE")


@dag(
    start_date=datetime(2023, 1, 1),
    catchup=False,
    schedule="@daily",
)
def kubernetes_decorator_example_dag():
    @task
    def extract_data():
        # simulating querying from a database
        data_point = random.randint(0, 100)
        return data_point

    @task.kubernetes(
        # specify the Docker image to launch, it needs to be able to run a Python script
        image="python",
        # launch the Pod on the same cluster as Airflow is running on
        in_cluster=True,
        # launch the Pod in the same namespace as Airflow is running in
        namespace=namespace,
        # Pod configuration
        # naming the Pod
        name="my_pod",
        # log stdout of the container as task logs
        get_logs=True,
        # log events in case of Pod failure
        log_events_on_failure=True,
        # enable pushing to XCom
        do_xcom_push=True,
    )
    def transform(data_point):
        multiplied_data_point = 23 * int(data_point)
        return multiplied_data_point

    @task
    def load_data(**context):
        # pull the XCom value that has been pushed by the KubernetesPodOperator
        transformed_data_point = context["ti"].xcom_pull(
            task_ids="transform", key="return_value"
        )
        print(transformed_data_point)

    load_data(transform(extract_data()))


kubernetes_decorator_example_dag()
```



## 参考文档

- <https://docs.astronomer.io/learn/kubepod-operator>