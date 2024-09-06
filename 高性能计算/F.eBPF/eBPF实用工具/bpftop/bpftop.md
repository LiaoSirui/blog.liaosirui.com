bpftop，一个旨在增强 eBPF 程序优化和监控的命令行实用程序。bpftop 可以提供 eBPF 程序实时运行的快照，显示程序执行的平均持续时间、每秒处理的事件数以及每个程序的总 CPU 使用率的近似值等指标

pftop 使用 `BPF_ENABLE_STATS` 命令从 eBPF 程序收集重要的性能数据。为了确保计算机平稳运行，数据收集默认处于关闭状态。bpftop 收集这些数据并计算有用的信息。收集的数据以类似于 top 命令的表格形式或以每 10 秒更新一次的图形形式显示。当 bpftop 停止运行时，也会停止收集统计信息。这个工具是用 Rust 编写的，并利用 libbpf-rs 和 ratatui 包来实现功能

官方：

- <https://github.com/Netflix/bpftop>

安装

```bash
curl -fLJ https://github.com/Netflix/bpftop/releases/latest/download/bpftop -o bpftop && chmod +x bpftop
```

