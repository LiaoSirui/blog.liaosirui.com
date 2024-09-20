- <https://www.a-programmer.top/2021/10/30/NVMe%20namespace/>

列出现有的 NVMe 设备和命名空间

在删除和创建命名空间之前，列出现有的 NVMe 设备和命名空间以确认其状态：

```
sudo nvme list
sudo nvme list-ns /dev/nvme0
```

删除命名空间

使用 `nvme delete-ns` 命令删除现有的命名空间。假设命名空间 ID 是 `1`，设备路径是 `/dev/nvme0`：

```
sudo nvme delete-ns /dev/nvme0 -n 1
```

创建新命名空间

使用 `nvme create-ns` 命令创建新的命名空间。例如，创建一个 100GB 的命名空间：

```
sudo nvme create-ns /dev/nvme0 --nsze=209715200 --ncap=209715200 --flbas=0
```

- `--nsze`：命名空间大小，以块为单位。
- `--ncap`：命名空间容量，以块为单位。
- `--flbas`：格式化 LBA 大小（通常为 0，表示使用默认大小）。

激活新命名空间

使用 `nvme attach-ns` 命令激活新创建的命名空间。假设命名空间 ID 是 `2`，控制器 ID 是 `1`：

```
sudo nvme attach-ns /dev/nvme0 -n 2 -c 1
```

列出新的命名空间

再次列出 NVMe 设备和命名空间，确保新创建的命名空间已成功添加：

```
sudo nvme list-ns /dev/nvme0
```



- <https://blog.csdn.net/BGONE/article/details/125399776>

`nsze` 和 `ncap` 是 NVMe 命名空间的两个关键属性：

- `nsze` (Namespace Size)：指定命名空间的大小，以逻辑块数（LBAs, Logical Block Addresses）为单位。
- `ncap` (Namespace Capacity)：指定命名空间的容量，同样以逻辑块数为单位。



- <https://www.cnblogs.com/ingram14/p/15778947.html>

- <https://cloud-atlas.readthedocs.io/zh-cn/latest/linux/storage/nvme/nvme-cli.html>

查看那 nvme 寿命 <https://yan-jian.com/%E5%A6%82%E4%BD%95%E6%9F%A5%E7%9C%8B%E5%9B%BA%E6%80%81%E7%A1%AC%E7%9B%98%E5%AF%BF%E5%91%BD.html>

