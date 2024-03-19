## Prometheus 告警简介

告警能力在 Prometheus 的架构中被划分成两个独立的部分。如下所示，通过在 Prometheus 中定义 AlertRule（告警规则），Prometheus 会周期性的对告警规则进行计算，如果满足告警触发条件就会向 Alertmanager 发送告警信息

![image-20240318231109059](.assets/AlertManager简介/image-20240318231109059.png)

在 Prometheus 中一条告警规则主要由以下几部分组成：

- 告警名称：用户需要为告警规则命名，当然对于命名而言，需要能够直接表达出该告警的主要内容
- 告警规则：告警规则实际上主要由 PromQL 进行定义，其实际意义是当表达式（PromQL）查询结果持续多长时间（During）后出发告警

在 Prometheus 中，还可以通过 Group（告警组）对一组相关的告警进行统一定义；Alertmanager 作为一个独立的组件，负责接收并处理来自 Prometheus Server (也可以是其它的客户端程序) 的告警信息。

Alertmanager 可以对这些告警信息进行进一步的处理，比如当接收到大量重复告警时能够消除重复的告警信息，同时对告警信息进行分组并且路由到正确的通知方，Prometheus 内置了对邮件，Slack 等多种通知方式的支持，同时还支持与 Webhook 的集成，以支持更多定制化的场景。例如，用户完全可以通过 Webhook 与钉钉机器人进行集成，从而通过钉钉接收告警信息。同时 AlertManager 还提供了静默和告警抑制机制来对告警通知行为进行优化

## AlertManager 特性

AlertManager 主要用于接收 Prometheus 发送的告警信息

Alertmanager 除了提供基本的告警通知能力以外，还主要提供了如：分组、抑制以及静默等告警特性

![image-20240318231320537](.assets/AlertManager简介/image-20240318231320537.png)

- 分组

分组机制可以将详细的告警信息合并成一个通知。在某些情况下，比如由于系统宕机导致大量的告警被同时触发，在这种情况下分组机制可以将这些被触发的告警合并为一个告警通知，避免一次性接受大量的告警通知，而无法对问题进行快速定位。

例如，当集群中有数百个正在运行的服务实例，并且为每一个实例设置了告警规则。假如此时发生了网络故障，可能导致大量的服务实例无法连接到数据库，结果就会有数百个告警被发送到 Alertmanager

而作为用户，可能只希望能够在一个通知中中就能查看哪些服务实例收到影响。这时可以按照服务所在集群或者告警名称对告警进行分组，而将这些告警内聚在一起成为一个通知

告警分组，告警时间，以及告警的接受方式可以通过 Alertmanager 的配置文件进行配置

- 抑制

抑制是指当某一告警发出后，可以停止重复发送由此告警引发的其它告警的机制

例如，当集群不可访问时触发了一次告警，通过配置 Alertmanager 可以忽略与该集群有关的其它所有告警。这样可以避免接收到大量与实际问题无关的告警通知

抑制机制同样通过 Alertmanager 的配置文件进行设置

- 静默

静默提供了一个简单的机制可以快速根据标签对告警进行静默处理。如果接收到的告警符合静默的配置，Alertmanager 则不会发送告警通知

静默设置需要在 Alertmanager 的 Web 页面上进行设置

## 告警处理流程

- <https://github.com/prometheus/alertmanager/blob/main/dispatch/dispatch.go>

## 参考资料

- <https://www.cnblogs.com/hmtk123/p/14991088.html>
- <https://help.aliyun.com/document_detail/176180.html>
- <https://flashcat.cloud/docs/content/flashcat-monitor/prometheus/alert/manager-inhibit/>

- <https://pshizhsysu.gitbook.io/prometheus/ff08-san-ff09-prometheus-gao-jing-chu-li/gao-jing-de-lu-you-yu-fen-zu>

- <https://www.kancloud.cn/jiaxzeng/kubernetes/3125901#Alertmanager_6>

- <https://blog.csdn.net/agonie201218/article/details/126243110>

- <https://blog.csdn.net/sinat_32582203/article/details/122617740>
