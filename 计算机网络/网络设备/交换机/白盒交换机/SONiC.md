## SONiC

微软在 2016 年开源了 SONiC，希望能够通过开源的方式，让 SONiC 能够成为一个通用的网络操作系统，从而解决上面的问题。而且，由于 Azure 的背书，也能保证 SONiC 确实能够承受大规模的生产环境的考验，这也是 SONiC 的一个优势

SONiC 是微软开发的基于 debian 的开源的网络操作系统，它的设计核心思想有三个：

1. 硬件和软件解耦：通过 SAI（Switch Abstraction Interface）将硬件的操作抽象出来，从而使得 SONiC 能够支持多种硬件平台。这一层抽象层由 SONiC 定义，由各个厂商来实现。
2. 使用 docker 容器将软件微服务化：SONiC 上的主要功能都被拆分成了一个个的 docker 容器，和传统的网络操作系统不同，升级系统可以只对其中的某个容器进行升级，而不需要整体升级和重启，这样就可以很方便的进行升级和维护，支持快速的开发和迭代。
3. 使用 redis 作为中心数据库对服务进行解耦：绝大部分服务的配置和状态最后都被存储到中心的 redis 数据库中，这样不仅使得所有的服务可以很轻松的进行协作（数据存储和 pubsub），也可以让我们很方便的在上面开发工具，使用统一的方法对各个服务进行操作和查询，而不用担心状态丢失和协议兼容问题，最后还可以很方便的进行状态的备份和恢复。

这让 SONiC 拥有了非常开放的生态（Community，Devices，Workgroups）

支持的型号查询：<https://sonic-net.github.io/SONiC/Supported-Devices-and-Platforms.html>

## 参考资料

- <https://r12f.com/posts/sonic-1-intro/>
- <https://www.cnblogs.com/lionelgeng/p/16330586.html>
