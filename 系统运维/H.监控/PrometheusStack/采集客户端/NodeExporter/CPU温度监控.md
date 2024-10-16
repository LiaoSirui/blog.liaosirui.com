## CPU 温度

| Name  | Description                                                  | OS    |
| ----- | ------------------------------------------------------------ | ----- |
| hwmon | Expose hardware monitoring and sensor data from `/sys/class/hwmon/`. | Linux |

指标

```
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

## CPU 频率

可以使用以下查询来获取 CPU 频率的度量值：

```ebnf
node_cpu_frequency_hertz
```

该指标表示每个CPU核心的时钟频率（赫兹）。它可以用于监视 CPU 的时钟速度，帮助了解 CPU 的性能和负载情况

通过以下查询语句来获取 CPU 实时最大频率的度量指标：

```
max_over_time(node_cpu_frequency_max_hertz[1m])
```

