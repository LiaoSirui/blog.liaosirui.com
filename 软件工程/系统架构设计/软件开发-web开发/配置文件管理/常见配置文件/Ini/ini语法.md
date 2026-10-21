

## 简介

INI 是一种固定标准格式的配置文件，INI配置方法来自 MS-DOS 操作系统

## 格式

Ini 格式文件的基本格式如下：

```ini
[section1]
key1 = value1
key2 = value2
# 注释
....
```

### 部分 (Sections)

每个部分都由一个 `[section]` 标题开头。

- 名称单独出现在一行中
- 名称在方括号 `[` 和 `]` 中
- 没有明确的 `section 结束` 分隔符
- 在下一个 `section` 声明处或文件末尾处结束
- 部分和属性名称不区分大小写（默认情况下，`[section]` 的名称是区分大小写的，而后面键是不区分大小写的。）

```ini
[section]
key1 = a
key2 = b
```

与下面 `JSON` 大致相同

```json
{
  "section": {
    "key1": "a",
    "key2": "b"
  }
}
```

### 条目

由特定的字符串 (`=` 或者 `:`, 默认是 `=`) 分割的键 / 值条目。前面和后面的空格，将会从键和值中删除。值也是可以跨多行的，只要值在换行时，缩进的深度比第一行的要深就行。

- 基本元素是键或属性
- 每个键由`名称`和`值`构成，等号 (=) 分隔
- `键名称`显示在等号的`左侧`
- `等号`和`分号`是`保留`字符

```ini
name = value
```

与下面JSON 大致相同

```js
{
  "name": "value"
}
```

### 嵌套(部分解析器支持)

```ini
[section]
domain = jaywcjlove.github.io

[section.subsection]
foo = bar
```

与下面 `JSON` 大致相同

```js
{
  "section": {
    "domain": "jaywcjlove.github.io"
    "subsection": {
      "foo": "bar"
    }
  }
}
```

嵌套到上一节 (简写)

```ini
[section]
domain = jaywcjlove.github.io
[.subsection]
foo = bar
```

### 转义字符

| 符号     | 含义                                     |
| -------- | ---------------------------------------- |
| `\\`     | \ (单个反斜杠，转义转义字符)             |
| `\'`     | 撇号                                     |
| `\"`     | 双引号                                   |
| `\0`     | 空字符                                   |
| `\a`     | 铃声/警报/声音                           |
| `\b`     | 退格键，某些应用程序的贝尔字符           |
| `\t`     | 制表符                                   |
| `\r`     | 回车                                     |
| `\n`     | 换行                                     |
| `\;`     | 分号                                     |
| `\#`     | 数字符号                                 |
| `\=`     | 等号                                     |
| `\:`     | 冒号                                     |
| `\x????` | 十六进制代码点的 Unicode 字符对应于 ???? |

### 数组

```ini
[section]
domain = jaywcjlove.github.io
array[]=first value
array[]=second value
```

与下面 `JSON` 大致相同

```js
{
  "section": {
    "domain": "jaywcjlove.github.io",
    "array": [
      "first value", "second value"
    ]
  }
}
```

### 注释

配置文件中也可能包含注释部分，由特定字符 (`#` 或者 `;`，默认是 `#`) 界定，值得注意的是，注释部分不可与键值处于同一行

注释 (`;`)

```ini
; 这里是注释文本，将被忽略
```

注释 (`#`)

```ini
# 这里是注释文本，⚠️ 部分编译器支持
```

一行之后的注释 (`;`,`#`) *(不标准)*

```ini
var = a       ; 这是一个内联注释
foo = bar     # 这是另一个内联注释
```

在某些情况下注释必须单独出现在行上

## 解释器

- [@go-ini/ini](https://github.com/go-ini/ini) *(golang)*
- [@npm/ini](https://www.npmjs.com/package/ini) *(nodejs)*
- [@zonyitoo/rust-ini](https://github.com/zonyitoo/rust-inii) *(rust)*
- [@rxi/ini](https://www.npmjs.com/package/ini) *(c)*
- [@pulzed/mINI](https://github.com/pulzed/mINI) *(c++)*
- [@rickyah/ini-parser](https://github.com/rickyah/ini-parser) *(c#)*
- [@Enichan/Ini](https://github.com/Enichan/Ini) *(c#)*

