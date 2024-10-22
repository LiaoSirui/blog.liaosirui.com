## Airflow 简介

官方

- 官网：<https://airflow.apache.org/>

- 文档：<https://airflow.apache.org/docs/>
- GitHub 仓库：<https://github.com/apache/airflow>

- Airflow 入门教程代码：<https://github.com/apache/airflow/blob/main/airflow/example_dags/tutorial.py>

astronomer 基于airflow 做了一些扩展，可以实现 airflow 安全，产品级，可靠以及可扩展

- <https://www.astronomer.io/>

## 基础概念

- Data Pipeline

数据管道或者数据流水线，可以理解为贯穿数据处理分析过程中不同工作环节的流程，例如加载不同的数据源，数据加工以及可视化

- DAGs

是有向非循环图（directed acyclic graphs），可以理解为有先后顺序任务的多个 Tasks 的组合。图的概念是由节点组成的，有向的意思就是说节点之间是有方向的，转成工业术语我们可以说节点之间有依赖关系；非循环的意思就是说节点直接的依赖关系只能是单向的，不能出现 A 依赖于 B，B 依赖于 C，然后 C 又反过来依赖于 A 这样的循环依赖关系。每个 Dag 都有唯一的 DagId，当一个 DAG 启动的时候，Airflow 都将在数据库中创建一个 DagRun 记录，相当于一个日志

- Task

是包含一个具体 Operator 的对象，operator 实例化的时候称为 task。DAG 图中的每个节点都是一个任务，可以是一条命令行（BashOperator），也可以是一段 Python 脚本（PythonOperator）等，然后这些节点根据依赖关系构成了一个图，称为一个 DAG。当一个任务执行的时候，实际上是创建了一个 Task 实例运行，它运行在 DagRun 的上下文中

- Connections

是管理外部系统的连接对象，如外部 MySQL、HTTP 服务等，连接信息包括 conn_id／hostname／login／password／schema 等，可以通过界面查看和管理，编排 workflow 时，使用 conn_id 进行使用

- Pools

用来控制 tasks 执行的并行数。将一个 task 赋给一个指定的 pool，并且指明 priority_weight 权重，从而干涉 tasks 的执行顺序

- XComs

在 airflow 中，operator 一般是原子的，也就是它们一般是独立执行，不需要和其他 operator 共享信息。但是如果两个 operators 需要共享信息，例如 filename 之类的，则推荐将这两个 operators 组合成一个 operator；如果一定要在不同的 operator 实现，则使用 XComs (cross-communication) 来实现在不同 tasks 之间交换信息。在 airflow 2.0 以后，因为 task 的函数跟 python 常规函数的写法一样，operator 之间可以传递参数，但本质上还是使用 XComs，只是不需要在语法上具体写 XCom 的相关代码

- Trigger Rules

指 task 的触发条件。默认情况下是 task 的直接上游执行成功后开始执行，airflow 允许更复杂的依赖设置，包括 all_success (所有的父节点执行成功)，all_failed (所有父节点处于 failed 或 upstream_failed 状态)，all_done (所有父节点执行完成)，one_failed (一旦有一个父节点执行失败就触发，不必等所有父节点执行完成)，one_success (一旦有一个父节点执行成功就触发，不必等所有父节点执行完成)，dummy (依赖关系只是用来查看的，可以任意触发)。另外，airflow 提供了 depends_on_past，设置为 True 时，只有上一次调度成功了，才可以触发

- Backfill:

可以支持重跑历史任务，例如当 ETL 代码修改后，把上周或者上个月的数据处理任务重新跑一遍

## 参考资料

- <https://www.kancloud.cn/luponu/airflow-doc-zh/889658>

- <https://blog.csdn.net/weixin_40046357/article/details/127456285>
