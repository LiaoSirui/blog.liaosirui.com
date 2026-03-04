创建备份

```bash
gitlab-rake gitlab:backup:create
```

获取备份文件：备份文件通常以时间戳命名

将生成的文件（`/var/opt/gitlab/backups` 下的 `.tar` 文件）通过 `scp` 或 `rsync` 移动到安全的外部存储，确保灾难恢复

启动新的容器，然后将刚才备份的文件拷贝到容器里，后面两个文件直接覆盖即可

拷贝完之后，进入容器，进入备份目录，执行如下命令

```bash
gitlab-rake gitlab:backup:restore BACKUP=1672294041_2022_12_29_11.1.4
```

恢复之后，重新加载配置，并重启 Gitlab

```bash
gitlab-ctl reconfigure

gitlab-ctl restart
```

