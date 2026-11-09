切换第三方 Provider 的插件：`johnny-zhao.oai-compatible-copilot`

配置模型示例

```json
{
    "oaicopilot.baseUrl": "https://api-inference.modelscope.cn/v1",
    "oaicopilot.models": [
        {
            "id": "claude-opus-4-6-ssvip",
            "owned_by": "claude",
            "context_length": 256000,
            "max_tokens": 8192,
            "temperature": 0,
            "top_p": 1
        }
    ]
}
```

VSCode 设置：`editor.inlineSuggest.enabled` - 启用或禁用内联补全。