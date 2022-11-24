修改`/etc/fstab`文件，将原本要挂载的`/dev/sdb`换成对应的`UUID`即可（因为 sda 和 sdb 可能会变，而 UUID 是不会变的）。

通过命令 `blkid` 查看对应设备的 UUID

```plain
> blkid

/dev/sda1: UUID="a0b19198-16d0-4f3d-b3fb-53359da6fe5f" BLOCK_SIZE="4096" TYPE="xfs" PARTUUID="e6c8efc2-71a2-9a48-a56e-23aaa49a0bcd"
/dev/sda2: UUID="cf4e2207-8fe6-45bf-9ea1-73618d788f69" BLOCK_SIZE="4096" TYPE="xfs" PARTUUID="126ea669-f627-bb41-9018-7b13f3a2ba24"
/dev/sda3: UUID="72cde011-1938-4b93-aede-17094575b786" BLOCK_SIZE="4096" TYPE="xfs" PARTUUID="01dfdbdd-e375-ae4b-95db-cf33dca9c7de"
/dev/sda4: UUID="a451cacc-3954-4e54-a3dc-dd4a59bed864" BLOCK_SIZE="4096" TYPE="xfs" PARTUUID="e21330dc-1c87-1843-9622-81b1fde0e922"
/dev/sda5: UUID="cf4d4b4d-3ff1-493a-b4fc-53650a4f9f29" BLOCK_SIZE="4096" TYPE="xfs" PARTUUID="16df639f-3b1e-f243-bceb-115227827f5b"
/dev/sda6: UUID="88ee5dcf-cd1f-4188-80de-7b91256cb5da" BLOCK_SIZE="4096" TYPE="xfs" PARTUUID="497cc9cb-0219-074a-b8e3-47d2c531c8f7"
/dev/sda7: UUID="6b2e61dc-3cb5-4d22-ab54-b0a6bb25b877" BLOCK_SIZE="4096" TYPE="xfs" PARTUUID="4c5c357a-54c1-c645-a7fb-e121baccb796"
/dev/sda8: UUID="5883ad54-9569-477c-9b80-61b890f734ff" BLOCK_SIZE="4096" TYPE="xfs" PARTUUID="25890a45-3f59-414d-94be-b5e90653acd2"
/dev/sda9: UUID="88111a1c-aec7-4b7a-8b32-dd906237d72e" BLOCK_SIZE="4096" TYPE="xfs" PARTUUID="7256e4d7-9eb6-ee49-8ad7-1927f050eab6"
/dev/sda10: UUID="8014d911-75ba-4337-b980-228b09cf2df9" BLOCK_SIZE="4096" TYPE="xfs" PARTUUID="6ce272b1-5c6b-e242-bad5-221528f0d0a5"
/dev/sda11: UUID="00b24ccd-c454-4dc1-8267-11b5c1cdb688" BLOCK_SIZE="4096" TYPE="xfs" PARTUUID="a35b723d-d3d0-8544-994f-e93ffd09694e"
/dev/sda12: UUID="6cb01c97-5767-4103-a970-0e1a524eee63" BLOCK_SIZE="4096" TYPE="xfs" PARTUUID="15bc88e0-7369-3f4b-b911-ee4b62cb98d0"
/dev/sda13: UUID="5f088374-3cb5-457d-8a80-418a689bf41d" BLOCK_SIZE="4096" TYPE="xfs" PARTUUID="c43b7ef2-5ef3-3844-a939-637b0b1c73af"
/dev/sda14: UUID="82a66b9c-8713-49e3-89c9-11a376132e9c" BLOCK_SIZE="4096" TYPE="xfs" PARTUUID="2081fac6-0dcb-3a4b-8fe4-0fd1f3443917"

```

修改后的`/etc/fstab`文件如下

```plain
#
# /etc/fstab
# Created by anaconda on Fri Sep  9 16:37:42 2022
#
# Accessible filesystems, by reference, are maintained under '/dev/disk/'.
# See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info.
#
# After editing this file, run 'systemctl daemon-reload' to update systemd
# units generated from this file.
#
...

# start beegfs storage
UUID="a0b19198-16d0-4f3d-b3fb-53359da6fe5f" /beegfs-storage/pool301 xfs defaults 0 0
UUID="cf4e2207-8fe6-45bf-9ea1-73618d788f69" /beegfs-storage/pool302 xfs defaults 0 0
UUID="72cde011-1938-4b93-aede-17094575b786" /beegfs-storage/pool303 xfs defaults 0 0
UUID="a451cacc-3954-4e54-a3dc-dd4a59bed864" /beegfs-storage/pool304 xfs defaults 0 0
UUID="cf4d4b4d-3ff1-493a-b4fc-53650a4f9f29" /beegfs-storage/pool305 xfs defaults 0 0
UUID="88ee5dcf-cd1f-4188-80de-7b91256cb5da" /beegfs-storage/pool306 xfs defaults 0 0
UUID="6b2e61dc-3cb5-4d22-ab54-b0a6bb25b877" /beegfs-storage/pool307 xfs defaults 0 0
UUID="5883ad54-9569-477c-9b80-61b890f734ff" /beegfs-storage/pool308 xfs defaults 0 0
UUID="88111a1c-aec7-4b7a-8b32-dd906237d72e" /beegfs-storage/pool309 xfs defaults 0 0
UUID="8014d911-75ba-4337-b980-228b09cf2df9" /beegfs-storage/pool310 xfs defaults 0 0
UUID="00b24ccd-c454-4dc1-8267-11b5c1cdb688" /beegfs-storage/pool311 xfs defaults 0 0
UUID="6cb01c97-5767-4103-a970-0e1a524eee63" /beegfs-storage/pool312 xfs defaults 0 0
UUID="5f088374-3cb5-457d-8a80-418a689bf41d" /beegfs-storage/pool313 xfs defaults 0 0
UUID="82a66b9c-8713-49e3-89c9-11a376132e9c" /beegfs-storage/pool314 xfs defaults 0 0
# end beegfs storage

```

