## CUDA 简介

CUDA 是 “Compute Unified Device Architecture” 的缩写，意为统一计算设备架构，它是由 NVIDIA 公司 2006 年创建的一种并行计算平台和应用程序编程接口，允许开发者通过 CUDA 利用 GPU 的强大处理能力进行高性能的并行计算。CUDA 支持 C 和 C++ 等标准编程语言，以及 OpenCL 和 DirectCompute 等用于 GPU 计算的 API。此外 NVIDIA 还提供了全套工具包，包括编译器、调试器、分析器、库等，以支持开发人员将 CUDA 架构应用于生产质量的产品

CUDA 是建立在 NVIDIA 的 CPUs 上的一个通用并行计算平台和编程模型，基于 CUDA 编程可以利用 GPUs 的并行计算引擎来更加高效地解决比较复杂的计算难题

CUDA 是 NVIDIA 公司所开发的 GPU 编程模型，它提供了 GPU 编程的简易接口，基于 CUDA 编程可以构建基于 GPU 计算的应用程序

CUDA 提供了对其它编程语言的支持，如 C/C++，Python，Fortran 等语言

![image-20240324002442952](.assets/CUDA简介/image-20240324002442952.png)

## 安装 CUDA

打开 NVIDIA CUDA 下载官网：<https://developer.nvidia.com/cuda-downloads>

按照提示安装完成后，配置下系统环境变量

```bash
export LD_LABRARY=$LD_LIBRARY_PATH:/usr/local/cuda-12.3/lib64
export PATH=$PATH:/usr/local/cuda-12.3/bin
export CUDA_HOME=$CUDA_HOME:/usr/local/cuda-12.3
export PATH=/usr/local/cuda/bin:$PATH
```

分别执行 `nvidia-smi` 和 `nvcc -V` 命令验证安装

## 访问方式

编写 CUDA 程序访问 GPU 有两种 API：

- `Driver API`
- `Runtime API`

CUDA 版本对应的 runtime API 文档可在 NVIDIA 官网查看：

- CUDA 版本：<https://developer.nvidia.com/cuda-toolkit-archive>
- CUDA 12.3 的 runtime API 文档：<https://docs.nvidia.com/cuda/archive/12.3.0/cuda-runtime-api/index.html>

## 入门程序

nvcc 编译器支持纯 C/C++ 代码编译

```c
#include<stdio.h>

__global__ void hello_world()
{
        printf("hello world\n");
}

int main()
{
        hello_world<<<2, 2>>>();
        cudaDeviceSynchronize();
        return 0;
}
```

使用 nvcc 编译执行

```bash
> nvcc cuda.cu -o cuda_hello

> ./cuda_hello
hello world
hello world
hello world
hello world
```

- 第 1 行：引入头文件 `stdio.h`，这和 c 语言是一样的

- 第 3~6 行：如果把`__global__`去掉，其实就是一个普通的 c 语言函数，这个函数使用 printf 输出 hello world，没有入参，返回值是 void

  - `__global__`是一种 CUDA 编程特定修饰前缀，除了`__global__`，CUDA 有其他特定的修饰前缀，分别是`__host__`和`__device__`，这三种修饰前缀的含义分别为：

    - `__host__`：与 C/C++ 中函数相同，由CPU调用CPU执行的函数

    - `__global__`：表示一个核函数，是一组由 GPU 执行的并行计算任务，具体并行度在函数调用处指定。核函数必须是CPU 调用

    - `__device__`：表示一个由 GPU 中一个线程调用的函数。由于 Tesla 架构的 GPU 允许线程调用函数，因此实际上是将`__device__` 函数以 `__inline` 形式展开后直接编译到二进制代码中实现的，并不是真正的函数

- 第 8 行，c 语言的 main 函数入口
- 第 10 行，核函数调用。与普通 C/C++ 函数调用不同，该核函数调用时多了三对尖括号，并且尖括号里有两个逗号分隔的数字。尖括号中的数字是用来指定核函数执行的线程数，其中第一个数字指的是线程块的个数，第二个数值指的是每个线程块中线程的数量；很显然 `<<<2, 2>>>` 的写法就是表示指定 2 个线程块、每个线程块 2 个线程来执行这个核函数，因此总共有 `2*2=4` 个线程会执行这个核函数，所以输出内容有 4 行 hello world
- 第 11 行，同步 host 与 device，促使缓冲区刷新，从而在终端打印 hello world；因核函数具有异步性，CPU 并不会等待 GPU 核函数执行完毕再继续执行后续代码，如果不调用 cudaDeviceSynchronize 函数，CPU 逻辑都执行完程序退出了，就无法打印 hello world
- 第 12 行，main 函数返回 0，表示执行成功

核函数除了需要加`__global__`前缀修饰，还有一些注意事项：

- 核函数要求函数的返回值必须是 void
- 核函数只能访问 GPU 内存，也就是显存
- 核函数不能使用变长参数
- 核函数不能使用静态变量
- 核函数不能使用函数指针
- 核函数具有异步性
- 核函数不支持 c++ 的 iostream
