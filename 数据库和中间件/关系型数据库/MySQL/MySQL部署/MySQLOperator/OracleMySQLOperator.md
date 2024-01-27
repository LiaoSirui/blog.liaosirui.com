## 简介

项目地址：https://github.com/mysql/mysql-operator

## 工作原理

Oracle MySQL Operator 支持以下 2 种 MySQL 部署模式。

* Primary - 服务由一个可读写的主节点和多个只读的从节点组成。

* Multi-Primary - 集群中各节点角色相同，没有主从的概念，每个节点都可以处理用户的读写请求。


## 安装

使用工具 helm

```
helm version

version.BuildInfo{Version:"v3.10.0", GitCommit:"ce66412a723e4d89555dc67217607c6579ffcb21", GitTreeState:"clean", GoVersion:"go1.18.6"}
```

添加 helm repo

```
helm repo add mysql-operator https://mysql.github.io/mysql-operator/
```

更新 helm 仓库

```
 helm repo update
```

查看版本

```
 helm search repo mysql-operator

NAME                              	CHART VERSION	APP VERSION 	DESCRIPTION
mysql-operator/mysql-operator     	2.0.6        	8.0.30-2.0.6	MySQL Operator Helm Chart for deploying MySQL I...
mysql-operator/mysql-innodbcluster	2.0.6        	8.0.30      	MySQL InnoDB Cluster Helm Chart for deploying M...
```

查看 operator 的默认配置：https://github.com/mysql/mysql-operator/blob/8.0.30-2.0.6/helm/mysql-operator/values.yaml

```
helm show values mysql-operator/mysql-operator --version 2.0.6
```

安装指定的版本

```
helm install mysql-operator mysql-operator/mysql-operator --version 2.0.6 --namespace mysql-operator --create-namespace
```

生成的 note

```
NAME: mysql-operator
LAST DEPLOYED: Sun Oct  9 16:15:16 2022
NAMESPACE: aipaas-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Create an MySQL InnoDB Cluster by executing:
1. When using a source distribution / git clone: `helm install [cluster-name] -n [ns-name] ~/helm/mysql-innodbcluster`
2. When using the Helm repo from ArtifactHub
2.1 With self signed certificates
    export NAMESPACE="your-namespace"
    # in case the namespace doesn't exist, please pass --create-namespace
    helm install my-mysql-innodbcluster mysql-operator/mysql-innodbcluster -n $NAMESPACE \
        --version 2.0.6 \
        --set credentials.root.password=">-0URS4F3P4SS" \
        --set tls.useSelfSigned=true

2.2 When you have own CA and TLS certificates
        export NAMESPACE="your-namespace"
        export CLUSTER_NAME="my-mysql-innodbcluster"
        export CA_SECRET="$CLUSTER_NAME-ca-secret"
        export TLS_SECRET="$CLUSTER_NAME-tls-secret"
        export ROUTER_TLS_SECRET="$CLUSTER_NAME-router-tls-secret"
        # Path to ca.pem, server-cert.pem, server-key.pem, router-cert.pem and router-key.pem
        export CERT_PATH="/path/to/your/ca_and_tls_certificates"

        kubectl create namespace $NAMESPACE

        kubectl create secret generic $CA_SECRET \
            --namespace=$NAMESPACE --dry-run=client --save-config -o yaml \
            --from-file=ca.pem=$CERT_PATH/ca.pem \
        | kubectl apply -f -

        kubectl create secret tls $TLS_SECRET \
            --namespace=$NAMESPACE --dry-run=client --save-config -o yaml \
            --cert=$CERT_PATH/server-cert.pem --key=$CERT_PATH/server-key.pem \
        | kubectl apply -f -

        kubectl create secret tls $ROUTER_TLS_SECRET \
            --namespace=$NAMESPACE --dry-run=client --save-config -o yaml \
            --cert=$CERT_PATH/router-cert.pem --key=$CERT_PATH/router-key.pem \
        | kubectl apply -f -

        helm install my-mysql-innodbcluster mysql-operator/mysql-innodbcluster -n $NAMESPACE \
        --version 2.0.6 \
        --set credentials.root.password=">-0URS4F3P4SS" \
        --set tls.useSelfSigned=false \
        --set tls.caSecretName=$CA_SECRET \
        --set tls.serverCertAndPKsecretName=$TLS_SECRET \
        --set tls.routerCertAndPKsecretName=$ROUTER_TLS_SECRET
```

生成一个简单的集群

为了方便测试，这里使用 local-path-provisor 来提供数据

```
podSpec:
  containers:
  - name: mysql
    resources:
      requests:
        memory: "4096Mi"  # adapt to your needs
        cpu: "2"      # adapt to your needs
      limits:
        memory: "4096Mi"  # adapt to your needs
        cpu: "2"      # adapt to your needs
credentials:
  root:
    password: ">-0URS4F3P4SS"
datadirVolumeClaimTemplate:
  storageClassName: local-path
  accessModes: ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
tls:
  useSelfSigned: true
serverConfig:
  mycnf: |
    [mysqld]
    core_file
    local_infile=off

```

使用 chart 创建实例

```
helm install mysql-innodbcluster mysql-operator/mysql-innodbcluster -n mysql-operator \
        --version 2.0.6 \
        -f ./values.yaml --create-namespace
```

## MySQL Shell

MySQL Shell Utilities是MySQL 8.0官方推出的管理工具集合，包括Upgrade Checker Utility、JSON Import Utility、Table Export Utility、Parallel Table Import Utility、Instance Dump Utility、Schema Dump Utility、Table Dump Utility、Dump Loading Utility等，可以支持整个实例、单个数据库、单张表的逻辑备份与恢复

在MySQL 8.0版本中，推出了MySQL Shell Utilities，其中就包含最新的逻辑备份恢复工具，可以支持多线程导出导入，解决了mysqldump/mysqlpump速度慢的问题：https://cloud.tencent.com/developer/article/1808960

`mysql-shell` 是一个新的客户端软件，与之前的 `mysql` 命令不同的是 `mysql-shell` 支持使用 `SQL` 、`js`、 `python` 这三种语言与 `MySQL-Server`交互。

官方文档地址：https://dev.mysql.com/doc/mysql-shell/8.0/en/mysqlsh.html

### 安装

```
cd $(mktemp -d)

wget https://cdn.mysql.com//Downloads/MySQL-Shell/mysql-shell-8.0.30-linux-glibc2.12-x86-64bit.tar.gz

tar -xvf mysql-shell-8.0.30-linux-glibc2.12-x86-64bit.tar.gz -C /usr/local

cd /usr/local/
ln -s mysql-shell-8.0.30-linux-glibc2.12-x86-64bit mysql-shell

echo 'export PATH=/usr/local/mysql-shell/bin:$PATH' >> ~/.zshrc
```


### 使用

* 连接MySQL数据库

第一种是直接在命令行中输入mysqlsh命令和数据库地址等信息，然后根据提示输入密码即可

```
mysqlsh root@10.3.143.36:3306
```

登录状态：

```
 mysqlsh root@10.3.143.36:3306                                                                                                                                       ✔  took 4m 14s   with root@devmaster1  at 10:50:30 
Please provide the password for 'root@10.3.143.36:3306': *************
MySQL Shell 8.0.30

Copyright (c) 2016, 2022, Oracle and/or its affiliates.
Oracle is a registered trademark of Oracle Corporation and/or its affiliates.
Other names may be trademarks of their respective owners.

Type '\help' or '\?' for help; '\quit' to exit.
Creating a session to 'root@10.3.143.36:3306'
Fetching schema names for autocompletion... Press ^C to stop.
Your MySQL connection id is 105808
Server version: 8.0.30 MySQL Community Server - GPL
No default schema selected; type \use <schema> to set one.
 MySQL  10.3.143.36:3306 ssl  JS >
```

另一种方法是先输入mysqlsh启动程序，然后再通过 `\connect` 命令连接数据库。

```
 mysqlsh                                                                                                                                                              ✔  took 1m 5s   with root@devmaster1  at 10:51:47 
MySQL Shell 8.0.30

Copyright (c) 2016, 2022, Oracle and/or its affiliates.
Oracle is a registered trademark of Oracle Corporation and/or its affiliates.
Other names may be trademarks of their respective owners.

Type '\help' or '\?' for help; '\quit' to exit.
 MySQL  JS > \connect root@10.3.143.36:3306
Creating a session to 'root@10.3.143.36:3306'
Please provide the password for 'root@10.3.143.36:3306': *************
Fetching schema names for autocompletion... Press ^C to stop.
Your MySQL connection id is 105969
Server version: 8.0.30 MySQL Community Server - GPL
No default schema selected; type \use <schema> to set one.
 MySQL  10.3.143.36:3306 ssl  JS >
```


* 查看当前会话的状态

```
 MySQL  JS > shell.status()
MySQL Shell version 8.0.30

Not Connected.
```

mysqlsh 通过一个叫 `session` 的对象连接到`MySQL-Server`，session 是全局的并且是跨语言的，如果当前的 mysqlsh 没有连接到任何 `MySQL-Server` 那么可以看到如下状态。

```
MySQL  JS > session == null;                                                                
true
MySQL  JS > shell.status();                                                                 
MySQL Shell version 8.0.19

Not Connected.
```

* 检查配置是否生效

```
 MySQL  10.3.143.36:3306 ssl  JS > dba.checkInstanceConfiguration()
Validating MySQL instance at mysql-innodbcluster-0.mysql-innodbcluster-instances.mysql-operator.svc.cluster.local:3306 for use in an InnoDB cluster...

This instance reports its own address as mysql-innodbcluster-0.mysql-innodbcluster-instances.mysql-operator.svc.cluster.local:3306

Checking whether existing tables comply with Group Replication requirements...
No incompatible tables detected

Checking instance configuration...
Instance configuration is compatible with InnoDB cluster

The instance 'mysql-innodbcluster-0.mysql-innodbcluster-instances.mysql-operator.svc.cluster.local:3306' is valid to be used in an InnoDB cluster.

{
    "status": "ok"
}
```

检查其他机器

```
 MySQL  10.3.143.36:3306 ssl  JS > dba.checkInstanceConfiguration("root@10.4.198.206:3306")
Please provide the password for 'root@10.4.198.206:3306': *************
Validating MySQL instance at mysql-innodbcluster-1.mysql-innodbcluster-instances.mysql-operator.svc.cluster.local:3306 for use in an InnoDB cluster...

This instance reports its own address as mysql-innodbcluster-1.mysql-innodbcluster-instances.mysql-operator.svc.cluster.local:3306

Checking whether existing tables comply with Group Replication requirements...
No incompatible tables detected

Checking instance configuration...
Instance configuration is compatible with InnoDB cluster

The instance 'mysql-innodbcluster-1.mysql-innodbcluster-instances.mysql-operator.svc.cluster.local:3306' is valid to be used in an InnoDB cluster.

{
    "status": "ok"
}



 MySQL  10.3.143.36:3306 ssl  JS > dba.checkInstanceConfiguration("root@10.4.17.89:3306")
Please provide the password for 'root@10.4.17.89:3306': *************
Validating MySQL instance at mysql-innodbcluster-2.mysql-innodbcluster-instances.mysql-operator.svc.cluster.local:3306 for use in an InnoDB cluster...

This instance reports its own address as mysql-innodbcluster-2.mysql-innodbcluster-instances.mysql-operator.svc.cluster.local:3306

Checking whether existing tables comply with Group Replication requirements...
No incompatible tables detected

Checking instance configuration...
Instance configuration is compatible with InnoDB cluster

The instance 'mysql-innodbcluster-2.mysql-innodbcluster-instances.mysql-operator.svc.cluster.local:3306' is valid to be used in an InnoDB cluster.

{
    "status": "ok"
}
```

* 查看集群状态

文档地址：https://dev.mysql.com/doc/mysql-shell/8.0/en/monitoring-innodb-cluster.html

```
 MySQL  mysql-innodbcluster:3306 ssl  JS > var cluster = dba.getCluster()


 MySQL  mysql-innodbcluster:3306 ssl  JS > cluster.describe();
{
    "clusterName": "mysql_innodbcluster", 
    "defaultReplicaSet": {
        "name": "default", 
        "topology": [
            {
                "address": "mysql-innodbcluster-0.mysql-innodbcluster-instances.mysql-operator.svc.cluster.local:3306", 
                "label": "mysql-innodbcluster-0.mysql-innodbcluster-instances.mysql-operator.svc.cluster.local:3306", 
                "role": "HA"
            }, 
            {
                "address": "mysql-innodbcluster-1.mysql-innodbcluster-instances.mysql-operator.svc.cluster.local:3306", 
                "label": "mysql-innodbcluster-1.mysql-innodbcluster-instances.mysql-operator.svc.cluster.local:3306", 
                "role": "HA"
            }, 
            {
                "address": "mysql-innodbcluster-2.mysql-innodbcluster-instances.mysql-operator.svc.cluster.local:3306", 
                "label": "mysql-innodbcluster-2.mysql-innodbcluster-instances.mysql-operator.svc.cluster.local:3306", 
                "role": "HA"
            }
        ], 
        "topologyMode": "Single-Primary"
    }
}

 MySQL  mysql-innodbcluster:3306 ssl  JS > cluster.status()
{
    "clusterName": "mysql_innodbcluster", 
    "defaultReplicaSet": {
        "name": "default", 
        "primary": "mysql-innodbcluster-0.mysql-innodbcluster-instances.mysql-operator.svc.cluster.local:3306", 
        "ssl": "REQUIRED", 
        "status": "OK", 
        "statusText": "Cluster is ONLINE and can tolerate up to ONE failure.", 
        "topology": {
            "mysql-innodbcluster-0.mysql-innodbcluster-instances.mysql-operator.svc.cluster.local:3306": {
                "address": "mysql-innodbcluster-0.mysql-innodbcluster-instances.mysql-operator.svc.cluster.local:3306", 
                "memberRole": "PRIMARY", 
                "mode": "R/W", 
                "readReplicas": {}, 
                "replicationLag": "applier_queue_applied", 
                "role": "HA", 
                "status": "ONLINE", 
                "version": "8.0.30"
            }, 
            "mysql-innodbcluster-1.mysql-innodbcluster-instances.mysql-operator.svc.cluster.local:3306": {
                "address": "mysql-innodbcluster-1.mysql-innodbcluster-instances.mysql-operator.svc.cluster.local:3306", 
                "memberRole": "SECONDARY", 
                "mode": "R/O", 
                "readReplicas": {}, 
                "replicationLag": "applier_queue_applied", 
                "role": "HA", 
                "status": "ONLINE", 
                "version": "8.0.30"
            }, 
            "mysql-innodbcluster-2.mysql-innodbcluster-instances.mysql-operator.svc.cluster.local:3306": {
                "address": "mysql-innodbcluster-2.mysql-innodbcluster-instances.mysql-operator.svc.cluster.local:3306", 
                "memberRole": "SECONDARY", 
                "mode": "R/O", 
                "readReplicas": {}, 
                "replicationLag": "applier_queue_applied", 
                "role": "HA", 
                "status": "ONLINE", 
                "version": "8.0.30"
            }
        }, 
        "topologyMode": "Single-Primary"
    }, 
    "groupInformationSourceMember": "mysql-innodbcluster-0.mysql-innodbcluster-instances.mysql-operator.svc.cluster.local:3306"
}
```

* 退出

如果想要退出 mysqlsh 的话可以直接输入 `\quit` 来完成。