## Langfuse

Langfuse 是一个开源的 LLM（大型语言模型）工程平台，由 Langfuse 公司开发。它旨在帮助用户更好地管理、调试和优化他们的 LLM 应用程序。Langfuse 的核心产品包括追踪、可观察性、评估、提示管理和 API/SDK 等。作为一款开源项目，Langfuse 能够解决数据安全和隐私问题，用户可以选择自行托管。它适用于希望对 LLM 应用程序进行迭代和改进的企业和个人开发者。

Langfuse 的核心功能包括：

- 追踪（Tracing）：捕获 LLM 应用程序的完整上下文。
- 可观察性（Observability）：通过客户端 SDKs 和集成，模型和框架无关，能够捕获执行的全貌。
- 评估（Evals）：帮助用户构建丰富的应用性能数据集，用于后续的微调、调试等。
- 提示管理（Prompt Management）：管理 LLM 应用程序中的提示。
- API/SDK：提供 Python、JS/TS 等语言的 SDK，以及手动 instrumentation。

## 测试

获取最新 Langfuse 存储库的副本

```bash
git clone https://github.com/langfuse/langfuse.git
cd langfuse
```

运行 langfuse docker compose

```bash
docker compose up
```

运行完成后，访问 3000 端口

Langfuse 没有预设的默认用户密码，需要新注册一个用户，这个用户，就是管理员。

依次进行：

- 新建组织
- 新建项目
- 创建 API Key

##  调用跟踪

大语言模型（LLM）应用程序使用越来越复杂的抽象概念，例如链、配备工具的智能体以及高级提示。嵌套跟踪在 Langfuse 中有助于理解正在发生的事情并确定问题的根本原因。

Trace 跟踪功能可让你追踪应用程序中的每一次大语言模型调用以及其他相关逻辑

