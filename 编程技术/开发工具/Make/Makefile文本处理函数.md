GNU make 提供了一系列文本处理函数：

- `subst`
- `patsubst`
- `strip`
- `findstring`
- `filter`
- `filer-out`
- `sort`
- `word`
- `wordlist`
- `words`
- `fistword`

## word 函数：取单词

word 函数的作用是从一个字符串 TEXT 中，按照指定的数目 N 取单词：

```bash
$(word N,TEXT)
```

函数的返回值是字符串 TEXT 中的第 N 个单词。如果 N 的值大于字符串中单词的个数，返回空；如果 N 为 0，则出错

```makefile
.PHONY: all
LIST = banana pear apple peach orange 
word1 = $(word 1, $(LIST))
word2 = $(word 2, $(LIST))
word3 = $(word 3, $(LIST))
word4 = $(word 4, $(LIST))
word5 = $(word 5, $(LIST))
word6 = $(word 6, $(LIST))
all:
    @echo "word1 = $(word1)"
    @echo "word2 = $(word2)"
    @echo "word3 = $(word3)"
    @echo "word4 = $(word4)"
    @echo "word5 = $(word5)"
    @echo "word6 = $(word6)"
```

执行 make，运行结果为：

```bash
# make
word1 = banana
word2 = pear
word3 = apple
word4 = peach
word5 = orange
word6 =
```

如果 N 的值为 0，Makefile 含有下面的语句：

```makefile
word0 = $(word 0, $(LIST))
```

则会报错：`makefile:9: *** first argument to 'word' function must be greater than 0.  Stop.`

## wordlist 函数：取字串

wordlist 函数用来从一个字符串 TEXT 中取出从 N 到 M 之间的一个单词串：

```makefile
$(wordlist N, M, TEXT)
```

N 和 M 都是从 1 开始的一个数字，函数的返回值是字符串 TEXT 中从 N 到 M 的一个单词串。当 N 比字符串 TEXT 中的单词个数大时，函数返回空

```makefile
.PHONY: all
LIST = banana pear apple peach orange 
sub_list = $(wordlist 1, 3, $(LIST))
all:
    @echo "LIST = $(LIST)"
    @echo "sub_list = $(sub_list)"
```

执行 make 时，wordlist 函数会将字符串 LIST 中的前三个单词赋值给 sub_list：

```bash
# make
LIST = banana pear apple peach orange 
sub_list = banana pear apple
```

## firstword 函数：取首个单词

firstword 函数用来取一个字符串中的首个单词