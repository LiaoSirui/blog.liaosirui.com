## 基础语法

Jsonnet 语法比 JSON 更宽松

字段可以不加引号; 支持注释; 字典或列表的最后一项可以带逗号

```jsonnet
/* 多行
注释 */
{key: 1+2, 'key with space': 'key with special char should be quoted'}
// 单行注释
```

得到输出

```json
{
   "key": 3,
   "key with space": "key with special char should be quoted"
}
```

类比: Jsonnet 支持与主流语言类似的四则运算, 条件语句, 字符串拼接, 字符串格式化, 数组拼接, 数组切片以及 python 风格的列表生成式

```jsonnet
{
    array: [1, 2] + [3],
    math: (4 + 5) / 3 * 2,
    format: 'Hello, I am %s' % 'Cyril',
    concat: 'Hello, ' + 'I am Cyril',
    slice: [1,2,3,4][1:3],
    'list comprehension': [x * x for x in [1,2,3,4]],
    condition:
        if 2 > 1 then 
        'true'
        else 
        'false',
}

```

得到输出

```json
{
   "array": [
      1,
      2,
      3
   ],
   "concat": "Hello, I am Cyril",
   "condition": "true",
   "format": "Hello, I am Cyril",
   "list comprehension": [
      1,
      4,
      9,
      16
   ],
   "math": 6,
   "slice": [
      2,
      3
   ]
}
```

## Variables

使用变量:

- 使用 `::` 定义的字段是隐藏的(不会被输出到最后的 JSON 结果中), 这些字段可以作为内部变量使用(非常常用)

- 使用 local 关键字也可以定义变量

JSON 的值中可以引用字段或变量, 引用方式:

- 变量名

- self 关键字: 指向当前对象

- `$` 关键字: 指向根对象

示例

```jsonnet
{
    local name = 'aylei',
    language:: 'jsonnet',
    message: {
        target: $.language,
        author: name,
        by: self.author,
    }
}
```

得到输出

```json
{
   "message": {
      "author": "aylei",
      "by": "aylei",
      "target": "jsonnet"
   }
}
```

## Functions

函数(或者说方法)在 Jsonnet 中是一等公民, 定义与引用方式与变量相同, 函数语法类似 python

```jsonnet
{
    local hello(name) = 'hello %s' % name,
    sum(x, y):: x + y,
    newObj(name='Cyril', age=23, gender='male'):: {
        name: name,
        age: age,
        gender: gender,
    },
    call_sum: $.sum(1, 2),
    call_hello: hello('world'),
    me: $.newObj(age=24),
}
```

## Patches

Jsonnet 使用组合来实现面向对象的特性(类似 Go)

- Json Object 就是 Jsonnet 中的对象

- 使用 `+` 运算符来组合两个对象, 假如有字段冲突, 使用右侧对象(子对象)中的字段

- 子对象中使用 super 关键字可以引用父对象, 用这个办法可以访问父对象中被覆盖掉的字段

```jsonnet
local base = {
    f: 2,
    g: self.f + 100,
};
base + {
    f: 5,
    old_f: super.f,
    old_g: super.g,
}

```

得到输出

```json
{
   "f": 5,
   "g": 105,
   "old_f": 2,
   "old_g": 105
}
```

有时候希望一个对象中的字段在进行组合时不要覆盖父对象中的字段, 而是与相同的字段继续进行组合

这时可以用 `+:` 来声明这个字段 (`+::` 与 `+:` 的含义相同, 但与 `::` 一样的道理, `+::` 定义的字段是隐藏的)

对于 JSON Object, 更希望进行组合而非覆盖, 因此在定义 Object 字段时, 很多库都会选择使用 `+:` 和 `+::`, 但也要注意不能滥用

```jsonnet
local child = {
    override: {
        x: 1,
    },
    composite+: {
        x: 1,
    },
};
{
    override: { y: 5, z: 10 },
    composite: { y: 5, z: 10 },
} + child
```

得到输出

```json
{
   "composite": {
      "x": 1,
      "y": 5,
      "z": 10
   },
   "override": {
      "x": 1
   }
}
```

## Imports

库与 import:

- jsonnet 共享库复用方式其实就是将库里的代码整合到当前文件中来,

- 引用方式也很暴力, 使用 -J 参数指定 lib 文件夹, 再在代码里 import 即可

jsonnet 约定库文件的后缀名为 `.libsonnet`

```jsonnet
{
    newVPS(
        ip, 
        region='cn-hangzhou', 
        distribution='CentOS 7', 
        cpu=4, 
        memory='16GB'
    ):: {
        ip: ip,
        distribution: distribution,
        cpu: cpu,
        memory: memory,
        vendor: 'Cyril',
        os: 'linux',
        packages: [],
        install(package):: self + {
            packages+: [package],
        },
    }
}
```

调用

```jsonnet
local vpsTemplate = import 'some-path/mylib.libsonnet';
vpsTemplate
  .newVPS(ip='10.10.44.144', cpu=8, memory='32GB')
  .install('docker')
  .install('jsonnet')
```

上面这种 Builder 模式在 jsonnet 中非常常见, 也就是先定义一个构造器, 构造出基础对象然后用各种方法进行修改

当对象非常复杂时, 这种模式比直接覆盖父对象字段更易维护