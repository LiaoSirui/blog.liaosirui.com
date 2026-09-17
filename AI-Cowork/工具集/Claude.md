## VSCode 插件

`Anthropic.claude-code`

安装 ccr

```bash
npm install -g @musistudio/claude-code-router
```

首先，在终端运行 `ccr start` 来自动生成默认配置文件

vscode 设置

```json
{
    "claudeCode.disableLoginPrompt": true
}
```

## 终端工具

Claude Code 终端/命令行工具（自带终端用户界面交互功能）

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

## 配置

Claude Code 启动时会读取 `~/.claude/settings.json` 中的 `env` 字段，将其作为环境变量注入运行时。只需修改 `ANTHROPIC_BASE_URL` 和 `ANTHROPIC_AUTH_TOKEN`，就能把请求指向第三方 API。

| 变量                                       | 说明                                    |
| ------------------------------------------ | --------------------------------------- |
| `ANTHROPIC_BASE_URL`                       | API 端点地址，改为第三方服务地址        |
| `ANTHROPIC_AUTH_TOKEN`                     | API Key / Token                         |
| `ANTHROPIC_MODEL`                          | 默认使用的模型名称                      |
| `ANTHROPIC_DEFAULT_OPUS_MODEL`             | Opus 级别模型                           |
| `ANTHROPIC_DEFAULT_SONNET_MODEL`           | Sonnet 级别模型                         |
| `ANTHROPIC_DEFAULT_HAIKU_MODEL`            | Haiku 级别模型                          |
| `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` | 设为 `1` 禁用非必要网络请求（建议开启） |

Claude Code 区分三个模型级别（Opus > Sonnet > Haiku），Fast/Think 模式走 Opus，普通模式走 Sonnet，轻量任务走 Haiku。如果第三方只提供一个模型，把三个值设成同一个即可。

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://...",
    "ANTHROPIC_AUTH_TOKEN": "sk-...",
    "ANTHROPIC_MODEL": "gpt-6-astra",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "claude-opus-5",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "claude-sonnet-5",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "claude-haiku-4-5",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1",
    "CLAUDE_CODE_MAX_CONTEXT_TOKENS": "1024000",
    "DISABLE_COMPACT": "1"
  }
}
```

