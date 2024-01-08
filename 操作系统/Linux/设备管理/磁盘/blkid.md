查看 disk uuid

```bash
blkid -s UUID -o value /dev/sdb

# export DISK_UUID=$(blkid -s UUID -o value /dev/sdb)
```
