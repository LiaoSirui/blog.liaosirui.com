## WorkQueue

```
k8s.io/client-go/util/workqueue/doc.go
```

- `Fair`

- `Stingy`

- `Multiple consumers and producers`

- `Shutdown notifications`

## 去重 / processing / dirty 的核心逻辑

```
k8s.io/client-go/util/workqueue/queue.go
```

重点看：

- `Add`

- `Get`

- `Done`

## 延迟入队

```
k8s.io/client-go/util/workqueue/delaying_queue.go
```

重点看：

- `AddAfter`

- `waitingLoop`

- `waitForPriorityQueue`

## 指数退避与默认 rate limiter

```
k8s.io/client-go/util/workqueue/default_rate_limiters.go
```

重点看：

- `DefaultTypedControllerRateLimiter`

- `TypedItemExponentialFailureRateLimiter`

- `TypedBucketRateLimiter`