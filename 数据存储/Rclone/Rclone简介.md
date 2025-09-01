## Rclone 简介

Rclone 是一个命令行程序，用于管理云存储上的文件。它是云供应商的网络存储接口的一个功能丰富的替代品。超过 40 种云存储产品支持 rclone，包括 S3 对象存储、企业和消费者文件存储服务以及标准传输协议。

官网：<https://rclone.org/>

安装

```bash
https://downloads.rclone.org/rclone-current-linux-amd64.zip
```

## 常用命令

| 命令          | 说明                                                         |
| :------------ | :----------------------------------------------------------- |
| rclone copy   | 复制                                                         |
| rclone move   | 移动，如果要在移动后删除空源目录，加上 `--delete-empty-src-dirs` 参数 |
| rclone mount  | 挂载                                                         |
| rclone sync   | 同步：将源目录同步到目标目录，只更改目标目录                 |
| rclone size   | 查看网盘文件占用大小                                         |
| rclone delete | 删除路径下的文件内容                                         |
| rclone purge  | 删除路径及其所有文件内容                                     |
| rclone mkdir  | 创建目录                                                     |
| rclone rmdir  | 删除目录                                                     |
| rclone rmdirs | 删除指定环境下的空目录。如果加上 `--leave-root` 参数，则不会删除根目录 |
| rclone check  | 检查源和目的地址数据是否匹配                                 |
| rclone ls     | 列出指定路径下的所有的文件以及文件大小和路径                 |
| rclone lsl    | 比上面多一个显示上传时间                                     |
| rclone lsd    | 列出指定路径下的目录                                         |
| rclone lsf    | 列出指定路径下的目录和文件                                   |

## 参考资料

- <https://cloud.tencent.com/developer/article/2192254>