简介

kube-monkey 会在一天的随机的一个时间点删除 pod，用来测试高可用服务在突发故障下是否仍能正常工作。

Kube-monkey 遵循混沌工程原理，可随机删除 K8s pod 并检查服务是否具有故障恢复能力，并提高系统健康性。

Kube-monkey 由 TOML 文件配置，可在其中指定要杀死的应用程序及恢复时间。

## 部署 kube-monkey

```bash
git clone https://github.com/asobti/kube-monkey.git

cd kube-monkey
helm install --name kube-monkey helm/kubemonkey
```

chart 模板中 debug 模式只支持配 enabled 和 schedule_immediate_kill 两个配置项，其他配置项需要 helm 部署之后，修改 kubemonkey-kube-monkey

configmap 的值

## kube-monkey 运行参数配置

可通过 `kubectl edit configmap -n <kube-monkey 安装命名空间> kubemonkey-kube-monke` 修改，修改完毕后需重建 kube-monkey 的 pod

```ini
[kubemonkey]

dry_run = true

run_hour = 8

start_hour = 10 # Don't schedule any pod deaths before 10am

end_hour = 16 # Don't schedule any pod deaths after 4pm

blacklisted_namespaces = [ "kube-system" ] # 不攻击的 namespace 列表

whitelisted_namespaces = [ "default" ] # 攻击的 namespace 列表

time_zone = "Asia/Shanghai" # 时区

[debug] # 无视 start_hour 配置和 end_hour 配置，每隔 60s 都会攻击 pod

enabled = false

schedule_immediate_kill = false

[notifications]

enabled = false

[notifications.attacks]



[kubemonkey]

dry_run = true

run_hour = 8

start_hour = 10 # Don't schedule any pod deaths before 10am

end_hour = 16 # Don't schedule any pod deaths after 4pm

blacklisted_namespaces = [ "kube-system" ] # 不攻击的 namespace 列表

whitelisted_namespaces = [ "default" ] # 攻击的 namespace 列表

time_zone = "Asia/Shanghai" # 时区

[debug] # 无视 start_hour 配置和 end_hour 配置，每隔 60s 都会攻击 pod

enabled = true

schedule_immediate_kill = false

[notifications]

enabled = true

reportSchedule = false

[notifications.attacks]

endpoint = "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=bec1f42f-5d6f-4854-a0a8-c91746d77b00"

headers = ["Content-Type:application/json"]

message = '{"msgtype": "markdown","markdown": {"content": "删除命名空间 {$namespace} 中的 {$name}\n执行时间：{$date}"}}'
```

## 工作负载标签

可以通过在 k8s app 中打如下几种 label 来让 kube-monkey 管理:

- kube-monkey/enabled：设置为 "enabled" 选择加入 kube-monkey

- kube-monkey/mtbf：平均故障间隔时间（以天为单位）。例如，如果设置为 "3"，则 k8s 应用程序预计大约每三个工作日就会杀死一个 Pod。

- kube-monkey/identifier：k8s 应用程序的唯一标识符。这用于识别属于 k8s 应用程序的 Pod，因为 Pods 从其 k8s 应用程序继承标签。因此，如果 kube-monkey 检测到该应用程序 foo 已注册成为受害者，kube-monkey 将查找具有标签的所有 pod。kube-monkey/identifier: foo 以确定哪些 pod 是候选者杀死。建议将此值设置为与应用名称相同。

- kube-monkey/kill-mode：默认行为是 kube-monkey 只杀死应用程序的一个 pod。您可以通过将值设置为：

- "kill-all" 如果您希望 kube-monkey 杀死所有 pod，而不管其状态如何（包括未准备好或未运行的 pod）。不需要杀伤值。小心使用这个标签。

- fixed 如果你想用 kill-value 杀死特定数量的正在运行的 pod。如果您过度指定，它将杀死所有正在运行的 pod 并发出警告。

- random-max-percent 指定可以杀死的最大百分比与杀死值。在预定时间，将终止一个统一随机指定百分比的正在运行的 Pod。

- fixed-percent 指定一个可以被杀死的带有 kill-value 的固定百分比。在预定的时间，指定的固定百分比的正在运行的 Pod 将被终止。

- kube-monkey/kill-value: 指定 kill-mode 的值

- 如果 fixed，提供整数个要杀死的 pod

- 如果 random-max-percent，提供一个 0-100 之间的数字来指定 kube-monkey 可以杀死的 pod 的最大百分比

- 如果 fixed-percent，提供一个 0-100 之间的数字来指定要杀死的 pod 的百分比

```yaml
labels:

kube-monkey/enabled: enabled

# kube-monkeypod

kube-monkey/identifier: monkey-victim

# () pod

kube-monkey/mtbf: '5'

# killpod

kube-monkey/kill-mode: "fixed"

# kill-all killpod

# fixed kill-valuepod

# random-max-percent kill-value pod

# fixed-percen kill-valuepod

kube-monkey/kill-value: '1'
```

使用如下脚本给 deployment 加标签

```bash
#!/usr/bin/env bash



global_namespace=$1

workloads=$(kubectl get deployment -n "${global_namespace}" |grep -v 'NAME'|awk '{print $1}')



sleep 1



for workload in ${workloads[@]}

do

echo "patch label for deployment ${workload}"

export workload

kubectl label deployment -n "${global_namespace}" "${workload}" kube-monkey/enabled=enabled --overwrite=true

kubectl label deployment -n "${global_namespace}" "${workload}" kube-monkey/identifier="${workload}" --overwrite=true

kubectl label deployment -n "${global_namespace}" "${workload}" kube-monkey/mtbf=5 --overwrite=true

kubectl label deployment -n "${global_namespace}" "${workload}" kube-monkey/kill-mode=fixed --overwrite=true

kubectl label deployment -n "${global_namespace}" "${workload}" kube-monkey/kill-value=1 --overwrite=true

yq -i '.spec.template.metadata.labels."kube-monkey/identifier" = strenv(workload)' patch.yaml

kubectl patch deployment -n "${global_namespace}" "${workload}" --patch-file patch.yaml

done
```

patch 的内容如下

```yaml
spec:

template:

metadata:

labels:

kube-monkey/enabled: enabled

kube-monkey/identifier: "wiki-js"

kube-monkey/kill-mode: fixed

kube-monkey/kill-value: "1"

kube-monkey/mtbf: "5"
```
