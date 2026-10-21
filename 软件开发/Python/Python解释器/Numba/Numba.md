## Numba

Numba 是一个针对 Python 的开源 JIT 编译器，由 Anaconda 公司主导开发

Numba 会将这些函数使用即时编译 JIT 方式编译成机器码，这些代码将以近乎机器码的速度运行

官方：

- 官网 <https://numba.pydata.org/>
- GitHub 仓库 <https://github.com/numba/numba>

优势：

- 可以对 Python 原生代码进行 CPU 和 GPU 加速

- Numba 对 NumPy 数组和函数非常友好

目前，Numba 对以下环境进行了支持：

- 操作系统：Windows（32 位和 64 位），macOS，Linux（32 位和 64 位）
- CPU 微架构：x86，x86_64，ppc64，armv7l 和 armv8l
- GPU：NVIDIA CUDA 和 AMD ROCm
- CPython
- NumPy 1.15 以后的版本

## 安装

官方文档：<https://numba.pydata.org/numba-doc/latest/user/installing.html>

使用`conda`安装 Numba：

```bash
conda install numba
```

或者使用`pip`安装：

```bash
pip3 install numba
```

安装完成后查看版本，确定安装是否成功

```bash
python3 -c 'import numba;print(numba.__version__)'

# or: numba --sysinfo
numba -s
```

## 入门

使用 Numba 非常方便，只需要在 Python 原生函数上增加一个装饰器（Decorator）

只需要在原来的代码上添加一行 `@jit`，即可将一个函数编译成机器码，其他地方都不需要更改

```python
"""
Demo for numba
"""
import numpy as np
from numba import jit

SIZE = 2000
x = np.random.random((SIZE, SIZE))


@jit
def jit_tan_sum(arr):  # 函数在被调用时编译成机器语言
    """
    给定 n*n 矩阵, 对矩阵每个元素计算 tanh 值, 然后求和。
    因为要循环矩阵中的每个元素，计算复杂度为 n*n
    """
    tan_sum = 0
    for i in range(SIZE):  # Numba 支持循环
        for j in range(SIZE):
            tan_sum += np.tanh(arr[i, j])  # Numba 支持绝大多数 NumPy 函数
    return tan_sum


print(jit_tan_sum(x))

```

