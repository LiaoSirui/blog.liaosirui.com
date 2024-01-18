## 定义 Pipeline（管道）的例子

```python
"""
### Tutorial Documentation
Documentation that goes along with the Airflow tutorial located
[here](https://airflow.apache.org/tutorial.html)
"""
from __future__ import annotations

# [START tutorial]
# [START import_module]
from datetime import datetime, timedelta
from textwrap import dedent

# The DAG object; we'll need this to instantiate a DAG
from airflow import DAG

# Operators; we need this to operate!
from airflow.operators.bash import BashOperator

# [END import_module]


# [START instantiate_dag]
with DAG(
    "tutorial",
    # [START default_args]
    # These args will get passed on to each operator
    # You can override them on a per-task basis during operator initialization
    default_args={
        "depends_on_past": False,
        "email": ["airflow@example.com"],
        "email_on_failure": False,
        "email_on_retry": False,
        "retries": 1,
        "retry_delay": timedelta(minutes=5),
        # 'queue': 'bash_queue',
        # 'pool': 'backfill',
        # 'priority_weight': 10,
        # 'end_date': datetime(2016, 1, 1),
        # 'wait_for_downstream': False,
        # 'sla': timedelta(hours=2),
        # 'execution_timeout': timedelta(seconds=300),
        # 'on_failure_callback': some_function, # or list of functions
        # 'on_success_callback': some_other_function, # or list of functions
        # 'on_retry_callback': another_function, # or list of functions
        # 'sla_miss_callback': yet_another_function, # or list of functions
        # 'trigger_rule': 'all_success'
    },
    # [END default_args]
    description="A simple tutorial DAG",
    schedule=timedelta(days=1),
    start_date=datetime(2021, 1, 1),
    catchup=False,
    tags=["example"],
) as dag:
    # [END instantiate_dag]

    # t1, t2 and t3 are examples of tasks created by instantiating operators
    # [START basic_task]
    t1 = BashOperator(
        task_id="print_date",
        bash_command="date",
    )

    t2 = BashOperator(
        task_id="sleep",
        depends_on_past=False,
        bash_command="sleep 5",
        retries=3,
    )
    # [END basic_task]

    # [START documentation]
    t1.doc_md = dedent(
        """\
    #### Task Documentation
    You can document your task using the attributes `doc_md` (markdown),
    `doc` (plain text), `doc_rst`, `doc_json`, `doc_yaml` which gets
    rendered in the UI's Task Instance Details page.
    ![img](http://montcs.bloomu.edu/~bobmon/Semesters/2012-01/491/import%20soul.png)
    **Image Credit:** Randall Munroe, [XKCD](https://xkcd.com/license.html)
    """
    )

    dag.doc_md = __doc__  # providing that you have a docstring at the beginning of the DAG; OR
    dag.doc_md = """
    This is a documentation placed anywhere
    """  # otherwise, type it like this
    # [END documentation]

    # [START jinja_template]
    templated_command = dedent(
        """
    {% for i in range(5) %}
        echo "{{ ds }}"
        echo "{{ macros.ds_add(ds, 7)}}"
    {% endfor %}
    """
    )

    t3 = BashOperator(
        task_id="templated",
        depends_on_past=False,
        bash_command=templated_command,
    )
    # [END jinja_template]

    t1 >> [t2, t3]
# [END tutorial]

```

## DAG 定义文件

### 导入模块

导入所需的模块

```python
# DAG 用来实例化 DAG 对象，注意仅仅只是定义了一个对象，而不是进行真正的数据处理流程
from airflow import DAG
from airflow.operators.bash import BashOperator
```

### 设置默认参数

创建任务的时候可以使用这些默认参数

```python
default_args={
    "depends_on_past": False,
    "email": ["airflow@example.com"],
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
    # 'queue': 'bash_queue',
    # 'pool': 'backfill',
    # 'priority_weight': 10,
    # 'end_date': datetime(2016, 1, 1),
    # 'wait_for_downstream': False,
    # 'sla': timedelta(hours=2),
    # 'execution_timeout': timedelta(seconds=300),
    # 'on_failure_callback': some_function, # or list of functions
    # 'on_success_callback': some_other_function, # or list of functions
    # 'on_retry_callback': another_function, # or list of functions
    # 'sla_miss_callback': yet_another_function, # or list of functions
    # 'trigger_rule': 'all_success'
},
```

### 实例化一个 DAG

需要一个 DAG 对象来嵌入任务，下面的代码中，首先定义一个字符串，作为 DAG 的唯一标识，然后传入默认的参数字典(上面定义的)，然后定义调度的间隔为 1 天

```python
with DAG(
    "tutorial",
    # [START default_args]
    # These args will get passed on to each operator
    # You can override them on a per-task basis during operator initialization
    default_args={
        "depends_on_past": False,
        "email": ["airflow@example.com"],
        "email_on_failure": False,
        "email_on_retry": False,
        "retries": 1,
        "retry_delay": timedelta(minutes=5),
        # 'queue': 'bash_queue',
        # 'pool': 'backfill',
        # 'priority_weight': 10,
        # 'end_date': datetime(2016, 1, 1),
        # 'wait_for_downstream': False,
        # 'sla': timedelta(hours=2),
        # 'execution_timeout': timedelta(seconds=300),
        # 'on_failure_callback': some_function, # or list of functions
        # 'on_success_callback': some_other_function, # or list of functions
        # 'on_retry_callback': another_function, # or list of functions
        # 'sla_miss_callback': yet_another_function, # or list of functions
        # 'trigger_rule': 'all_success'
    },
    # [END default_args]
    description="A simple tutorial DAG",
    schedule=timedelta(days=1),
    start_date=datetime(2021, 1, 1),
    catchup=False,
    tags=["example"],
) as dag:
```

### 任务

实例化 operator 时会生成任务。一个从 operator 实例化的对象也称为构造器(constructor)，第一个参数 `task_id` 作为任务的唯一标识

```python
t1 = BashOperator(
    task_id="print_date",
    bash_command="date",
)

t2 = BashOperator(
    task_id="sleep",
    depends_on_past=False,
    bash_command="sleep 5",
    retries=3,
)
```

注意如何将各个 Operator 特定的参数 `bash_command` 以及继承自 BaseOperator 的所有 Operator 的通用参数 `retries` 传递给Operator 的 constructor

这比将每个参数传递给每个 constructor 要简单

也注意到，t2 继承的通用参数 retries 被我们重载，赋值成 3 

任务的前提规则如下：

1. 明确传递参数
2. 值在 default_args 字典中存在
3. operator 的默认值（如果存在），一个任务必须包含或者继承参数 task_id 与 owner ，否则 Airflow 将会抛出异常

### Templating with Jinja

Airflow 利用Jinja Templating 的强大功能，为管道作者提供一组内置参数和宏

Airflow 还为管道提供了定义自己的参数、宏和模板的钩子 Hooks

```python
templated_command = dedent(
    """
{% for i in range(5) %}
    echo "{{ ds }}"
    echo "{{ macros.ds_add(ds, 7)}}"
{% endfor %}
"""
)

t3 = BashOperator(
    task_id="templated",
    depends_on_past=False,
    bash_command=templated_command,
)
```

templated_command 包含 `{%%}` 块中的代码逻辑，引用参数如 `{{ds}}`，调用 `{{macros.ds_add (ds，7)}`} 中的函数，并在 `{{params.my_param}}` 中引用用户定义的参数

### 设置依赖关系

有互不依赖的三个任务 t1, t2, t3

接下来有一些定义它们之间依赖关系的方法

```python
t1.set_downstream(t2)

# 这个表示 t2 将依赖于 t1
# 等价于
t2.set_upstream(t1)

# 位移运算符也可以完成 t2 依赖于 t1 的设置
t1 >> t2

# 位移运算符完成t1 依赖于 t2 的设置
t2 << t1

# 使用位移运算符更加简洁地设置多个连锁依赖关系
t1 >> t2 >> t3

# 任务列表也可以被设置成依赖，以下几种表达方式是等效的
t1.set_downstream([t2, t3])
t1 >> [t2, t3]
[t2, t3] << t1
```

在执行脚本时，Airflow 会在 DAG 中找到循环或多次引用依赖项时引发异常

## 测试

### 运行脚本

首先确认上述的代码已经存入`tutorial.py`，文件的位置位于你的`airflow.cfg`指定的 `dags` 文件夹内

在命令行执行：

```bash
python ~/airflow/dags/tutorial.py
```

### 命令行元数据验证

运行一些命令来进一步验证上一个脚本

```bash
# 打印激活的 DAGs 的列表
airflow list_dags

# 打印 dag_id 为 "tutorial"  的任务的列表
airflow list_tasks tutorial

# 打印 tutorial DAG 中任务的层级关系
airflow list_tasks tutorial --tree
```

### 测试

通过在特定日期运行实际任务实例来进行测试

在此上下文中指定的日期是`execution_date`，它模拟特定日期+时间调度运行任务或 dag：

```bash
# command layout: command subcommand dag_id task_id date

# testing print_date
airflow test tutorial print_date 2015-06-01

# testing sleep
airflow test tutorial sleep 2015-06-01
```

通过运行此命令，了解如何呈现和执行此模板：

```bash
# testing templated
airflow test tutorial templated 2015-06-01
```

`airflow test`命令在本地运行任务实例，将其日志输出到stdout（在屏幕上），不依赖于依赖项，并且不向数据库传达状态（运行，成功，失败，...）

### backfill

backfill: 在指定的日期范围内运行 DAG 的子部分

```
此上下文中的日期范围是 start_date 和可选的e nd_date，它们用于使用此 dag 中的任务实例填充运行计划

# 在一个时间范围内开始你的 backfill
airflow backfill tutorial -s 2015-06-01 -e 2015-06-07
```

