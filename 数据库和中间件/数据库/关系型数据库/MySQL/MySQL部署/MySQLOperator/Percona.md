Percona Server是Percona公司的MySQL分支，随着Percona公司业务范围的扩大，这个分支应该叫“Percona Server for MySQL”更为合适。

根据Percona公司的说法，Percona Server是一个开放的，全面兼容的，高性能的，开源的MySQL分支，且能安全替代MySQL。

与MariaDB的理念不同，Percona Server是紧跟MySQL的，在兼容的路上走得很远，而且自己实现了很多只有MySQL企业版中才有的功能，例如线程池，审计插件等功能。

Percona Server默认引擎是XtraDB，这是InnoDB的增强版，完全兼容InnoDB。


### 安装 operator


helm chart：git@github.com:percona/percona-helm-charts.git

```
gco pxc-operator-1.11.1

cd charts/pxc-operator
helm install pxc-operator --namespace aipaas-system --create-namespace .
```

部署完成后

```
NAME: pxc-operator
LAST DEPLOYED: Wed Sep 21 10:19:06 2022
NAMESPACE: aipaas-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
1. pxc-operator deployed.
  If you would like to deploy an pxc-cluster set cluster.enabled to true in values.yaml
  Check the pxc-operator logs
    export POD=$(kubectl get pods -l app.kubernetes.io/name=pxc-operator --namespace aipaas-system --output name)
    kubectl logs $POD --namespace=aipaas-system
```

源码：

https://github.com/percona/percona-server-mysql-operator

git@github.com:percona/percona-server-mysql-operator.git


## 安装 pxc-cluster


helm chart：git@github.com:percona/percona-helm-charts.git

pxc operator 文档

https://www.percona.com/doc/kubernetes-operator-for-pxc/index.html<br />

```
gco pxc-db-1.11.6

cd charts/pxc-db
```

默认提供了一个 production 配置参考：https://github.com/percona/percona-helm-charts/blob/pxc-db-1.11.6/charts/pxc-db/production-values.yaml