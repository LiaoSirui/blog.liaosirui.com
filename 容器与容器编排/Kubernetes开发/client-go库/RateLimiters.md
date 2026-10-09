```
k8s.io/client-go/util/workqueue/default_rate_limiters.go
```

重点看：

- `DefaultTypedControllerRateLimiter`
- `TypedItemExponentialFailureRateLimiter`
- `TypedBucketRateLimiter`