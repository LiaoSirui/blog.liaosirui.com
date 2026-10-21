## CPU 指标

| 指标名称               | 类型    | 含义                           |
| ---------------------- | ------- | ------------------------------ |
| node_cpu_seconds_total | Counter | 节点 CPU 的使用时间 (单位：秒) |

## CPU 基础信息

## CPU 频率

`node_cpu_frequency_max_hertz` 和 `node_cpu_frequency_min_hertz` 是硬件可以执行的作的限制。 `node_cpu_scaling_frequency_max_hertz` 和 `node_cpu_scaling_frequency_min_hertz` 是内核将保持在的限制范围内，并且可以在运行时进行调整。

`node_cpu_scaling_frequency_hertz` 是内核认为的当前频率。还有一个 `node_cpu_frequency_hertz`，它是硬件的当前频率值。

可以使用以下查询来获取 CPU 频率的度量值：

```bash
node_cpu_scaling_frequency_hertz
```

该指标表示每个CPU核心的时钟频率（赫兹）。它可以用于监视 CPU 的时钟速度，帮助了解 CPU 的性能和负载情况

## CPU 温度

| Name  | Description                                                  | OS    |
| ----- | ------------------------------------------------------------ | ----- |
| hwmon | Expose hardware monitoring and sensor data from `/sys/class/hwmon/`. | Linux |

指标

```bash
node_hwmon_temp_celsius
```

查询温度传感器的名称

```bash
node_hwmon_sensor_label{instance="192.168.16.140:9100", chip=~".+coretemp.+"}
```

查询温度传感器的温度值

```bash
node_hwmon_temp_celsius{instance="192.168.16.140:9100", chip=~".+coretemp.+"}
```

关联

```bash
0 * node_hwmon_sensor_label{instance="192.168.16.140:9100", chip=~".+coretemp.+"} + on (sensor) group_left(node_hwmon_temp_celsius) node_hwmon_temp_celsius{instance="192.168.16.140:9100", chip=~".+coretemp.+"}
```

画图

- 使用 stat panel

- 显示名：`${__field.labels.label}`

参考图表

- <https://grafana.com/grafana/dashboards/12950-hwmon/>

## CPU 使用率

```bash
node_cpu_seconds_total
```

该指标包括了多个标签，分别标记每种处理模式使用的CPU时间，该指标为counter类型。

```bash
# HELP node_cpu_seconds_total Seconds the CPUs spent in each mode.
# TYPE node_cpu_seconds_total counter
node_cpu_seconds_total{cpu="0",mode="idle"} 3.56934038e+06
node_cpu_seconds_total{cpu="0",mode="iowait"} 6208.33
node_cpu_seconds_total{cpu="0",mode="irq"} 0
node_cpu_seconds_total{cpu="0",mode="nice"} 398.62
node_cpu_seconds_total{cpu="0",mode="softirq"} 2759.47
node_cpu_seconds_total{cpu="0",mode="steal"} 0
node_cpu_seconds_total{cpu="0",mode="system"} 65250.09
node_cpu_seconds_total{cpu="0",mode="user"} 190913.76
node_cpu_seconds_total{cpu="1",mode="idle"} 3.56738873e+06
node_cpu_seconds_total{cpu="1",mode="iowait"} 8643.69
node_cpu_seconds_total{cpu="1",mode="irq"} 0
node_cpu_seconds_total{cpu="1",mode="nice"} 378.03
node_cpu_seconds_total{cpu="1",mode="softirq"} 2633.77
node_cpu_seconds_total{cpu="1",mode="steal"} 0
node_cpu_seconds_total{cpu="1",mode="system"} 65323.76
node_cpu_seconds_total{cpu="1",mode="user"} 190535.96
```

`mode="idle"` 代表 CPU 的空闲时间，所以我们只需要算出空闲的时间占比，再以总数减去该值 ，便可知道 CPU 的使用率，此处使用 irate 方法。

由于现有的服务器一般为多核，所以加上 avg 求出所有 cpu 的平均值，便是 CPU 的使用率情况 ，如下 ：

```bash
100 - avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) by (instance)* 100
```

```bash
System - cpu 在内核模式下执行的进程占比
sum by (mode)(irate(node_cpu_seconds_total{mode="system",instance=~"$node:$port",job=~"$job"}[5m])) * 100
 
User - cpu 在用户模式下执行的正常进程占比
sum by (mode)(irate(node_cpu_seconds_total{mode='user',instance=~"$node:$port",job=~"$job"}[5m])) * 100
 
Nice - cpu 在用户模式下执行的 nice 进程占比
sum by (mode)(irate(node_cpu_seconds_total{mode='nice',instance=~"$node:$port",job=~"$job"}[5m])) * 100
 
Idle - cpu 在空闲模式下的占比
sum by (mode)(irate(node_cpu_seconds_total{mode='idle',instance=~"$node:$port",job=~"$job"}[5m])) * 100
 
Iowait - cpu 在 io 等待的占比
sum by (mode)(irate(node_cpu_seconds_total{mode='iowait',instance=~"$node:$port",job=~"$job"}[5m])) * 100
 
Irq - cpu 在服务中断的占比
sum by (mode)(irate(node_cpu_seconds_total{mode='irq',instance=~"$node:$port",job=~"$job"}[5m])) * 100
 
Softirq - cpu 在服务软中断的占比
sum by (mode)(irate(node_cpu_seconds_total{mode='softirq',instance=~"$node:$port",job=~"$job"}[5m])) * 100
 
Steal - 在 VM 中运行时其他 VM 占用的本 VM 的 cpu 的占比
sum by (mode)(irate(node_cpu_seconds_total{mode='steal',instance=~"$node:$port",job=~"$job"}[5m])) * 100
 
Guest - 运行各种 VM 使用的 cpu 占比
sum by (mode)(irate(node_cpu_seconds_total{mode='guest',instance=~"$node:$port",job=~"$job"}[5m])) * 100
```
