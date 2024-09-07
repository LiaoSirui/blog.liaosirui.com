## Ray 简介

Ray 是一种分布式应用程序的框架，为构建分布式应用程序提供简单、通用的 API

- 提供简单的用于构建和运行分布式应用程序的原语；
- 使最终用户能够并行化单个机器代码，代码更改很少甚至为零；
- 在核心 Ray 之上包括一个由应用程序、库和工具组成的大型生态系统，以支持复杂的应用程序

Ray 官方资料：

- GitHub：<https://github.com/ray-project/ray>

- 官方文档：<https://docs.ray.io/en/latest/index.html>

## Ray 启动方式

### 单机启动

调用`ray.init()`会在本机上启动Ray，这台机器成为头节点

```python
import ray

ray.init()
# ray.is_initialized() 用来检查 Ray 是否已经初始化
assert ray.is_initialized() == True

ray.shutdown()
assert ray.is_initialized() == False
```

当进程调用`ray.init()`终止时，Ray 运行时也将终止。

### 通过 CLI 启动 Ray

从 CLI使用`ray start`在机器上启动 1 节点 ray 运行时。这台机器成为“头节点”

```bash
ray start --head
```

这样启动后，在该节点上的程序可通过绑定`address='auto'`，来连接到该 Ray 集群

```python
import ray 
ray.init(address='auto')
```

## Ray 中的对象

在 Ray 中，可以创建和计算对象。将这些对象称为远程对象，并使用对象引用来引用它们。远程对象存储在共享内存对象存储中，集群中的每个节点都有一个对象存储。在集群设置中，实际上可能不知道每个对象存活在哪台机器上。

一个`ObjectRef`基本上是一个唯一的ID可以被用来指代一个远程对象。

可以通过多种方式创建对象引用。

> 1. 它们由远程函数调用返回
> 2. 它们由`ray.put`返回

通过`ray.get`获取它的值。

```bash
a = 1
object_ref = ray.put(a)
print(object_ref, ray.get(object_ref))
```

## 函数实践

通过`@ray.remote`装饰函数来声明要远程运行此函数，最后通过`func.remote()`调用它。这个调用将产生一个`futrues`或者`ObjectRef`，可以用`ray.get`获取它的值。

```python
import time
import ray

ray.init(num_cpus=5)

def f1():
    time.sleep(1)

@ray.remote
def f2():
    time.sleep(1)

t1 = time.time()
# 这个任务将消耗 5s
[f1() for _ in range(5)]
t2 = time.time()
print(t2 - t1)

# 这个任务只消耗 1s (如果服务器上有 5 个 cpu).
ray.get([f2.remote() for _ in range(5)])
print(time.time() - t2)
```

可以通过`ray.cancel(ObjectRef)`来取消远程函数

## Ray Actor Class 实践

actor 本质上是一个有状态的 worker（或 service）。当一个新的 actor 被实例化时，一个新的 worker 被创建，actor 的方法被调度到那个特定的 worker 上，并且可以访问和改变那个 worker 的状态

### actor 创建与使用

可以将 Python 类转化为Ray Actor Class：

```python
@ray.remote
class Counter(object):
    def __init__(self):
        self.value = 0

    def increment(self):
        time.sleep(1)
        self.value += 1
        return self.value

counter = Counter.remote()
r1 = [counter.increment.remote() for _ in range(5)]
print(ray.get(r1))
```

### actor 资源

actor 类可以设置默认实例需要的 cpu 和 gpu

```python
@ray.remote(num_cpus=2, num_gpus=1)
class GPUActor(object):
    pass
```

实例会被放置在满足资源条件的节点上，这些资源直到实例生命周期结束才会被释放（即使实例没有执行任务）。

同一个 actor 不同的实例可以通过 options 设置不同的资源：

```python
@ray.remote(num_cpus=4)
class Counter(object):
    pass

a1 = Counter.options(num_cpus=1).remote()
a2 = Counter.options(num_cpus=2).remote()
a3 = Counter.options(num_cpus=3).remote()
```

### 终止 actor

在 actor 中方法中终止 actor：

```python
@ray.remote
class Counter(object):
	def shutdown(self):
		ray.actor.exit_actor()
```

注意，这种终止方法将等待任何先前提交的任务完成执行后，再退出进程

也可以强制终止：

```python
ray.kill(actor_handle)
```

### 命名 actor

actor 可以在其命名空间内被赋予一个唯一的名称。这可以从 Ray 集群中的任何 worker 中检索 actor。actor 生命周期可以与 worker 分离，即使在 worker 的驱动程序进程退出后，actor 也可以持续存在。通过指定`lifetime="detached"`，使用实现生命周期与 worker 分离

验证：

首先通过 CLI 启动 ray：`ray start --head`

`demo1.py`：

```python
import ray

@ray.remote
class Actor:
    pass

ray.init(address="auto", namespace="actor_one")
a = Actor.options(name="actor1", lifetime="detached").remote()
# print(ray.get_actor("actor2", namespace="actor_two"))
```

`demo2.py`：

```python
import ray

@ray.remote
class ActorTwo:
    pass

ray.init(address="auto", namespace="actor_two")
a2 = ActorTwo.options(name="actor2", lifetime="detached").remote()
print(ray.get_actor("actor1", namespace="actor_one"))
```

## 设计模式

- actor tree

一组worker actor由一个supervisor actor管理：

示例：

```python
import time
import ray

@ray.remote(num_cpus=1)
class Worker:
    def work(self):
        time.sleep(1)
        return "end"

@ray.remote(num_cpus=1)
class Supervisor:
    def __init__(self):
        self.workers = [Worker.remote() for _ in range(3)]
    def work(self):
        return ray.get([w.work.remote() for w in self.workers])

ray.init()
sup = Supervisor.remote()
print(ray.get(sup.work.remote()))
```

如果 supervisor actor 死了，由于 actor 引用计数，worker actor 也会终止

- 使用 ray.wait 限制提交的任务数

当提交 ray 任务或 actor 调用时，ray 将确保数据可供工作人员使用。但是，如果快速提交过多任务，则 worker 可能会过载并耗尽内存。所以应该使用 ray.wait 进行阻塞，直到一定数量的任务准备就绪

```python
import time
import ray

@ray.remote(num_cpus=1)
class Actor:
    def time_sleep(self):
        time.sleep(1)
        
actor = Actor.remote()
task_limit = 4
result_refs = []
for i in range(100):
    print(result_refs, len(result_refs), sep="\n")
    if len(result_refs) > task_limit:
        num_ready = i-task_limit
        ray.wait(result_refs, num_returns=num_ready)
    result_refs.append(actor.time_sleep.remote())
```

## 反模式

- 在任务中尽可能少地调用`ray.get`

当`ray.get`被调用时，对象必须被转移到调用的工作者/节点`ray.get`。如果不需要在任务中操作对象，就直接处理对象引用

Bad:

```python
import ray

@ray.remote	
def generate_array(num):
    return range(num)

@ray.remote
def sum_array(array):
    return sum(array)

array1 = ray.get(generate_array.remote(10))
print(array1)
print(ray.get(sum_array.remote(array1)))
```

Better:

```python
import ray

@ray.remote	
def generate_array(num):
    return range(num)

@ray.remote
def sum_array(array):
    return sum(array)

array1 = generate_array.remote(10)
print(array1)
print(ray.get(sum_array.remote(array1)))
```

- 避免执行太细粒度的任务

并行化或分发任务通常比普通函数调用具有更高的开销。因此，如果并行化一个执行速度非常快的函数，可能比直接调用函数花费的时间更长

如果功能或任务太小，可以使用批处理的技术

Bad:

```python
import ray

@ray.remote
def double(number):
    return number * 2

numbers = list(range(10000))

doubled_numbers = []
for i in numbers:
    doubled_numbers.append(ray.get(double.remote(i)))
```

Better:

```python
import ray

@ray.remote
def double_list(list_of_numbers):
    return [number * 2 for number in list_of_numbers]

numbers = list(range(10000))
doubled_list_refs = []
BATCH_SIZE = 100
for i in range(0, len(numbers), BATCH_SIZE):
    batch = numbers[i : i + BATCH_SIZE]
    doubled_list_refs.append(double_list.remote(batch))

print(sum(ray.get(doubled_list_refs), []))
```

## 参考资料

- <https://www.51cto.com/article/681540.html>

- <https://www.cnblogs.com/fanzhidongyzby/p/7901139.html>
