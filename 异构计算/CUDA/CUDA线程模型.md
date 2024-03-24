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

![img](.assets/CUDA线程模型/v2-aa6aa453ff39aa7078dde59b59b512d8_1440w.png)

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

- <https://qiankunli.github.io/2021/08/18/gpu_utilization.html>
- <https://mp.weixin.qq.com/s/K_Yl-MD0SN4ltlG3Gx_Tiw>
