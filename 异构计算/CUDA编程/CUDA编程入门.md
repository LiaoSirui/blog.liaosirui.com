## CUDA

CUDA 是建立在 NVIDIA 的 CPUs 上的一个通用并行计算平台和编程模型，基于 CUDA 编程可以利用 GPUs 的并行计算引擎来更加高效地解决比较复杂的计算难题

CUDA 是 NVIDIA 公司所开发的 GPU 编程模型，它提供了 GPU 编程的简易接口，基于 CUDA 编程可以构建基于 GPU 计算的应用程序

CUDA 提供了对其它编程语言的支持，如 C/C++，Python，Fortran 等语言

<img src=".assets/CUDA%E7%BC%96%E7%A8%8B%E5%85%A5%E9%97%A8/v2-708897c8e1b627e3b08de922412a3347_1440w.webp" alt="img" style="zoom:50%;" />

### 异构计算

GPU 并不是一个独立运行的计算平台，而需要与 CPU 协同工作，可以看成是 CPU 的协处理器，因此当我们在说 GPU 并行计算时，其实是指的基于 CPU+GPU 的异构计算架构

在异构计算架构中，GPU 与 CPU 通过 PCIe 总线连接在一起来协同工作，CPU 所在位置称为为主机端（host），而 GPU 所在位置称为设备端（device），如下图所示

![img](.assets/CUDA%E7%BC%96%E7%A8%8B%E5%85%A5%E9%97%A8/v2-df49a98a67c5b8ce55f1a9afcf21d982_1440w.png)

可以看到 GPU 包括更多的运算核心，其特别适合数据并行的计算密集型任务，如大型矩阵运算，而 CPU 的运算核心较少，但是其可以实现复杂的逻辑运算，因此其适合控制密集型任务

另外，CPU 上的线程是重量级的，上下文切换开销大，但是 GPU 由于存在很多核心，其线程是轻量级的

因此，基于 CPU+GPU 的异构计算平台可以优势互补，CPU 负责处理逻辑复杂的串行程序，而 GPU 重点处理数据密集型的并行计算程序，从而发挥最大功效

![img](.assets/CUDA%E7%BC%96%E7%A8%8B%E5%85%A5%E9%97%A8/v2-2959e07a36a8dc8f59280f53b43eb9d1_1440w-20230323214109589.webp)

## CUDA 安装

官方文档：<https://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html>

安装需要的包

```bash
dnf install kernel-devel-$(uname -r) kernel-headers-$(uname -r)
```

安装 cuda 仓库

```bash
export distro=rhel9
export arch=x86_64

dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/$distro/$arch/cuda-$distro.repo
```

安装 cuda

```bash
dnf module install nvidia-driver:latest-dkms

dnf install cuda

# GDS
dnf install nvidia-gds
```

配置 share 库的软链，部分库可能会用到

```bash
ls -al /usr/lib{,64}/nvidia
ls -al /usr/lib/libcuda.so /usr/lib64/libcuda.so

# 如果没有，再执行：
# ln -s /usr/lib/nvidia/libcuda.so /usr/lib/libcuda.so
# ln -s /usr/lib64/nvidia/libcuda.so /usr/lib64/libcuda.so
```

安装完成后：

```bash
export PATH=/usr/local/cuda-12.1/bin${PATH:+:${PATH}}

export LD_LIBRARY_PATH=/usr/local/cuda-12.1/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
```

开启持久化服务

```bash
systemctl enable --now nvidia-persistenced
```

安装第三方包

```bash
dnf install -y freeglut-devel libX11-devel libXi-devel libXmu-devel \
  make mesa-libGLU-devel freeimage-devel
```

## CUDA 编程模型基础

CUDA 编程模型是一个异构模型，需要 CPU 和 GPU 协同工作

### host 和 device

在 CUDA 中，两个重要的概念

- host：用 host 指代 CPU 及其内存

- device：用 device 指代 GPU 及其内存

CUDA 程序中既包含 host 程序，又包含 device 程序，它们分别在 CPU 和 GPU 上运行；同时，host 与 device 之间可以进行通信，这样它们之间可以进行数据拷贝

典型的 CUDA 程序的执行流程如下：

1. 分配 host 内存，并进行数据初始化
2. 分配 device 内存，并从 host 将数据拷贝到 device 上
3. 调用 CUDA 的核函数在 device 上完成指定的运算
4. 将 device 上的运算结果拷贝到 host 上
5. 释放 device 和 host 上分配的内存

### kernel

上面流程中最重要的一个过程是调用 CUDA 的核函数来执行并行计算

kernel 是 CUDA 中一个重要的概念，kernel 是在 device 上线程中并行执行的函数，核函数用 `__global__` 符号声明，在调用时需要用 `<<<grid, block>>>` 来指定 kernel 要执行的线程数量，在 CUDA 中，每一个线程都要执行核函数，并且每个线程会分配一个唯一的线程号 thread ID，这个 ID 值可以通过核函数的内置变量 threadIdx 来获得

由于 GPU 实际上是异构模型，所以需要区分 host 和 device 上的代码，在 CUDA 中是通过函数类型限定词开区别 host 和 device 上的函数，主要的三个函数类型限定词如下：

- `__global__`：在 device 上执行，从 host 中调用（一些特定的 GPU 也可以从 device 上调用），返回类型必须是 void，不支持可变参数参数，不能成为类成员函数。注意用`__global__`定义的 kernel 是异步的，这意味着 host 不会等待 kernel 执行完就执行下一步
- `__device__`：在 device 上执行，单仅可以从 device 中调用，不可以和 `__global__`同时用
- `__host__`：在 host 上执行，仅可以从 host 上调用，一般省略不写，不可以和`__global__` 同时用，但可和 `__device__`，此时函数会在 device 和 host 都编译

要深刻理解 kernel，必须要对 kernel 的线程层次结构有一个清晰的认识：

- GPU 上很多并行化的轻量级线程
- kernel 在 device 上执行时实际上是启动很多线程，一个 kernel 所启动的所有线程称为一个网格（grid），同一个网格上的线程共享相同的全局内存空间，grid 是线程结构的第一层次，而网格又可以分为很多线程块（block），一个线程块里面包含很多线程，这是第二个层次
- 线程两层组织结构如下图所示，这是一个 gird 和 block 均为 2-dim 的线程组织

![img](.assets/CUDA%E7%BC%96%E7%A8%8B%E5%85%A5%E9%97%A8/v2-aa6aa453ff39aa7078dde59b59b512d8_1440w.png)

grid 和 block 都是定义为 dim3 类型的变量，dim3 可以看成是包含三个无符号整数（x，y，z）成员的结构体变量，在定义时，缺省值初始化为 1

因此 grid 和 block 可以灵活地定义为 1-dim，2-dim 以及 3-dim 结构，对于图中结构（主要水平方向为 x 轴），定义的 grid 和 block 如下所示，kernel 在调用时也必须通过执行配置 `<<<grid, block>>> `来指定 kernel 所使用的线程数及结构

```cpp
dim3 grid(3, 2);
dim3 block(5, 3);
kernel_fun<<< grid, block >>>(prams...);
```

所以，一个线程需要两个内置的坐标变量`(blockIdx，threadIdx)`来唯一标识，它们都是`dim3`类型变量，其中

- blockIdx 指明线程所在 grid 中的位置
- threaIdx 指明线程所在 block 中的位置

如图中的 `Thread (1,1)` 满足：

```cpp
blockIdx.x = 1
blockIdx.y = 1

threadIdx.x = 1
threadIdx.y = 1
```

## 参考资料

- <https://zhuanlan.zhihu.com/p/34587739>
- <https://lulaoshi.info/gpu/python-cuda/numba.html#%E5%AE%89%E8%A3%85%E6%96%B9%E6%B3%95>
