## LXCFS 简介

基于FUSE实现的用户空间文件系统

- 站在文件系统的角度: 通过调用`libfuse库`和 `内核的FUSE模块`交互实现
- 两个基本功能
- `让每个容器有自身的cgroup文件系统视图`,类似 Cgroup Namespace
- `提供容器内部虚拟的proc文件系统`