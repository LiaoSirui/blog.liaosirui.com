示例

```toml
[project]
  dependencies    = [
    "duckdb>=1.5.3,<1.6.0",
    "numpy>=2.4.6,<2.5.0",
    "pandas>=3.0.3,<3.1.0",
    "pip>=26.1.2",
    "pkgconfig>=1.6.0",
    "setuptools>=82.0.1",
    "wheel>=0.47.0",
]
  description     = "Add your description here"
  name            = "user-workspace-runtime"
  readme          = "README.md"
  requires-python = "==3.11.*"
  version         = "1.0.0"

[project.optional-dependencies]
  cpu = [
    "torch==2.7.1",
    "torchaudio==2.7.1",
    "torchvision==0.22.1",
    "lightgbm>=4.6.0,<4.7.0",
  ]
  cu128 = [
    "torch==2.7.1+cu128",
    "torchaudio==2.7.1+cu128",
    "torchvision==0.22.1+cu128",
    "lightgbm>=4.6.0,<4.7.0",
    "nvidia-cublas-cu12 ; platform_system == 'linux'",
    "nvidia-cuda-cupti-cu12 ; platform_system == 'linux'",
    "nvidia-cuda-nvrtc-cu12 ; platform_system == 'linux'",
    "nvidia-cuda-runtime-cu12 ; platform_system == 'linux'",
    "nvidia-cudnn-cu12 ; platform_system == 'linux'",
    "nvidia-cufft-cu12 ; platform_system == 'linux'",
    "nvidia-cufile-cu12 ; platform_system == 'linux'",
    "nvidia-curand-cu12 ; platform_system == 'linux'",
    "nvidia-cusolver-cu12 ; platform_system == 'linux'",
    "nvidia-cusparse-cu12 ; platform_system == 'linux'",
    "nvidia-cusparselt-cu12 ; platform_system == 'linux'",
    "nvidia-nccl-cu12 ; platform_system == 'linux'",
    "nvidia-nvjitlink-cu12 ; platform_system == 'linux'",
    "nvidia-nvtx-cu12 ; platform_system == 'linux'",
  ]

[tool.uv.sources]
  torch = [
    { index = "pypi-torch-cpu", extra = "cpu" },
    { index = "pypi-torch-cu128", extra = "cu128" },
  ]
  torchvision = [
    { index = "pypi-torch-cpu", extra = "cpu" },
    { index = "pypi-torch-cu128", extra = "cu128" },
  ]
  torchaudio = [
    { index = "pypi-torch-cpu", extra = "cpu" },
    { index = "pypi-torch-cu128", extra = "cu128" },
  ]
  nvidia-cublas-cu12 = { index = "pypi-nvidia" }
  nvidia-cuda-cupti-cu12 = { index = "pypi-nvidia" }
  nvidia-cuda-nvrtc-cu12 = { index = "pypi-nvidia" }
  nvidia-cuda-runtime-cu12 = { index = "pypi-nvidia" }
  nvidia-cudnn-cu12 = { index = "pypi-nvidia" }
  nvidia-cufft-cu12 = { index = "pypi-nvidia" }
  nvidia-cufile-cu12 = { index = "pypi-nvidia" }
  nvidia-curand-cu12 = { index = "pypi-nvidia" }
  nvidia-cusolver-cu12 = { index = "pypi-nvidia" }
  nvidia-cusparse-cu12 = { index = "pypi-nvidia" }
  nvidia-cusparselt-cu12 = { index = "pypi-nvidia" }
  nvidia-nccl-cu12 = { index = "pypi-nvidia" }
  nvidia-nvjitlink-cu12 = { index = "pypi-nvidia" }
  nvidia-nvtx-cu12 = { index = "pypi-nvidia" }

[tool.uv]
  conflicts = [
    [
        { extra = "cpu" },
        { extra = "cu128" },
    ],
  ]

  # lightgbm 编译时使用
  config-settings = { "cmake.define.USE_CUDA" = "ON" }

  allow-insecure-host = ["nexus-mirror.alpha-quant.tech"]

  override-dependencies = ["win32-setctime>=1.0.0"]

  [[tool.uv.index]]
    default = true
    name    = "pypi"
    url     = "http://nexus-mirror.alpha-quant.tech/repository/pypi/simple"

  # https://pypi.nvidia.cn
  [[tool.uv.index]]
    explicit = true
    name = "pypi-nvidia"
    url = "http://nexus-mirror.alpha-quant.tech/repository/pypi-nvidia"

  # https://mirrors.nju.edu.cn/pytorch
  [[tool.uv.index]]
    explicit = true
    name     = "pypi-torch-cpu"
    url      = "http://nexus-mirror.alpha-quant.tech/repository/pytorch/whl/cpu"

  [[tool.uv.index]]
    explicit = true
    name     = "pypi-torch-cu128"
    url      = "http://nexus-mirror.alpha-quant.tech/repository/pytorch/whl/cu128"

```

- CPU 环境

```bash
# using cpu
uv sync --all-groups --extra cpu
```

- GPU 环境

```bash
# using gpu
export UV_NO_BINARY_PACKAGE=lightgbm

uv sync --all-groups --extra cu128
```
