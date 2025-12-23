Kyverno policy reports 是 Kubernetes 的自定义资源。每个 namespace 、每个集群都有对应的 policy report ，提供有关 policy 结果的信息（也包含违规行为）。

这里需要特别提下违规资源的问题（validationFailureAction=[audit, enforce]）。

- 当处于 audit 模式下 ，每当创建违反适用规则集的一个或多个规则的资源时，就会将结果添加到报告中。（资源删除时，报告对应的 item 也会被删除）
- 当处于 enforce 模式下 ，资源在创建时立即被阻止，报告中不会有。

Kyverno 创建和更新两种类型的报告（报告的内容取决于违规资源，而不是规则的存储位置）：

- ClusterPolicyReport - 集群范围的资源
- PolicyReport - namespace 级别的资源

使用 kubectl 来查看报告结果

```bash
kubectl get clusterpolicyreports
```

示例输出

```bash
NAME                                   KIND        NAME                      PASS   FAIL   WARN   ERROR   SKIP   AGE
57928e30-284a-4a1d-9516-3faa8f7be124   Namespace   cpaas-system              1      0      0      0       0      59s
5ca3b2b3-342b-4c01-ad93-06c840597c83   Namespace   cpaas-middleware-system   1      0      0      0       0      59s
773f965d-7dbb-4de3-b7ab-1ad107514d8b   Namespace   cpaas-logging-system      1      0      0      0       0      59s
7ed4695f-bcbc-4bf8-a09d-071fc34c36b9   Namespace   cpaas-monitoring-system   1      0      0      0       0      59s
f1e6b231-0245-45d9-96d3-c642eab2f52c   Namespace   cpaas-storage-system      1      0      0      0       0      59s
```

