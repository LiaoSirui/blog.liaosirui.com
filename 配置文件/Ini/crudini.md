## crudini 简介

`crudini` 实现的是对自定义的 ini 格式的配置文件进行解析

官方：

- GitHub 地址：<https://github.com/pixelb/crudini>

安装

```bash
dnf install -y crudini

# 或者
pip3 install crudini
```

## 说明

```bash
man crudini
```

显示使用内容如下：

```bash
NAME
       crudini - manipulate ini files

SYNOPSIS
       crudini --set [OPTION]...   config_file section   [param] [value]
       crudini --get [OPTION]...   config_file [section] [param]
       crudini --del [OPTION]...   config_file section   [param] [list value]
       crudini --merge [OPTION]... config_file [section]

EXAMPLES
       # Add/Update a var
              crudini --set config_file section parameter value

       # Add/Update a var in the root or global area.  # I.e. that's not under a [section].
              crudini --set config_file "" parameter value

       # Update an existing var
              crudini --set --existing config_file section parameter value

       # Add/Append a value to a comma separated list # Note any whitespace around commas is ignored
              crudini --set --list config_file section parameter a_value

       # Add/Append a value to a whitespace separated list # Note multiline lists are supported (as newline is whitespace)
              crudini --set --list --list-sep= config_file section parameter a_value

       # Delete a var
              crudini --del config_file section parameter

       # Delete a section
              crudini --del config_file section

       # output a value
              crudini --get config_file section parameter

       # output a global value not in a section
              crudini --get config_file "" parameter

       # output a section
              crudini --get config_file section

       # output a section, parseable by shell
              eval "$(crudini --get --format=sh config_file section)"

       # update an ini file from shell variable(s)
              echo name="$name" | crudini --merge config_file section

       # merge an ini file from another ini
              crudini --merge config_file < another.ini

       # compare two ini files using standard UNIX text processing
              diff <(crudini --get --format=lines file1.ini|sort) \
              <(crudini --get --format=lines file2.ini|sort)

       # Rewrite ini file to use name=value format rather than name = value
              crudini --ini-options=nospace --set config_file ""

       # Add/Update a var, ensuring complete file in name=value format
              crudini --ini-options=nospace --set config_file section parameter value
```

## 使用

用法概述

```bash
crudini --set [--existing] config_file section [param] [value]
crudini --get [--format=sh|ini] config_file [section] [param]
crudini --del [--existing] config_file section [param]
crudini --merge [--existing] config_file [section]
```

`crudini` 用于操作ini文件，可以设置、获取、删除、合并其中的变量

其中：`config_file` 代表要操作的文件名，`section` 表示变量所在的部分，如以下配置文件：

配置文件的格式如下

```ini
global_value="xxx"

[DEFAULT]
user = admin
passwd = admin
port = 8088

[URL]
client = 127.0.0.1:8088
admin = 127.0.0.1:8080
```

> `section` 则表示了以上配置文件中的`DEFAULT` 和 `URL`
>
> 如果该标量不在某一个 section 里面，则 section 用一个空字符表示，即 `''`

配置添加

```bash
crudini --set ${config_file} ${section} parameter value
```

配置更新

```bash
crudini --set [--existing] ${config_file} ${section} parameter value
```

删除变量

```bash
crudini --del ${config_file} ${section} parameter
```

删除 section

```bash
crudini --del ${config_file} ${section}
```

获取

```bash
crudini --get ${config_file} ${section} parameter
```

合并

```bash
# 将 another.ini 配置文件合并到 config_file 中
crudini --merge ${config_file} < another.ini
```

