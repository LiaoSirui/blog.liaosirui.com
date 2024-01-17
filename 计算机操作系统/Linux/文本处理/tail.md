
## 获取字符串最后几个字符

`tail` 加上参数 `-c` 就可以按照字符来获取最后的数据

```bash
> echo "hello" | tail -c 5

ello
```

注意：获取最后 4 个字符使用的是 `-c 5` 是因为 echo 指令显示的字符串组后有隐含换行 `\n`。如果要避免机上新行（newline character），则使用 `echo -n`。

另外，shell 支持切片方法：

```bash
> str="A random string*"; echo "$str"
A random string*

> echo "${str:$((${#str}-1)):1}"
*

> echo "${str:$((${#str}-2)):1}"
g
```

其实比较简明的是结合使用 `head -c` 和 `tail -c`，例如要截取 `hello` 的倒数第四个字符 `e`:

```bash
echo -n "hello" | tail -c 4 | head -c 1
```
