## Python 源码编译过程

Python 源码到机器码的过程，以 CPython 为例，编译过程如下：

- 将源代码解析为解析树（Parser Tree）
- 将解析树转换为抽象语法树（Abstract Syntax Tree）
- 将抽象语法树转换到控制流图（Control Flow Graph）
- 根据流图将字节码（bytecode）发送给虚拟机（ceval）

可以使用以下模块进行操作：

- ast 模块可以控制抽象语法树的生成和编译
- py-compile 模块能够将源码换成字节码（编译），保存在 `__pycache__` 文件夹，以 `.pyc` 结尾（不可读）
- dis 模块通过反汇编支持对字节码的分析（可读）

## ast 模块使用

ast 模块可以用于生成和编译 Python 代码的抽象语法树，许多静态分析工具都使用该模块生成抽象语法树。

`ast.parse()` 函数可以用来生成抽象语法树，`ast.compile()` 可以将抽象语法树编译为代码。

用下列代码作为测试样例：

```python
def nums():
    for i in range(2):
        if i % 2 == 0:
            print("even: ", i)
        else:
            print(" odd: ", i)

nums()
```

### 编译执行

代码对象是 CPython 实现的低级细节，涉及 code 模块，该模块是解释器基类，可用于自定义 Python 解释器。

```python
# 读取源文件
with open("demo.py") as f:
    data = f.read()

# 生成可以被 exec() 或 eval() 执行的代码对象
cm = compile(data, '<string>', 'exec')
exec(cm)
```



## 参考资料

<https://jckling.github.io/2021/07/14/Other/Python%20ast%20%E6%A8%A1%E5%9D%97%E4%BD%BF%E7%94%A8/index.html>