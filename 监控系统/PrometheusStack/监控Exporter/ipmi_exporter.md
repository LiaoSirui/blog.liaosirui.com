## IPMI Exporter

IPMI Exporter 支持通过常规的 /metrics 接口暴露数据，以及通过 RMCP 支持 IPMI 的 /ipmi 接口，RMCP 是一个运行在一台主机上的导出器可以通过传递 target 参数来监视大量的 IPMI 接口。

IPMI Exporter 依赖 FreeIPMI 套件中的工具去实现对实际的 IPMI 的执行。

- Github 仓库：<https://github.com/prometheus-community/ipmi_exporter>

## 配置

配置文档：<https://github.com/prometheus-community/ipmi_exporter/blob/master/docs/configuration.md>

FreeIPMI 的配置参数在：`/etc/freeipmi/freeipmi.conf`

但是更推荐修改 ipmi_exporter 参数，参考：<https://github.com/prometheus-community/ipmi_exporter/blob/master/ipmi_remote.yml>

```yaml
modules:
  default:
    user: "admin"
    pass: "admin123"
    driver: "LAN_2_0"
    privilege: "admin"
    timeout: 10000
    collectors:
      - bmc
      # - bmc-watchdog
      - ipmi
      - chassis
      - dcmi
      - sel
      # - sm-lan-mode
    custom_args:
      ipmi:
        - "--bridge-sensors"

```

## 可获取的指标

IPMI Exporter 可以获取很多指标，比如一些元数据、BMC 信息、 Chassis Power 状态、电力消耗、系统事件日志信息、超微 LAN 模式的设置、传感器信息，传感器信息包括温度传感器、风扇转速传感器、电压传感器、电流传感器、电源传感器、其他传感器 。

指标文档：<https://github.com/prometheus-community/ipmi_exporter/blob/master/docs/metrics.md>

CPU 温度信息

```bash
ipmi_temperature_celsius{name=~"CPU Temperature"}
```

## Non-Root

如果以非特权用户的身份运行 IPMI Exporter，但需要以 root 用户的身份执行 FreeIPMI 工具，可以这样做:

在 sudoers 文件中运行下列命令的执行

```bash
ipmi-exporter ALL = NOPASSWD: /usr/sbin/ipmimonitoring,\
                              /usr/sbin/ipmi-sensors,\
                              /usr/sbin/ipmi-dcmi,\
                              /usr/sbin/ipmi-raw,\
                              /usr/sbin/bmc-info,\
                              /usr/sbin/ipmi-chassis,\
                              /usr/sbin/ipmi-sel
```

在模块配置中，使用 sudo 覆盖收集器命令，并将实际命令添加为自定义参数

```yaml
collector_cmd:
  ipmi: sudo
custom_args:
  ipmi:
    - "ipmimonitoring"
```

配置文件参考：<https://github.com/prometheus-community/ipmi_exporter/blob/master/ipmi_local_sudo.yml>