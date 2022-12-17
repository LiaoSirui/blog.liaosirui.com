
## 在线生成

仓库地址：<https://github.com/toptal/gitignore.io>

在线服务地址：<https://www.toptal.com/developers/gitignore>

## vscode 插件

### 安装

插件地址：<https://marketplace.visualstudio.com/items?itemName=piotrpalarz.vscode-gitignore-generator>

插件名称：piotrpalarz.vscode-gitignore-generator

### 使用

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
