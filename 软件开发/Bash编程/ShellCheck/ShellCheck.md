官方：

- 文档：<https://www.shellcheck.net/>
- Wiki：<https://www.shellcheck.net/wiki/Home>
- <https://github.com/koalaman/shellcheck>

安装

```bash
dnf install -y ShellCheck
```

关闭 warning

```bash
# shellcheck source=/dev/null

# shellcheck source=../other.sh

# shellcheck disable=all
```

