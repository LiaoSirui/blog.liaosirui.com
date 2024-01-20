在 shell 脚本中，如果直接用自定义的 alias，会提示不是系统内部的命令，这是因为默认的脚本中 alias 模块并不生效，这时候需要手动打开 alias 模块：

`shopt -s expand_aliases` 就是开启 alias 的机制

```bash
#!/bin/bash

shopt -s expand_aliases
```

## 参考资料

<https://jskcw.com/post/how-to-create-bash-aliases/>
