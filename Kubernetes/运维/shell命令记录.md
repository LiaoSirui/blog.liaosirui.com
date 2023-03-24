- 统计命名空间 pod 数量

```bash
kubectl get pods --all-namespaces | tail -n +2 | awk '{print $1}' | uniq -c
```

