## xDS

Envoy 通过查询文件或管理服务器来动态发现资源，这些发现服务及其相应的 API 被统称为 `xDS`

Envoy 通过订阅（`subscription`）方式来获取资源，如监控指定路径下的文件、启动 gRPC 流（streaming）或轮询 REST-JSON URL。

后两种方式会发送 [DiscoveryRequest](https://www.envoyproxy.io/docs/envoy/latest/api-v2/api/v2/discovery.proto#discoveryrequest) 请求消息，发现的对应资源则包含在响应消息 [DiscoveryResponse](https://www.envoyproxy.io/docs/envoy/latest/api-v2/api/v2/discovery.proto#discoveryrequest) 中

### 文件订阅

### gRPC 流式订阅

### REST-JSON 轮询订阅