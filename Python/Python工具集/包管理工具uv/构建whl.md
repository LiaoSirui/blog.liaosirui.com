## PEP 427

Python `.whl` (Wheel) 文件命名遵循 PEP 427 标准，结构为：

```bash
{distribution}-{version}(-{build})?-{python}-{abi}-{platform}.whl
```

它包含包名、版本、构建标签、Python 版本、ABI 和平台信息，确保 `pip` 能准确识别兼容性

详细字段解释：

- 包名 (Distribution): 库的名称，例如 `numpy`, `flask`。
- 版本 (Version): 例如 `1.21.0`。
- 构建标签 (Build Tag): 可选，用于标识同一版本下的重新构建（如 `1`），通常省略。
- Python 标签 (Python Tag): 兼容的 Python 解释器。如 `py2.py3` (通用), `cp39` (CPython 3.9), `pp37` (PyPy 3.7)。
- ABI 标签 (ABI Tag): 二进制接口。如 `none` (纯 Python), `cp39` (CPython 3.9), `cp39m` (CPython 3.9 且有 pydebug 或 pymalloc)。
- 平台标签 (Platform Tag): 兼容的操作系统。如 `any` (通用), `win_amd64`, `linux_x86_64`, `macosx_10_9_x86_64`

示例：

`numpy-1.21.0-cp39-cp39-win_amd64.whl`

- 包名: numpy
- 版本: 1.21.0
- Python: CPython 3.9
- ABI: cp39
- 平台: Windows 64 位

## 手动打包

为每个 Python 版本创建独立虚拟环境

```python
# 为Python 3.10创建环境
uv venv --python 3.10 .venv-3.10

# 为Python 3.11创建环境
uv venv --python 3.11 .venv-3.11

# 为Python 3.12创建环境
uv venv --python 3.12 .venv-3.12
```

批量打包多版本

```bash
#!/bin/bash
# 批量打包多版本脚本

# 定义目标Python版本
VERSIONS=("3.10" "3.11" "3.12")

for v in "${VERSIONS[@]}"; do
  # 创建版本专属环境
  uv venv --python $v .venv-$v
  source .venv-$v/bin/activate
  
  # 执行构建并重命名输出文件
  uv build
  mv dist/*.whl dist/your_package-1.0.0-py3-$v-none-any.whl
  
  # 清理环境
  deactivate
done
```

