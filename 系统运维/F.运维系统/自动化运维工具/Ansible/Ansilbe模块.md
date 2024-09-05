ansible 很多模块都可以做到 “见其名，知其意”，很多模块都是对 Linux 命令的模仿或者封装，更多模块可参见官方文档。下面我们先挑几个模块简单介绍一下：

- synchronize，copy，unarchive 都可以上传文件。
- ping：检查指定节点机器是否还能连通。主机如果在线，则回复pong。
- yum, apt：这两个模块都是在远程系统上安装包的。
- pip：远程机器上 python 安装包。
- user，group：用户管理的。
- service：管理服务的，类似于 centos7 上的 service。

