`alignas(64)` 是 C++11 引入的**对齐说明符（alignment specifier）**，用于指定类型或变量的内存对齐要求。

```cpp
class alignas(64) OrderBook {
    // ...
};
```

这表示 OrderBook 类的每个实例在内存中的起始地址必须是 64 字节的整数倍。

```cpp
#include <iostream>

class alignas(64) OrderBook {
    int data;
};

int main() {
    std::cout << alignof(OrderBook) << std::endl;  // 输出: 64
    std::cout << sizeof(OrderBook) << std::endl;    // 输出: 64（会填充到对齐边界）

    OrderBook book;
    // book 的地址一定是 64 的倍数
    std::cout << ((uintptr_t)&book % 64) << std::endl;  // 输出: 0
}
```

对于 `OrderBook` 类使用 `alignas(64)` 是为了：

1.  防止 false sharing — 多个线程各自处理不同的订单簿，确保它们不在同一缓存行
2.  提升缓存命中率 — 订单簿的热数据完整地落在缓存行内，避免跨行访问

这是低延迟系统中非常常见的优化手段。

（1）缓存行对齐

现代 CPU 的 L1 缓存行（cache line）通常是 64 字节。对齐到 64 字节可以：

```cpp
// 避免 "false sharing"（伪共享）
// 当多个线程访问不同对象时，如果它们在同一缓存行上，会导致性能下降

class alignas(64) OrderBook {
    std::atomic<int> bid_price;
    std::atomic<int> ask_price;
    // ...
};

// 如果有数组：
OrderBook books[10];
// 每个元素都在独立的缓存行上，不同线程操作不同 book 不会互相干扰
```

（2）SIMD 指令要求

某些 SIMD 指令（如 AVX-512）要求数据对齐到特定边界。

```cpp
// 没有对齐要求
class Normal {
    int x;  // 地址可能是任意值，如 0x1004
};

// 64 字节对齐
class alignas(64) Aligned {
    int x;  // 地址一定是 64 的倍数，如 0x1000, 0x1040, 0x1080...
};
```

