## vscode 插件

官方地址：<https://marketplace.visualstudio.com/items?itemName=ms-python.isort>

直接配置

```json
{
      "[python]": {
    "editor.defaultFormatter": "ms-python.black-formatter",
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
        "source.organizeImports": true
    },
  },
  "isort.args":["--profile", "black"],
}
```

## 参考链接

- <https://cloud.tencent.com/developer/article/1925643>
- <https://marketplace.visualstudio.com/items?itemName=ms-python.isort>

- <https://muzing.top/posts/38b1b99e/>
- Black <https://muzing.top/posts/a29e4743/>