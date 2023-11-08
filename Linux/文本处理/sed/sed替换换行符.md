sed 使用中，执行命令：

```bash
sed "s/\n//g" file
```

没起到任何效果

sed 是按行处理文本数据的，每次处理一行数据后，都会在行尾自动添加 trailing newline，其实就是行的分隔符即换行符

如果非要使用 sed 命令，实现替换 file 文本内容的换行符为空的话，那么就要了解 sed 的分支条件命令，以及了解 sed 的 pattern space 模式空间和 hold space 保持空间。即，连续两行执行一次 sed 命令，这样就可以把前一行的 `\n` 替换完成

```bash
> cat a.txt
a11111
a22222
a33333

> sed "s/\n//g" a.txt
a11111
a22222
a33333

> sed ":a;N;s/\n//g;ta" a.txt
a11111a22222a33333

> sed ":a;N;s/\n//g;$!ba" a.txt
a11111a22222a33333

```

### 使用 test 跳转命令，实现替换换行符

```bash
sed ":a;N;s/\n//g;ta" a.txt
```

N 是把下一行加入到当前的 hold space 模式空间里，使之进行后续处理，最后 sed 会默认打印 hold space 模式空间里的内容。也就是说，sed 是可以处理多行数据的

`:a` 和 `ta` 是配套使用，实现跳转功能。t 是 test 测试的意思

另外，还有 `:a` 和 `ba` 的配套使用方式，也可以实现跳转功能。b 是 branch 分支的意思

branch 循环到文本结束。比如`sed ":a;N;s/\n//g;ba" a.txt`，转换成自然语言的描述，就是

```bash
while(1) {
 N;
 s/\n//g;
}
```

test 可以根据替换命令的完成是否成功，决定是否跳转。比如`sed ":a;N;s/\n//g;ta" a.txt`，转换成自然语言的描述，就是

```bash
while(state == 1) { # 默认 state 假设为 1
 N;
 s/\n//g; # 成功，返回 state 为 1；否则返回 state=0。此 state 用于跳转判断
}
else {
  last; # 即退出循环语句
}
```

### 使用 branch 跳转命令，实现替换换行符

增加`$!ba`语句，`$` 的意思是最后一行，不跳转到标记 `a` 处，即退出命令循环

```bash
sed ":a;$!N;s/\n//g;ba" a.txt
```

