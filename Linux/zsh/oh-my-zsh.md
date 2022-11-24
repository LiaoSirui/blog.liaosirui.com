
## 简介

oh-my-zsh（omz）是 zsh 上常用的美化终端的工具。

omz 在 GitHub 上面的仓库访问起来往往比较慢，而 gitee 上有 omz 的镜像（Gitee 极速下载/oh-my-zsh）。

通过简单地修改 omz 的安装脚本，可以通过 gitee 的镜像下载 omz 并在之后用 gitee 进行更新。

## 修改之处

<https://gitee.com/mirrors/oh-my-zsh/blob/master/tools/install.sh>

在该脚本中有这样一段代码，指定了上游的仓库

```bash
ZSH=${ZSH:-~/.oh-my-zsh}
REPO=${REPO:-ohmyzsh/ohmyzsh}
REMOTE=${REMOTE:-https://github.com/${REPO}.git}
BRANCH=${BRANCH:-master}
```

由于我们想要用 gitee 加速，所以应该将该代码改为

```bash
ZSH=${ZSH:-~/.oh-my-zsh}
REPO=${REPO:-mirrors/oh-my-zsh}
REMOTE=${REMOTE:-https://gitee.com/${REPO}.git}
BRANCH=${BRANCH:-master}
```

修改完成之后，在 install.sh 的文件夹下执行 sh install.sh 命令
