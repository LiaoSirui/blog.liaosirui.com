## protocol buffers

使用 protocol buffers 可以让你使用更优雅并且自定义样式的方式定义 API。如果使用 Json，则你需要在文档中记录包含的字段及其类型。与任何文档一样，你可能面临不准确，或者文档未及时更新的风险。

当你使用 protocol buffers 进行 API 定义时，从中生成 Python 代码。你的代码永远不会和文档不一致，文档是好的，但是代码中的自我文档是更好的方式。

protocol buffers 是将数据通过序列化方式在两个微服务之间传输。所以，protocol buffers 和 JSON 或 XML 都是相似的方式组织数据。不同的是，protocol buffers 拥有更严格的格式和更压缩的方式在网络上通讯。

另外一方面，RPC 架构应该被称为 gRPC 或者 Google RPC。这很像 HTTP。但正如上述所言，gRPC 实际上是基于 HTTP/2 构建的。

## 性能

gRPC 框架是比传统 HTTP 请求效率更高。gRPC 是在 HTTP/2 基础上构建的，能够在一个长连接上使用现成安全的方式进行多次并发请求。连接创建相对较慢，所以在多次请求时，一次连接并共享连接以节省时间。gRPC 信息是二进制的，并且小于 JSON。未来，HTTP/2 会提供内置的头部压缩。

gRPC 内置了对流式请求和返回的支持。比基础 HTTP 连接更好的管理网络问题，即使是在长时间断线后，也会自动重连。