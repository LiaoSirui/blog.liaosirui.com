- 统计命名空间 pod 数量

```bash
kubectl get pods --all-namespaces | tail -n +2 | awk '{print $1}' | uniq -c
```

- 清理无用 pod

```bash
kubectl get pods --all-namespaces --field-selector 'status.phase!=Running,status.phase!=Completed' | \
grep -E 'OOMKilled|Error|ContainerStatusUnknown|ImagePullBackOff|Evicted|OutOfmemory' | \
awk '{print "kubectl delete pod -n " $1 " " $2}' 
```

