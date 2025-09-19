# pytest

pytest 是 python 的一种单元测试框架，与 python 自带的 unittest 测试框架类似，但是比 unittest 框架使用起来更简洁，效率更高。并且 pytest 兼容 unittest 的用例，支持的插件也更多

- <https://docs.pytest.org/en/stable/>

安装 pytest

```bash
uv add pytest --dev
```

- 测试文件应以 `test_*.py` 或 `*_test.py` 命名
- 测试函数应以 `test_` 开头，否则 `pytest` 不会自动发现

即 pytest 运行规则：查找当前目录及其子目录下以 `test_*.py`文件和 `*_test.py` 文件，找到文件后，在文件中找到以 test 开头函数并执行

运行用例

```bash
uv run pytest -v    # 显示详细信息
uv run pytest -q    # 仅显示成功/失败
```

## 简单使用

简单上手，创建个 `test_sample.py` 文件

```python
def func(x):
    return x + 1

def test_answer():
    assert func(3) == 5
```

运行测试，直接在当前文件夹运行 pytest

```
collected 1 item

test_sample.py F                                                     [100%]

================================= FAILURES =================================
_______________________________ test_answer ________________________________

    def test_answer():
>       assert func(3) == 5
E       assert 4 == 5
E        +  where 4 = func(3)

test_sample.py:6: AssertionError
============================ 1 failed in 0.12s =============================
```

以类来封装用例

```python
# content of test_class.py
class TestClass:
    def test_one(self):
        x = "this"
        assert "h" in x

    def test_two(self):
        x = "hello"
        assert hasattr(x, "check")
```

运行可以使用 `pytest [file_path]` 指定文件，`-q` 是静默模式，不会打印用例输出

```
$ pytest -q tests/test_class.py
.F                                                                   [100%]
================================= FAILURES =================================
____________________________ TestClass.test_two ____________________________

self = <test_class.TestClass object at 0xdeadbeef>

    def test_two(self):
        x = "hello"
>       assert hasattr(x, "check")
E       AssertionError: assert False
E        +  where False = hasattr('hello', 'check')

test_class.py:8: AssertionError
1 failed, 1 passed in 0.12s
```

用例设计原则

- 文件名以 `test_*.py`文件和 `*_test.py`
- 以 `test_` 开头的函数
- 以 `Test` 开头的类
- 以 `test_` 开头的方法
- 所有的包 pakege 必须要有 `__init__.py` 文件

## 执行用例

（1）执行某个目录下所有的用例

```
pytest 文件名/
```

（2）执行某一个 py 文件下用例

```bash
pytest 脚本名称.py
```

（3）`-k` 按关键字匹配

```bash
pytest -k "MyClass and not method"
```

这将运行包含与给定字符串表达式匹配的名称的测试，其中包括 Python 使用文件名，类名和函数名作为变量的运算符。 上面的例子将运行`TestMyClass.test_something` 但不运行 `TestMyClass.test_method_simple`

（4）按节点运行

每个收集的测试都分配了一个唯一的 nodeid，它由模块文件名和后跟说明符组成来自参数化的类名，函数名和参数，由 `:: characters` 分隔

运行 `.py` 模块里面的某个函数

```bash
pytest test_mod.py::test_func
```

运行 `.py` 模块里面，测试类里面的某个方法

```bash
pytest test_mod.py::TestClass::test_method
```

（5）标记表达式

```bash
pytest -m slow
```

运行用 `@pytest.mark.slow` 装饰器修饰的所有测试，slow 是自己命名的标记，可以自定义

```python
import pytest

@pytest.mark.finished
def test_send_http():
    pass  


def test_something_quick():
    pass
```

运行测试时使用 `-m` 选项可以加上逻辑

```bash
# 匹配 finished 和 commit 运行
pytest -m "finished and commit"

# finished 运行，merged 不运行
pytest -m "finished and not merged"
```

（6）从包里面运行

```bash
pytest --pyargs pkg.testing
```

这将导入 `pkg.testing` 并使用其文件系统位置来查找和运行测试

（7）在第一个（或N个）失败后停止

```bash
# stop after first failure
pytest -x

# stop after two failures
pytest --maxfail=2
```

（8）跳过测试

使用 `pytest.mark.skip` 标记需要跳过的用例

```python
@pytest.mark.skip(reason="not finished")
def test_send_http():
    pass 
```

也支持使用 pytest.mark.skipif 为测试函数指定被忽略的条件

```python
@pytest.mark.skipif(finishflag==Fasle,reason="not finished")
def test_send_http():
    pass 
```

（9）脚本调用执行

```python
# 直接使用
pytest.main()

# 像命令行一样传递参数
pytest.main(["-x", "mytestdir"])
```

## 用例编写

### 断言

pytest 直接使用 python assert 语法来写

```python
def f():
    return 3

def test_function():
    assert f() == 4
```

断言中添加消息

```python
assert a % 2 == 0, "value was odd, should be even"
```

### 预设与清理

与 unittest 中的 setup 和 teardown 类似，pytest 也有这样的环境清理方法，主要有

- 模块级（setup_module/teardown_module）开始于模块始末，全局的
- 函数级（setup_function/teardown_function）只对函数用例生效（不在类中）
- 类级（setup_class/teardown_class）只在类中前后运行一次(在类中)
- 方法级（setup_method/teardown_method）开始于方法始末（在类中）
- 类里面的（setup/teardown）运行在调用方法的前后

```python
import pytest


class TestClass:

    def setup_class(self):
        print("setup_class: 类中所有用例执行之前")

    def teardown_class(self):
        print("teardown_class: 类中所有用例执行之前")

    def setup_method(self):
        print("setup_method:  每个用例开始前执行")

    def teardown_method(self):
        print("teardown_method:  每个用例结束后执行")

    def setup(self):
        print("setup: 每个用例开始前执行")

    def teardown(self):
        print("teardown: 每个用例结束后执行")

    def test_one(self):
        print("执行第一个用例")

    def test_two(self):
        print("执行第二个用例")


def setup_module():
    print("setup_module: 整个.py模块只执行一次")


def teardown_module():
    print("teardown_module: 整个.py模块只执行一次")


def setup_function():
    print("setup_function: 每个方法用例开始前都会执行")


def teardown_function():
    print("teardown_function: 每个方法用例结束前都会执行")


def test_three():
    print("执行第三个用例")

```

使用 `pytest -s tests/test_sample.py` 运行，`-s` 参数是为了显示用例的打印信息，下面是输出，可以看出几个方法之间的优先级

```bash
tests/test_sample.py setup_module: 整个.py模块只执行一次
setup_class: 类中所有用例执行之前
setup_method:  每个用例开始前执行
执行第一个用例
.teardown_method:  每个用例结束后执行
setup_method:  每个用例开始前执行
执行第二个用例
.teardown_method:  每个用例结束后执行
teardown_class: 类中所有用例执行之前
setup_function: 每个方法用例开始前都会执行
执行第三个用例
.teardown_function: 每个方法用例结束前都会执行
teardown_module: 整个.py模块只执行一次
```

注意：setup_method 和 teardown_method 的功能和 setup/teardown 功能是一样的，一般二者用其中一个即可；函数里面用到的 setup_function/teardown_function 与类里面的 setup_class/teardown_class 互不干涉

### 参数化

使用 `pytest.mark.parametrize(argnames, argvalues)` 可以实现函数的参数化

```python
@pytest.mark.parametrize('text',['test1','test2','test3'])
def test_one(text):
    print(text)
```

`argnames` 就是形参名称，`argvalues` 就是待测的一组数据

## 固件 fixture

### 基本使用

固件 Fixture 是一些函数，pytest 会在执行测试函数之前（或之后）加载运行它们。主要是为一些单独测试用例需要预先设置与清理的情况下使用的。

不同于上面的 setup 和 teardown 的就是，可以自定义函数，可以指定用例运行，使用方法如下

```python
@pytest.fixture()
def text():
    print("开始执行")  # 使用pytest.fixture()装饰一个函数成为fixture


def test_one():
    print("执行第一个用例")


def test_two(text):  # 用例传入fixture函数名，以此来确认执行
    print("执行第二个用例")

```

使用 yield 可以实现固件的拆分运行，yield 前在用例前执行，yield 后再用例后执行

```python
@pytest.fixture()
def text():
    print("开始执行")
    yield  # yield 关键词将固件分为两部分，yield 之前的代码属于预处理，会在测试前执行；yield 之后的代码属于后处理，将在测试完成后执行
    print("执行完毕")


def test_one():
    print("执行第一个用例")


def test_two(text):
    print("执行第二个用例")

```

### 统一管理

固件可以直接定义在各测试脚本中，就像上面的例子。更多时候，我们希望一个固件可以在更大程度上复用，这就需要对固件进行集中管理。Pytest 使用文件 conftest.py 集中管理固件。

不用显式调用 conftest.py，pytest 会自动调用，可以把 conftest 当做插件来理解

```python
# ./conftest.py

@pytest.fixture()
def text():
    print("开始执行")
    yield
    print("执行完毕")

# ./test_sample.py

def test_one():
    print("执行第一个用例")

def test_two(text):
    print("执行第二个用例")

```

### 作用域

fixture可以通过 scope 参数声明作用域，比如

- function: 函数级，每个测试函数都会执行一次固件；
- class: 类级别，每个测试类执行一次，所有方法都可以使用；
- module: 模块级，每个模块执行一次，模块内函数和方法都可使用；
- session: 会话级，一次测试只执行一次，所有被找到的函数和方法都可用。

```python
# ./conftest.py

@pytest.fixture(scope="module")
def text():
    print("开始执行")
    yield
    print("执行完毕")

# ./test_sample.py

def test_one(text):
    print("执行第一个用例")

def test_two(text):
    print("执行第二个用例")
```

执行情况

```bash
test_sample.py 开始执行
执行第一个用例
.执行第二个用例
.执行完毕
```

如果对于类使用作用域，需要使用 `pytest.mark.usefixtures`（对函数和方法也适用）

```python
# ./conftest.py

@pytest.fixture(scope="class")
def text():
    print("开始执行")
    yield
    print("执行完毕")

# ./test_sample.py

@pytest.mark.usefixtures('text')
class TestClass:

    def test_one(self):
        print("执行第一个用例")

    def test_two(self):
        print("执行第二个用例")
```

### 自动运行

将 fixture 的 autouse 参数设置为 True 时，可以不用传入函数，自动运行

```python
# ./conftest.py

@pytest.fixture(scope="module", autouse=True)
def text():
    print("开始执行")
    yield
    print("执行完毕")

# ./test_sample.py

def test_one():
    print("执行第一个用例")

def test_two():
    print("执行第二个用例")
```

### 参数化

使用 fixture 的 params 参数可以实现参数化

```python
# ./conftest.py

@pytest.fixture(scope="module",params=['test1','test2'])
def text(request):
    print("开始执行")
    yield request.param
    print("执行完毕")

# ./test_sample.py

def test_one(text):
    print("执行第一个用例")
    print(text)

def test_two(text):
    print("执行第二个用例")
```

固件参数化需要使用 pytest 内置的固件 request，并通过 `request.param` 获取参数

```bash
test_sample.py 开始执行
执行第一个用例
test1
.执行第二个用例
.执行完毕
开始执行
执行第一个用例
test2
.执行第二个用例
.执行完毕
```

## 处理异常

`pytest.raises` 是 `pytest` 提供的一个上下文管理器，用于断言代码是否抛出指定异常

```python
import pytest

def divide(a, b):
    return a / b

def test_divide_by_zero():
    with pytest.raises(ZeroDivisionError):
        divide(1, 0)

```

## Mock 场景

```bash
uv add pytest-mock --dev
```

替换内置函数

```python
import time

def slow_function():
    time.sleep(5)  # 模拟耗时操作
    return "done"

def test_slow_function(mocker):
    mocker.patch("time.sleep", return_value=None)  # 替换 time.sleep，不让它真正执行
    assert slow_function() == "done"

```

替换类方法

```python
class DataFetcher:
    def get_data(self):
        return "Real Data"

def process():
    fetcher = DataFetcher()
    return fetcher.get_data()

def test_process(mocker):
    mocker.patch.object(DataFetcher, "get_data", return_value="Mocked Data")
    assert process() == "Mocked Data"

```

## 生成报告

### HTML 报告

安装 `pytest-html`

```bash
uv add pytest-html --dev
```

使用方法是，直接在命令行 pytest 命令后面加 `--html=<文件名字或者路径>.html` 参数即可

```bash
pytest --html=report.html
```

上面生成的报告包括 html 和一个 assets 文件（里面是报告 CSS 样式），如果要合成一个文件可以添加下面的参数

```bash
pytest --html=report.html --self-contained-html
```

### XML 报告

使用命令可以生成 XML 格式报告

```bash
pytest --junitxml=report.xml
```

### allure 报告

Allure Report 是一种灵活的多语言测试报告工具，可展示已测试内容的详细表示，并从日常测试执行中提取最大程度的信息

安装 allure，需要 JDK 环境

```bash
export INST_ALLURE_VERSION=v2.35.1
export INST_ALLURE_PATCH="-1"

dnf install -y https://github.com/allure-framework/allure2/releases/download/${INST_ALLURE_VERSION/v/}/allure_${INST_ALLURE_VERSION/v/}${INST_ALLURE_PATCH}.noarch.rpm
```

安装插件

```bash
uv add allure-pytest --dev
```

进入测试 py 文件目录，运行

```bash
pytest --alluredir ./report
```

使用 allure 查看报告，直接启动 `allure server` 后面加报告路径就行

```bash
allure serve report # (报告文件夹名)
```

生成 HTML 报告

```bash
allure generate --clean report
```
