修改 kubelet 参数

```bash
--cpu-manager-policy=“static”
--topology-manager-policy=single-numa-node
```

删除旧的 CPU 管理器状态文件

```bash
rm /var/lib/kubelet/cpu_manager_state
```

cpu-manager-policy有两种策略：none和static

- `none` 策略：显式地启用现有的默认 CPU 亲和方案，不提供操作系统调度器默认行为之外的亲和性策略。 通过 CFS 配额来实现 Guaranteed Pods 和 Burstable Pods 的 CPU 使用限制。
- `static` 策略：针对具有整数型 CPU requests 的 Guaranteed Pod， 它允许该类 Pod 中的容器访问节点上的独占 CPU 资源。这种独占性是使用 cpuset cgroup 控制器来实现的。

当启用 static 策略时，要求使用 `--kube-reserved` 和/或 `--system-reserved` 或 `--reserved-cpus` 来保证预留的 CPU 值大于 0 。 这是因为 0 预留 CPU 值可能使得共享池变空。

可独占性 CPU 资源数量等于节点的 CPU 总量减去通过 kubelet `--kube-reserved` 或  `--system-reserved` 参数保留的 CPU 资源。 从 1.17 版本开始，可以通过 kubelet `--reserved-cpus` 参数显式地指定 CPU 预留列表。 由 `--reserved-cpus` 指定的显式 CPU 列表优先于由 `--kube-reserved` 和  `--system-reserved` 指定的 CPU 预留。 通过这些参数预留的 CPU 是以整数方式，按物理核心 ID 升序从初始共享池获取的。

共享池是 BestEffort 和 Burstable Pod 运行的 CPU 集合。 Guaranteed Pod  中的容器，如果声明了非整数值的 CPU requests，也将运行在共享池的 CPU 上。 只有 Guaranteed Pod 中，指定了整数型 CPU requests 的容器，才会被分配独占 CPU 资源。

当 Guaranteed Pod 调度到节点上时，如果其容器符合静态分配要求， 相应的 CPU 会被从共享池中移除，并放置到容器的 cpuset 中。 因为这些容器所使用的 CPU 受到调度域本身的限制，所以不需要使用 CFS 配额来进行 CPU 的绑定。 换言之，容器 cpuset  中的 CPU 数量与 Pod 规约中指定的整数型 CPU limit 相等。 这种静态分配增强了 CPU 亲和性，减少了 CPU  密集的工作负载在节流时引起的上下文切换。

topology-manager-policy 策略：

- 策略为 single-numa-node 时，则 yaml 中的 CPU 个数一定不能超过最大每个 numa 的个数
- 策略为 best-effort 时，yaml 中 limit 的 cpu 和 request 的 cpu 设置相同且 cpu 值为整数，则为独占 CPU。
- 策略为 best-effort 时，yaml 中只设置了 limit，但没有设置 request 的 CPU，且 limit 设置的 CPU 为整数，则为独占 CPU。
- 策略为 best-effort 除了以上两种情况，都是为共享 CPU 池，不符合独占要求。

查看设置的 CPU 亲和性（绑核状态）

```bash
taskset -c -p $CONTAINER_PID
```

注意 CPU Manager 还有一个配置项 `--cpu-manager-reconcile-period`，用来配置 CPU Manager Reconcile Kubelet 内存中 CPU 分配情况到 cpuset cgroups 的修复周期。如果没有配置该项，那么将使用 `--node-status-update-frequency（default 10s）` 配置的值。