```bash
> beegfs-net -h

DESCRIPTION: Show all network connections that are currently established from
this client to the BeeGFS servers.
(This script reads information from /proc/fs/beegfs.)

NOTE: BeeGFS clients establish connections on demand and also drop idle
connections after some time, so it does not automatically indicate an error if
there is no connection currently established to a certain server.

USAGE: beegfs-net [options]

   -h        - Print this help.

   -n        - No "df". By default, this script calls the "df" command to
               force the client module to establish storage server connections,
               but this can block if a storage server is unreachable.
```

查看集群服务连接情况：`beegfs-net`