## TOML 简介

TOML 是一种最小的配置文件格式，由于明显的语义而易于阅读

官方文档：<https://toml.io/en/>

## 格式

```toml
bool = true
date = 2006-05-27T07:32:00Z
string = "hello"
number = 42
float = 3.14
scientificNotation = 1e+12
```

### 基本类型

- 注释

```toml
# A single line comment example
# block level comment example
# 注释行 1
# 注释行 2
# 注释行 3
```

- 整数

```toml
int1 = +42
int2 = 0
int3 = -21
integerRange = 64
```

- 浮点数

```toml
float2 = 3.1415
float4 = 5e+22
float7 = 6.626e-34
```

- 布尔值

```toml
bool1 = true
bool2 = false
boolMustBeLowercase = true
```

- 时间日期

```toml
date1 = 1989-05-27T07:32:00Z
date2 = 1989-05-26T15:32:00-07:00
date3 = 1989-05-27T07:32:00
date4 = 1989-05-27
time1 = 07:32:00
time2 = 00:32:00.999999
```

### 字符串

- 文字字符串

```toml
str1 = "I'm a string."
str2 = "You can \"quote\" me."
str3 = "Name\tJos\u00E9\nLoc\tSF."
```

用单引号括起来，不允许转义

```toml
path = 'C:\Users\nodejs\templates'
path2 = '\\User\admin$\system32'
quoted = 'Tom "Dubs" Preston-Werner'
regex = '<\i\c*\s*>'
```

- 多行字符串

```toml
multiLineString = """
Multi-line basic strings are surrounded
by three quotation marks on each side
and allow newlines. 
"""
```

- 多行文字字符串

```toml
re = '''\d{2} apps is t[wo]o many'''
lines = '''
The first newline is
trimmed in raw strings.
All other whitespace
is preserved.
'''
```

### 数组

```toml
array1 = [1, 2, 3]
array2 = ["Commas", "are", "delimiter"]
array3 = [8001, 8001, 8002]
```

### 友好数组

```toml
array1 = [ "Don't mix", "different", "types" ]
array2 = [ [ 1.2, 2.4 ], ["all", 'strings', """are the same""", '''type'''] ]
array3 = [
  "Whitespace", "is", 
  "ignored"
]
```

### Tables

- 基本的 Table

`foo`  和  `bar`  是名为 `name`  的表中的键

```toml
[name]
foo = 1
bar = 2
```

- 点分隔

```toml
[dog."tater.man"]
type = "pug"
```

等效的 json 为

```json
{
    "dog": {
        "tater.man": {
            "type": "pug"
        }
    }
}

```

- Table 嵌套

```toml
[table1]
foo = "bar"
[table1.nested_table]
baz = "bat"
```

- 多嵌套

```toml
[foo.bar.baz]
bat = "hi"
```

等效的 json 为

```json
{
    "foo": {
        "bar": {
            "baz": {
                "bat": "hi"
            }
        }
    }
}
```

- 忽略空格

```toml
[a.b.c]          # this is best practice
[ d.e.f ]        # same as [d.e.f]
[ g .  h  .i ]   # same as [g.h.i]
[ j . "ʞ" .'l' ] # same as [j."ʞ".'l']
```

- 类数组

```toml
[[comments]]
author = "Nate"
text = "Great Article!"
[[comments]]
author = "Anonymous"
text = "Love it!"
```

等效的 json 为

```json
{
    "comments": [
        {
            "author": "Nate",
            "text": "Great Article!"
        },
        {
            "author": "Anonymous",
            "text": "Love It!"
        }
    ]
}
```

- 内联表

```toml
name = { first = "Tom", last = "Preston-Werner" }
point = { x = 1, y = 2 }
animal = { type.name = "pug" }
```
