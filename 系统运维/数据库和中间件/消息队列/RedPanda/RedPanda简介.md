## Redpanda

Redpanda 使用 C++ 编写，是一个与 Kafka兼容的流数据平台，事实证明它的速度提高了10 倍。它还不含 JVM、不含 ZooKeeper、经过 Jepsen 测试且源代码可用

因为是 C++ 编写，所以无需使用 JVM，分布式协调使用 raft 协议，所以也无需使用 zookeeper。只有一个可执行二进制文件，部署非常方便

![img](.assets/RedPanda简介/fc60babcd8cd1796c7ef6b3f79a8f885.png)

Redpanda Console 是一个 可视化 Kafka/Redpanda 集群管理工具，它被用于 消息队列 等场景。Redpanda Console（以前称为Kowl）是一个Web应用程序，可帮助您轻松管理和调试Kafka / Redpanda工作负载