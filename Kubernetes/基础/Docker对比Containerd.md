Containerd 跟 Docker 的区别说明

Docker 对容器的管理和操作基本都是通过 containerd 完成的，只是相当对于对其进行了封装，提供一些非常简单的命令进行管理容器生命周期。

Containerd 是一个工业级标准的容器运行时，它强调简单性、健壮性和可移植性，主要在宿主机中管理完整的容器生命周期：容器镜像的传输和存储、容器的执行和管理、存储和网络等。

Kubernetes 调用链对比

在Kubenetes 1.19.x 与 Kubernetes 1.20.x 版本针对runtime分别使用docker、Container的调用链关系。

- Runtime = docker 时的调用链

Kubelet -> Dockerd -> Containerd

- Runtime = containerd 时的调用链

Kubelet -> Containerd

命令对比：containerd不支持docker API和docker CLI， 但是可以通过cri-tool实现类似的功能。

<img src="https://i0.hdslb.com/bfs/article/8ff90cc2e33ba859ea8b804e36f49c4273df63dd.png" title="" alt="" data-align="center">

<img src="https://i0.hdslb.com/bfs/article/8d11eae9273ac136d38004a34ca5037be16ed7be.png" title="" alt="" data-align="center">

<img src="https://i0.hdslb.com/bfs/article/1540a7c3ad05b7f87a3d000a6bf5bf770643a69c.png" title="" alt="" data-align="center">

配置参数对比:

日志配置参数区别

![](https://i0.hdslb.com/bfs/article/d5610a98b9b84cab61ff1ce47421ae853518abc1.png)

stream server 区别: 执行 kubectl exec/logs 等命令需要在apiserver跟容器运行时之间建立流转发通道。 Docker API本身提供stream服务，kubelet 内部的 docker-shim 会通过 docker API做流转发, containerd 的stream服务需要单独配置。

[plugins.cri] stream_server_address = "127.0.0.1" stream_server_port = "0" enable_tls_streaming = false

Tips: 从k8s1.11引入了 kubelet stream proxy (https://github.com/kubernetes/kubernetes/pull/64006), 从而使得containerd stream server只需要监听本地地址即可。

CNI 网络区别

<img src="https://i0.hdslb.com/bfs/article/b5fe567304ae533fb189b255562f045b10981316.png" title="" alt="" data-align="center">

名称空间（Namespace）:

![](https://i0.hdslb.com/bfs/article/8d2d39223daa23a71bf7c930521c06f384da4075.png)

Docker没有namespace名称空间，而Containerd是支持namespaces的，对于上层编排系统的支持，主要区分了3个命名空间分别是k8s.io、moby和default，以上我们用crictl操作的均在k8s.io命名空间完成如查看镜像列表就需要加上-n参数 .
