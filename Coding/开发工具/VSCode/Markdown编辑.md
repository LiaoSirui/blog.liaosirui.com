## Markdown 相关插件

- `DavidAnson.vscode-markdownlint`

## Markdown 相关配置

自动拷贝图片

```json
{
    "markdown.copyFiles.destination": {
        "**/*.md": ".assets/${documentBaseName}/${unixTime}-${fileName}"
    }
}
```

忽略部分规则

```json
{
    "markdownlint.config": {
        "MD025": false,
        "MD033": false,
        "MD039": false,
        "MD041": false,
        "default": true
    },
}
```

缩进

```json
{
    "[markdown]": {
        "editor.tabSize": 2,
    },
}
```
