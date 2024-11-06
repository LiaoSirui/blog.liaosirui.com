## RBAC

参考文档：<https://cloud.google.com/composer/docs/airflow-rbac?hl=zh-cn>

将 DAG 分配给 DAG 属性中的角色

通过 DAG 源代码中定义的 `access_control` 属性为角色授予 DAG 访问权限

官方文档：

- <https://airflow.apache.org/docs/apache-airflow-providers-fab/stable/auth-manager/access-control.html>
- <https://airflow.apache.org/docs/apache-airflow-providers-fab/stable/auth-manager/webserver-authentication.html>

## 角色

在 airflow 中，有不同的角色，Admin 拥有最大的权限，Viewer 可以查看前端 UI 的内容；User 除了查看还有具体操作（对 DAG 的增删改查）的权限，Op 在 User 的基础上增加了参数配置的权限，详见：<https://airflow.apache.org/docs/apache-airflow/2.8.2/security/access-control.html>

如果需要对某一个具体的用户只赋予查看局部 DAG 以及操作 DAG 的权限，就赋予其以下权限：

- can read on Website: 可以登录 UI 系统
- can read on DAG（Dag 名称）：可以访问具体的 DAG
- can eidt on DAG（Dag 名称）：可以停止或者开启具体的 DAG
- can read on DAG Runs: 可以查看每一次 Run 的日志
- can read on Task Instances/can read on Task Logs: 可以点击 DAG 进入查看其日志
- can delete on Task Instances: 可以将某一个任务 clear，重启任务

## 其他

添加 admin 权限

```shell
airflow users add-role -r "Admin" -u "sirui.liao"
```

增加的默认权限

```
airflow roles add-perms -r "Website" -a can_read -- Public
airflow roles add-perms -r "DAG Code" -a can_read -- Public
airflow roles add-perms -r "DAG Dependencies" -a can_read menu_access -- Public
airflow roles add-perms -r "DAG Runs" -a can_read menu_access -- Public
airflow roles add-perms -r "DAG Warnings" -a can_read -- Public
airflow roles add-perms -r "Docs" -a menu_access -- Public
airflow roles add-perms -r "Documentation" -a menu_access -- Public
airflow roles add-perms -r "ImportError" -a can_read -- Public
airflow roles add-perms -r "Jobs" -a can_read -- Public
airflow roles add-perms -r "My Password" -a can_edit can_read -- Public
airflow roles add-perms -r "My Profile" -a can_edit can_read -- Public
airflow roles add-perms -r "Plugins" -a can_read can_read -- Public
airflow roles add-perms -r "Pools" -a can_read -- Public
airflow roles add-perms -r "Task Instances" -a can_read -- Public
airflow roles add-perms -r "Task Logs" -a can_read -- Public
airflow roles add-perms -r "XComs" -a can_read -- Public

```

单个 dag 授权

```bash
airflow roles del-perms \
    -r \
    "DAG Runs" \
    "DAGs" \
    "Datasets" \
    "Docs" \
    "Documentation" \
    "Jobs" \
    "Plugins" \
    "SLA Misses" \
    "Task Instances" \
    -a menu_access -- sirui.liao-dags

airflow roles del-perms \
    -r "Cluster Activity" \
    "DAG Dependencies" \
    "DAG Runs" \
    "DAGs" \
    "Datasets" \
    "Docs" \
    "Documentation" \
    "Jobs" \
    "Plugins" \
    "SLA Misses" \
    "Task Instances" \
    -a menu_access -- sirui.liao-dags

airflow roles add-perms \
    -r "Browse" \
    -r "Cluster Activity" \
    -r "DAG Dependencies" \
    -r "DAG Runs" \
    -r "DAGs" \
    -r "Datasets" \
    -r "Docs" \
    -r "Documentation" \
    -r "Jobs" \
    -r "Plugins" \
    -r "SLA Misses" \
    -r "Task Instances" \
    -a menu_access -- sirui.liao-dags
airflow roles add-perms -r "Cluster Activity"  -a menu_access -- sirui.liao-dags
airflow roles add-perms -r "DAG Dependencies"  -a menu_access -- sirui.liao-dags
airflow roles add-perms -r DAG Runs            -a menu_access -- sirui.liao-dags
airflow roles add-perms -r DAGs                -a menu_access -- sirui.liao-dags
airflow roles add-perms -r Datasets            -a menu_access -- sirui.liao-dags
airflow roles add-perms -r Docs                -a menu_access -- sirui.liao-dags
airflow roles add-perms -r Documentation       -a menu_access -- sirui.liao-dags
airflow roles add-perms -r Jobs                -a menu_access -- sirui.liao-dags
airflow roles add-perms -r Plugins             -a menu_access -- sirui.liao-dags
airflow roles add-perms -r SLA Misses          -a menu_access -- sirui.liao-dags
airflow roles add-perms -r "Task Instances"    -a menu_access -- sirui.liao-dags

```

添加单个 DAG 权限

```
airflow roles add-perms -r DAG:srliao_param_the_dag -a can_edit can_read menu_access -- sirui.liao-dags
```

查看权限

```shell
airflow roles list -p 
```
