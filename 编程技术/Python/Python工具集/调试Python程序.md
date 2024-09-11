## 调试方式

### faulthandler

利用 python3 的 faulthandler，可定位到出错的代码行

```python
import faulthandler
faulthandler.enable()
```

或者直接通过命令行来启用，运行时添加 - X faulthandler 参数即可：

```bash
python -X faulthandler your_script.py
```

### gdb

利用 gdb，操作方式如下

```bash
gdb python
(gdb) run /path/to/your_script.py
## wait for segfault ##
(gdb) backtrace
## stack trace of the py code

```

追踪产生 segmenttation fault 的位置及代码函数调用情况：

```bash
gdb>bt
```

### pdb

从 Python 版本 3.7 开始，有一个新的名为 `breakpoint()` 的内置函数可以用来放置断点

可以通过运行以下代码来实现同样的效果：

```python
import pdb

# 设置断点，进入调试模式
pdb.set_trace()

```

可以使用`n`（next）命令逐行执行代码，使用`p`（print）命令查看变量的值，使用`c`（continue）命令继续执行代码直到下一个断点或程序结束

一行：

```python
import pdb; pdb.set_trace()
```

### IPython

```python
from IPython import embed
 
embed()

```

在程序运行到插入语句的地方时，会转到 IPython 环境下

两行代码放在同一行

```python
from IPython import embed; embed()

```

## 内存分析

安装模块：使用 pip 命令安装模块，命令如下：

```bash
pip3 install memory-profiler -i https://mirrors.aliyun.com/pypi/simple/
```

在需要测试的脚本顶部添加装饰器：使用@profile注解在需要测试的代码块顶部添加装饰器。例如：

```python
@profile
def run():
    # 需要测试的代码块
```

运行代码：使用命令行或终端运行代码，并在命令后添加-m memory_profiler选项，例如：

```bash
python3 -m memory_profiler your_script.py
```

