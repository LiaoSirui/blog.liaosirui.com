- MAD（Management Datagram）：

MAD是InfiniBand网络中用于管理和配置的数据报文。它包含了各种类型的管理操作，如查询端口状态、配置端口参数等。MAD通常用于执行网络管理任务。

- uMAD（User MAD）：

uMAD是用户空间应用程序与InfiniBand子系统之间进行通信的接口。它允许应用程序发送和接收MAD消息，以执行特定的管理操作。通过uMAD，应用程序可以直接与InfiniBand网络进行交互，执行各种管理任务。

- Verbs API：

Verbs是一种用于编程InfiniBand和RoCE（RDMA over Converged Ethernet）设备的API（Application Programming Interface）。它提供了一组函数和数据结构，用于创建和管理RDMA连接、发送和接收数据等操作。Verbs API是一种低级别的编程接口，允许应用程序直接操纵RDMA设备。

- RDMACM（RDMA Connection Manager）：

RDMACM是一个库，用于管理RDMA连接的建立、维护和关闭。它提供了一组函数，使应用程序能够发现和连接远程节点，并在需要时建立RDMA连接。RDMACM简化了RDMA连接的管理过程，使应用程序可以更方便地使用RDMA功能。

参考资料：<https://blog.csdn.net/eidolon_foot/article/details/132840943>