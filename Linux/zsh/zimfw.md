
## zimfw

先安装 zimfw

<https://github.com/zimfw/zimfw>

安装命令：

With curl:

```bash
curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh
```

With wget:

```bash
wget -nv -O - https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh
```

添加如下内容到 `~/.zimrc`：

```bash
zmodule ohmyzsh/ohmyzsh -f 'plugins/git' -s 'plugins/git/git.plugin.zsh' -f 'plugins/wd' -s 'plugins/wd/wd.plugin.zsh' -f 'plugins/pip' -s 'plugins/pip/pip.plugin.zsh' -f 'plugins/command-not-found' -s 'plugins/command-not-found/command-not-found.plugin.zsh' -f 'plugins/git-lfs' -s 'plugins/git-lfs/git-lfs.plugin.zsh' -f 'plugins/common-aliases' -s 'plugins/common-aliases/common-aliases.plugin.zsh' -f 'plugins/z' -s 'plugins/z/z.plugin.zsh'
zmodule romkatv/powerlevel10k
```

运行 `zimfw install` 安装插件。

运行 `zimfw update` 更新所有插件。

处理报错：

```text
x completion: Error during git merge
  fatal: 未指定提交并且 merge.defaultToUpstream 未设置。
x utility: Error during git merge
  fatal: 未指定提交并且 merge.defaultToUpstream 未设置。
x git-info: Error during git merge
  fatal: 未指定提交并且 merge.defaultToUpstream 未设置。
x zsh-syntax-highlighting: Error during git merge
  fatal: 未指定提交并且 merge.defaultToUpstream 未设置。
x asciiship: Error during git merge
  fatal: 未指定提交并且 merge.defaultToUpstream 未设置。
x input: Error during git merge
  fatal: 未指定提交并且 merge.defaultToUpstream 未设置。
x termtitle: Error during git merge
  fatal: 未指定提交并且 merge.defaultToUpstream 未设置。
x zsh-completions: Error during git merge
  fatal: 未指定提交并且 merge.defaultToUpstream 未设置。
x zsh-autosuggestions: Error during git merge
  fatal: 未指定提交并且 merge.defaultToUpstream 未设置。
```

需要配置一下 git:

```bash
git config --global merge.defaultToUpstream true
```
