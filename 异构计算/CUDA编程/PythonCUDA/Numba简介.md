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

### Python 解释器工作原理

Python是一门解释语言，Python为我们提供了基于硬件和操作系统的一个虚拟机，并使用解释器将源代码转化为虚拟机可执行的字节码

字节码在虚拟机上执行，得到结果

![Python解释器工作原理](.assets/Numba%E7%AE%80%E4%BB%8B/python-intrepretor-eb27cb5b.jpg)

- Python 解释器

使用 `python example.py` 来执行一份源代码时，Python 解释器会在后台启动一个字节码编译器（Bytecode Compiler），将源代码转换为字节码；字节码是一种只能运行在虚拟机上的文件，Python 的字节码默认后缀为 `.pyc`，Python 生成 `.pyc` 后一般放在内存中继续使用，并不是每次都将 `.pyc` 文件保存到磁盘上；有时候会看到自己 Python 代码文件夹里有很多 `.pyc` 文件与 `.py` 文件同名，但也有很多时候看不到 `.pyc` 文件；pyc 字节码通过 Python 虚拟机与硬件交互

虚拟机的出现导致程序和硬件之间增加了中间层，运行效率大打折扣

- Just-In-Time

Just-In-Time（JIT）技术为解释语言提供了一种优化，它能克服上述效率问题，极大提升代码执行速度，同时保留 Python 语言的易用性

使用 JIT 技术时，JIT 编译器将 Python 源代码编译成机器直接可以执行的机器语言，并可以直接在 CPU 等硬件上运行；这样就跳过了原来的虚拟机，执行速度几乎与用 C 语言编程速度并无二致

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

