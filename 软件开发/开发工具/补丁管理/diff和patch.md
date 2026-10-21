## diff

```
diff [option] file1 file2
```

按“行”比较两个文件的差异。可以比较文件或目录。

option:

- `-c`: 完整的显示两个文件不同行的上下文
- `-c -C num`: 显示上下文的行数，默认为 3
- `-u`: 以 unified 格式显示不同
- `-u -U num`:  显示上下文的行数，默认为 3
- `-p`: 如果不同在函数中，则提示所在函数名
- `-r`: 递归的比较所有子目录
- `-N`: 视不存在的文件为空文件来比较
- `-x PATTERN`: 忽略 PATTERN 匹配的文件

例如，比较 compdir01 和 compdir03 两个文件夹，忽略其中的 `.patch` 文件：

```bash
diff -u compdir01 compdir03 -x *.patch
```

`-X patternfiles`: 忽略 patternfiles 文件中指定的所有 PATTERN

```bash
diff -u compdir01 compdir03 -X patternfiles
```

生成一个 patch：

```bash
diff -u compdir01 compdir03 > compdir.patch
```

## patch

打 patch：

```bash
patch -pN < compdir.patch
```

其中 N 为需要剥掉的文件名中的目录级数

例如，`compdir.patch` 文件中指明的文件名为：

```plain
/home/myname/personale/compdir01/backtrace.c
```

而 `backtrace.c` 文件在 `/home/yourname/compdir01/` 目录下

那需要将 patch 拷贝到 `/home/yourname/` 目录下，然后执行

```bash
patch -p3 < compdir.patch
```

即剥掉 patch 文件中的 `/home/myname/personale/`前缀。

或者将 patch 拷贝到 `/home/yourname/compdir01/` 目录下，然后执行

```bash
patch -p4 < compdir.patch
```

即剥掉 patch 文件中的 `/home/myname/personale/compdir01/` 前缀。

记住，打 patch 的时候不要过分依赖 patc h命令，打完之后一定要检查代码。另外，尽量在原始项目中打 patch，避免冲突。
