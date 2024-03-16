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
