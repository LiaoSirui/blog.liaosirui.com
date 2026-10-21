## WasmEdge 简介

WasmEdge 是一个高性能的 WebAssembly 运行时

WasmEdge 是轻量级、安全、高性能、可扩展、兼容 OCI 的软件容器与运行环境。目前是 CNCF 沙箱项目。WasmEdge 被应用在 SaaS、云原生，service mesh、边缘计算、边缘云、微服务、流数据处理等领域

官方：

- GitHub：<https://github.com/WasmEdge/WasmEdge>
- 官网：<https://wasmedge.org/>
- 文档：<https://wasmedge.org/book/en>

### 优势

- 是开源的，属于 CNCF
- 支持所有主要的 CPU 架构（x86、ARM、RISC-V）
- 支持所有主要操作系统（Linux、Windows、macOS）以及其他操作系统，例如 seL4 RTOS、Android
- 针对云原生和边缘应用程序进行了优化
- 可扩展并支持标准和新兴技术
  - 使用 Tensorflow、OpenVINO、PyTorch 进行人工智能推理
  - Tokio 的异步网络。 支持微服务、数据库客户端、消息队列等
  - 与容器生态、Docker 和 Kubernetes 无缝集成

## 安装 WasmEdge

- 下载 Wasmedge 二进制文件

前往 <https://github.com/WasmEdge/WasmEdge/releases> 下载对应平台的二进制文件

```bash
# refer: https://github.com/WasmEdge/WasmEdge/releases
export INST_WASMEDGE_VERSION=v0.12.1

cd $(mktemp -d)
curl -sL \
    https://github.com/WasmEdge/WasmEdge/releases/download/${INST_WASMEDGE_VERSION/v/}/WasmEdge-${INST_WASMEDGE_VERSION/v/}-manylinux2014_x86_64.tar.gz \
    -o WasmEdge.tgz
mkdir -p /usr/local/WasmEdge
tar zxf WasmEdge.tgz -C /usr/local/WasmEdge

export PATH=/usr/local/WasmEdge/WasmEdge-0.12.1-Linux/bin:$PATH
```

- 查看 Wasmedge 版本

```bash
> wasmedge --version

wasmedge version 0.12.1
```

## 优化二进制码

Wasm 是一个虚拟指令集，因此任何运行时的默认行为都是即时解释这些指令。 当然，这在某些情况下可能会让速度变慢。 因此，为了通过 WasmEdge 获得两全其美的效果，可以创建一个 AOT（提前编译）优化的二进制文件，它可以在当前机器上原生运行，但仍然可以在其他机器上进行解释
