## 新增 storage 节点

先停止所有的 client 服务

```bash
systemctl stop beegfs-client.service

systemctl stop beegfs-helperd.service
```

停止所有的 storage 服务

```bash
systemctl stop beegfs-storage.service
```

依次增加 stoarge

```bash
# devmaster1
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs-storage/pool102 -s 1 -i 102 -m 10.244.244.103
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs-storage/pool103 -s 1 -i 103 -m 10.244.244.103
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs-storage/pool104 -s 1 -i 104 -m 10.244.244.103
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs-storage/pool105 -s 1 -i 105 -m 10.244.244.103
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs-storage/pool106 -s 1 -i 106 -m 10.244.244.103
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs-storage/pool107 -s 1 -i 107 -m 10.244.244.103
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs-storage/pool108 -s 1 -i 108 -m 10.244.244.103
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs-storage/pool109 -s 1 -i 109 -m 10.244.244.103
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs-storage/pool110 -s 1 -i 110 -m 10.244.244.103
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs-storage/pool111 -s 1 -i 111 -m 10.244.244.103
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs-storage/pool112 -s 1 -i 112 -m 10.244.244.103
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs-storage/pool113 -s 1 -i 113 -m 10.244.244.103
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs-storage/pool114 -s 1 -i 114 -m 10.244.244.103

# devmaster2
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs-storage/pool202 -s 2 -i 202 -m 10.244.244.103
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs-storage/pool203 -s 2 -i 203 -m 10.244.244.103
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs-storage/pool204 -s 2 -i 204 -m 10.244.244.103
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs-storage/pool205 -s 2 -i 205 -m 10.244.244.103
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs-storage/pool206 -s 2 -i 206 -m 10.244.244.103
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs-storage/pool207 -s 2 -i 207 -m 10.244.244.103
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs-storage/pool208 -s 2 -i 208 -m 10.244.244.103
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs-storage/pool209 -s 2 -i 209 -m 10.244.244.103
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs-storage/pool210 -s 2 -i 210 -m 10.244.244.103
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs-storage/pool211 -s 2 -i 211 -m 10.244.244.103
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs-storage/pool212 -s 2 -i 212 -m 10.244.244.103
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs-storage/pool213 -s 2 -i 213 -m 10.244.244.103
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs-storage/pool214 -s 2 -i 214 -m 10.244.244.103

# devmaster3
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs-storage/pool302 -s 3 -i 302 -m 10.244.244.103
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs-storage/pool303 -s 3 -i 303 -m 10.244.244.103
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs-storage/pool304 -s 3 -i 304 -m 10.244.244.103
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs-storage/pool305 -s 3 -i 305 -m 10.244.244.103
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs-storage/pool306 -s 3 -i 306 -m 10.244.244.103
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs-storage/pool307 -s 3 -i 307 -m 10.244.244.103
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs-storage/pool308 -s 3 -i 308 -m 10.244.244.103
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs-storage/pool309 -s 3 -i 309 -m 10.244.244.103
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs-storage/pool310 -s 3 -i 310 -m 10.244.244.103
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs-storage/pool311 -s 3 -i 311 -m 10.244.244.103
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs-storage/pool312 -s 3 -i 312 -m 10.244.244.103
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs-storage/pool313 -s 3 -i 313 -m 10.244.244.103
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs-storage/pool314 -s 3 -i 314 -m 10.244.244.103


```

重新启动 beegfs-storage

```bash
systemctl start beegfs-storage.service
```

重启所有客户端

```bash
systemctl start beegfs-helperd.service

systemctl start beegfs-client.service
```

查看存储池

```bash
> beegfs-df

METADATA SERVERS:
TargetID   Cap. Pool        Total         Free    %      ITotal       IFree    %
========   =========        =====         ====    =      ======       =====    =
       3      normal     238.4GiB     144.2GiB  61%      125.0M      125.0M 100%

STORAGE TARGETS:
TargetID   Cap. Pool        Total         Free    %      ITotal       IFree    %
========   =========        =====         ====    =      ======       =====    =
     101         low     238.4GiB     144.2GiB  61%      125.0M      125.0M 100%
     102         low    1023.5GiB    1016.3GiB  99%      107.4M      107.4M 100%
     103         low    1023.5GiB    1016.3GiB  99%      107.4M      107.4M 100%
     104         low    1023.5GiB    1016.3GiB  99%      107.4M      107.4M 100%
     105         low    1023.5GiB    1016.3GiB  99%      107.4M      107.4M 100%
     106         low    1023.5GiB    1016.3GiB  99%      107.4M      107.4M 100%
     107         low    1023.5GiB    1016.3GiB  99%      107.4M      107.4M 100%
     108         low    1023.5GiB    1016.3GiB  99%      107.4M      107.4M 100%
     109         low    1023.5GiB    1016.3GiB  99%      107.4M      107.4M 100%
     110         low    1023.5GiB    1016.3GiB  99%      107.4M      107.4M 100%
     111         low    1023.5GiB    1016.3GiB  99%      107.4M      107.4M 100%
     112         low    1023.5GiB    1016.3GiB  99%      107.4M      107.4M 100%
     113         low    1023.5GiB    1016.3GiB  99%      107.4M      107.4M 100%
     114      normal    1589.2GiB    1578.1GiB  99%      166.7M      166.7M 100%
     201         low     238.4GiB     144.2GiB  61%      125.0M      125.0M 100%
     202         low    1023.5GiB    1016.3GiB  99%      107.4M      107.4M 100%
     203         low    1023.5GiB    1016.3GiB  99%      107.4M      107.4M 100%
     204         low    1023.5GiB    1016.3GiB  99%      107.4M      107.4M 100%
     205         low    1023.5GiB    1016.3GiB  99%      107.4M      107.4M 100%
     206         low    1023.5GiB    1016.3GiB  99%      107.4M      107.4M 100%
     207         low    1023.5GiB    1016.3GiB  99%      107.4M      107.4M 100%
     208         low    1023.5GiB    1016.3GiB  99%      107.4M      107.4M 100%
     209         low    1023.5GiB    1016.3GiB  99%      107.4M      107.4M 100%
     210         low    1023.5GiB    1016.3GiB  99%      107.4M      107.4M 100%
     211         low    1023.5GiB    1016.3GiB  99%      107.4M      107.4M 100%
     212         low    1023.5GiB    1016.3GiB  99%      107.4M      107.4M 100%
     213         low    1023.5GiB    1016.3GiB  99%      107.4M      107.4M 100%
     214      normal    1589.2GiB    1578.1GiB  99%      166.7M      166.7M 100%
     301         low     238.4GiB     144.2GiB  61%      125.0M      125.0M 100%
     302         low    1023.5GiB    1016.3GiB  99%      107.4M      107.4M 100%
     303         low    1023.5GiB    1016.3GiB  99%      107.4M      107.4M 100%
     304         low    1023.5GiB    1016.3GiB  99%      107.4M      107.4M 100%
     305         low    1023.5GiB    1016.3GiB  99%      107.4M      107.4M 100%
     306         low    1023.5GiB    1016.3GiB  99%      107.4M      107.4M 100%
     307         low    1023.5GiB    1016.3GiB  99%      107.4M      107.4M 100%
     308         low    1023.5GiB    1016.3GiB  99%      107.4M      107.4M 100%
     309         low    1023.5GiB    1016.3GiB  99%      107.4M      107.4M 100%
     310         low    1023.5GiB    1016.3GiB  99%      107.4M      107.4M 100%
     311         low    1023.5GiB    1016.3GiB  99%      107.4M      107.4M 100%
     312         low    1023.5GiB    1016.3GiB  99%      107.4M      107.4M 100%
     313         low    1023.5GiB    1016.3GiB  99%      107.4M      107.4M 100%
     314      normal    1589.2GiB    1578.1GiB  99%      166.7M      166.7M 100%
```

查看存储 target

```bash
> beegfs-ctl --listtargets --nodetype=storage --state

TargetID     Reachability  Consistency   NodeID
========     ============  ===========   ======
     101           Online         Good        1
     102           Online         Good        1
     103           Online         Good        1
     104           Online         Good        1
     105           Online         Good        1
     106           Online         Good        1
     107           Online         Good        1
     108           Online         Good        1
     109           Online         Good        1
     110           Online         Good        1
     111           Online         Good        1
     112           Online         Good        1
     113           Online         Good        1
     114           Online         Good        1
     201           Online         Good        2
     202           Online         Good        2
     203           Online         Good        2
     204           Online         Good        2
     205           Online         Good        2
     206           Online         Good        2
     207           Online         Good        2
     208           Online         Good        2
     209           Online         Good        2
     210           Online         Good        2
     211           Online         Good        2
     212           Online         Good        2
     213           Online         Good        2
     214           Online         Good        2
     301           Online         Good        3
     302           Online         Good        3
     303           Online         Good        3
     304           Online         Good        3
     305           Online         Good        3
     306           Online         Good        3
     307           Online         Good        3
     308           Online         Good        3
     309           Online         Good        3
     310           Online         Good        3
     311           Online         Good        3
     312           Online         Good        3
     313           Online         Good        3
     314           Online         Good        3
```



## 移除存储节点

迁移数据

```bash
beegfs-ctl --migrate --targetid=101 /mnt/beegfs
beegfs-ctl --removetarget 101

beegfs-ctl --migrate --targetid=201 /mnt/beegfs
beegfs-ctl --removetarget 201

beegfs-ctl --migrate --targetid=301 /mnt/beegfs
beegfs-ctl --removetarget 301
```

移除对应的 `/etc/beegfs/beegfs-storage.conf` 配置

```ini
# devmaster1
storeStorageDirectory        =  ,/beegfs-storage/pool102 ,/beegfs-storage/pool103 ,/beegfs-storage/pool104 ,/beegfs-storage/pool105 ,/beegfs-storage/pool106 ,/beegfs-storage/pool107 ,/beegfs-storage/pool108 ,/beegfs-storage/pool109 ,/beegfs-storage/pool110 ,/beegfs-storage/pool111 ,/beegfs-storage/pool112 ,/beegfs-storage/pool113 ,/beegfs-storage/pool114
storeAllowFirstRunInit       = false
storeFsUUID                  =  ,dc96b920-f5e3-42a9-aa2c-aaffc6f33255 ,556ba248-9195-422b-8a4b-f67617c2f1a6 ,9c81b2b1-cccf-4231-9b07-4fd4ed566562 ,87966713-505b-4c1c-8c07-9afd3e39f905 ,94e03369-332a-4d4f-ba1f-926b45400f09 ,63bfef15-f18a-4ff3-a35b-8ca5b70c4081 ,2c698fa3-29e2-4c35-aa0c-8bb3bbd43c95 ,9b175afb-448c-4bfb-8c40-2ff8fd2dd922 ,2f1e6593-ad86-44d0-97b8-82affebc22df ,172680d6-3dad-44ee-8549-376cd522fcb9 ,a8382b6b-855c-49fe-9511-595b5ec504b6 ,cd6846b8-93b1-42ea-b9db-41e5cfe06018 ,426311b8-3a32-4971-bfa3-18269fc2f9be

# devmaster2
storeStorageDirectory        =  ,/beegfs-storage/pool202 ,/beegfs-storage/pool203 ,/beegfs-storage/pool204 ,/beegfs-storage/pool205 ,/beegfs-storage/pool206 ,/beegfs-storage/pool207 ,/beegfs-storage/pool208 ,/beegfs-storage/pool209 ,/beegfs-storage/pool210 ,/beegfs-storage/pool211 ,/beegfs-storage/pool212 ,/beegfs-storage/pool213 ,/beegfs-storage/pool214
storeAllowFirstRunInit       = false
storeFsUUID                  =  ,872f42ee-f548-4873-9260-28570874aaca ,e85c38ad-0842-4206-b404-33b948ac4f86 ,c48cd098-dab2-4b6d-9375-3ab245c64c50 ,0ff9ca76-2e4f-4653-b205-e85a1875eedd ,869b14fd-3bbd-483f-b300-ad71cea51b8e ,cd6a7fbc-9e8a-4111-82f0-60c4c26facba ,ef8a9cf5-3623-4a3e-84ed-bceb063b12f2 ,aeba2f9b-42b1-4391-b4a6-44b2bb08cce5 ,aab1519b-64b7-4da5-8943-d84ace818bd9 ,238ece85-12c2-4623-bf4d-ed30ab818c21 ,219974b5-6e38-477b-9563-0416b422d9df ,4f22db1c-c29b-4d18-a2cf-3c37a3b49c5d ,2f2ed118-7025-44f0-aba9-9902fd3d66a8

# devmaster3
storeStorageDirectory        =  ,/beegfs-storage/pool302 ,/beegfs-storage/pool303 ,/beegfs-storage/pool304 ,/beegfs-storage/pool305 ,/beegfs-storage/pool306 ,/beegfs-storage/pool307 ,/beegfs-storage/pool308 ,/beegfs-storage/pool309 ,/beegfs-storage/pool310 ,/beegfs-storage/pool311 ,/beegfs-storage/pool312 ,/beegfs-storage/pool313 ,/beegfs-storage/pool314
storeAllowFirstRunInit       = false
storeFsUUID                  =  ,cf4e2207-8fe6-45bf-9ea1-73618d788f69 ,72cde011-1938-4b93-aede-17094575b786 ,a451cacc-3954-4e54-a3dc-dd4a59bed864 ,cf4d4b4d-3ff1-493a-b4fc-53650a4f9f29 ,88ee5dcf-cd1f-4188-80de-7b91256cb5da ,6b2e61dc-3cb5-4d22-ab54-b0a6bb25b877 ,5883ad54-9569-477c-9b80-61b890f734ff ,88111a1c-aec7-4b7a-8b32-dd906237d72e ,8014d911-75ba-4337-b980-228b09cf2df9 ,00b24ccd-c454-4dc1-8267-11b5c1cdb688 ,6cb01c97-5767-4103-a970-0e1a524eee63 ,5f088374-3cb5-457d-8a80-418a689bf41d ,82a66b9c-8713-49e3-89c9-11a376132e9c
```

重启 storage 服务

```bash
systemctl restart beegfs-storage.service
```

重启 client 服务

```bash
systemctl restart beegfs-helperd.service
systemctl restart beegfs-client.service
```

