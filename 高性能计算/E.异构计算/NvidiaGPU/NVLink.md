## NVLink 简介

NVLink 网络主要用于服务器内 GPU 芯片之间互联，IB 网络主要用于服务器之间的互联

- 英伟达 H100 SXM 服务器内部的 8 块 GPU 是通过 NVSwitch 芯片做全互联，互联带宽 900GB/s（注意是大写 B，即 Byte）
- IB 网络 NDR 版的带宽是单向 400Gb/s（注意是小 b，即 bit），对齐口径，按双向换算为：400Gb/s÷8×2=100GB/s，单台机器的八张 IB 网卡总的速率才 800GB/s

2022 年，英伟达将 NVSwitch 芯片独立出来做成 NVLink 交换机（1U 设计，内置 2 个 NVSwitch3 芯片，共 32 个 OSFP 端口），用于连接主机之间的 GPU 设备

类似的互联技术，例如华为昇腾 HCCS、摩尔线程 MTLink、壁仞科技 Blink、寒武纪 MLU-Link 等芯片间互联技术