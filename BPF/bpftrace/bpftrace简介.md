## bpftrace 简介

bpftrace 是一个基于 Linux eBPF 的高级编程语言

语言的设计是基于 awk 和 C，以及之前的一些 tracer 例如 DTrace 和 SystemTap

bpftrace 使用了 LLVM 作为后端，来编译 compile 脚本为 eBPF 字节码，利用 BCC 作为库和 Linux eBPF 子系统、已有的监测功能、eBPF 附着点交互

## 入门程序

C++ 写一段 hello world 程序

```cpp
// main.cpp
#include <unistd.h>
#include <iostream>

using namespace std;

int hello(int i) 
{
    cout<<"hello world " << i << " ." << endl;
    // sleep(0);
    return i;
}

int main(int argc, char *argv[])
{
    for(int i = {0}; i < 3; i++) 
    {
        hello(i);
    }
    return 0;
}

```

编译并执行

```bash
# 编译
g++ main.cpp -o main

# 执行
./main
```

假设就是要确认一下 hello 这个函数，每执行一次耗时是多久

pftrace 的语法与其它的编程语言有着比较大的差异，总的来讲它的模式是这样的：

```cpp
probe /condition/ { action }
```

- probe 就是我们追踪项
- condition 指的过滤条件（只追踪特定 pid 也可以不指定）
- action 对应捕捉到之后要执行的动作

使用如下的程序

```cpp
// trace-hello-func-time-cost.bt
#!/usr/bin/env bpftrace 

// BEGIN 和 END 是两个特别的 probe，由于不需要过滤条件，所以 condition 部分就省略了
// 追踪启动时执行的 action 
BEGIN 
{
    printf("**** start trace main.hello function time cost ****\n");
}

// 函数开始执行时对应的 action 
uprobe:/code/code.liaosirui.com/z-demo/ebpf/main:hello 
{   // 记录一下开始执行的时候到 @start[cmmm] 变量中
    print("enter function hello .");
    @start[comm] = nsecs;
}

// 函数执行完成对应的 action
uretprobe:/code/code.liaosirui.com/z-demo/ebpf/main:hello  / @start[comm] /
{   // 取得函数返回时的时间，并计算耗时
    // 清理 @start[comm] 变量为下一次执行做准备
    print("exit  function hello .");
    printf("time-cost %d (ns) \n\n", (nsecs - @start[comm]));
    delete(@start[comm]);
}

// 追踪退出时要执行 action 
END 
{
    printf("**** end trace main.hello function time cost   ****\n");
    clear(@start);
}

```

执行 bpftrace 追踪程序

```bash
bpftrace trace-hello-func-time-cost.bt
```

执行刚才的 C++ 程序

```bash
./main
```

追踪程序会打印 hello 函数的执行耗时

```bash
Attaching 4 probes...
**** start trace cpps.hello function time cost ****
enter function hello .
exit  function hello .
time-cost 20298 (ns)

enter function hello .
exit  function hello .
time-cost 2985 (ns)

enter function hello .
exit  function hello .
time-cost 2034 (ns)
```

