## Git Config

Git Config 配置如下：

```ini
[merge]
	defaultToUpstream = true
[filter "lfs"]
	smudge = git-lfs smudge -- %f
	process = git-lfs filter-process
	required = true
	clean = git-lfs clean -- %f
[core]
	trustctime = false
	quotepath = false
	editor = vim
	longpaths = true
[init]
	defaultBranch = main
[alias]
	lg = log --color --graph --pretty=format:'%C(yellow)%h%Creset%C(cyan)%C(bold)%C(red)%d%Creset %s %C(green) [%cn] %Creset%C(cyan)[%cd]%Creset' --date=format-local:'%m-%d %H:%M'
	unstage = reset HEAD --
[user]
	name = LiaoSirui
	email = cyril@liaosirui.com
```

### git alias

```bash
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.ci commit
git config --global alias.br branch
```

设置撤销修改

```bash
git config --global alias.unstage 'reset HEAD --'
```

设置日志

```bash
git config --global alias.lg "log --color --graph --pretty=format:'%C(yellow)%h%Creset%C(cyan)%C(bold)%C(red)%d%Creset %s %C(green) [%cn] %Creset%C(cyan)[%cd]%Creset' --date=format-local:'%m-%d %H:%M'" \
```

此外，zsh 设置了大量关于 zsh 的命令别名

## gitignore

### 在线生成

仓库地址：<https://github.com/toptal/gitignore.io>

在线服务地址：<https://www.toptal.com/developers/gitignore>

### vscode 插件

插件地址：<https://marketplace.visualstudio.com/items?itemName=piotrpalarz.vscode-gitignore-generator>

插件名称：piotrpalarz.vscode-gitignore-generator

ctrl/command + shift + p 进入命令模式，选择

```bash
> generate .gitignore FIle
```

自定义部分放在最后，并且使用如下 title：

```bash
# Custom rules (everything added below won't be overriden by 'Generate .gitignore File' if you use 'Update' option)
/*.tgz

```

如果要取消前面模板生成的，不要直接删除而是使用 `!` 在自定义部分取消

