```bash
> beegfs-check-servers -h

DESCRIPTION: Check if all BeeGFS servers are reachable from this host.
             (This is a wrapper for beegfs-ctl.)

USAGE: beegfs-check-servers [options]

   (default) - If no command line argument is given, check servers based on
               default client config file.

   -h        - Print this help.

   -p <path> - Check servers for the given BeeGFS mount point.

   -c <path> - Check servers for the given BeeGFS client config file.

   -e        - Exit code reports an error if a node is not reachable.

```

