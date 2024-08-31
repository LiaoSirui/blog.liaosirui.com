overlay file system 可以做到：将两个 file system merge 在一起，下层的文件系统只读，上层的文件系统可写

- 如果读取，找到上层就读上层的，否则的话就找到下层的读

- 如果写入，会写入到上层

这样，其实对于最终用户来说，可以认为只有一个 merge 之后的文件系统，用起来和普通文件系统没有什么区别

有了这个功能，Docker 运行的时候，从最下层的文件系统开始，merge 两层，得到新的 fs 然后再 merge 上一层，然后再 merge 最上一层，最后得到最终的 directory，然后用 chroot 改变进程的 root 目录，启动 container。

![How Docker constructs map to OverlayFS constructs](.assets/overlay_constructs.jpg)

会存在以下的多用户复用共享文件和目录的场景：

![img](.assets/20170916113511895.jpeg)

<https://blog.csdn.net/luckyapple1028/article/details/77916194>

了解了原理之后，你会发现，这种设计对于 Docker 来说非常合适：

1. 如果 2 个 image 都是基于 Ubuntu，那么两个 Image 可以共用 Ubuntu 的 base image，只需要存储一份；
2. 如果 pull 新的 image，某一层如果已经存在，那么这一层之前的内容其实就不需要 pull 了；



如何手动挂载 overlay

```bash
mount -t overlay overlay \
  -o lowerdir=/lower,upperdir=/upper,workdir=/work
```

- `/lower` base directory will be read only
- `/upper` where changes will go
- `/work` must be empty
