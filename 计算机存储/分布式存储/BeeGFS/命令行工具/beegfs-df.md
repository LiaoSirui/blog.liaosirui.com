```bash
> beegfs-df -h

DESCRIPTION: Show free space information and available number of inodes for
individual BeeGFS metadata servers and storage targets.
(This is a wrapper for beegfs-ctl.)

USAGE: beegfs-df [options]

   (default) - If no command line argument is given, list servers and targets
               based on the default client config file.

   -h        - Print this help.

   -p <path> - Show servers and targets for the given BeeGFS mount point.

   -c <path> - Show servers and targets for the given BeeGFS client
               configuration file.

   -e        - Exit code reports an error if a target is not
               in the reachability state online or not in the
               consistency state good.

   -s <ID>   - Show only storage targets belonging to storage pool with ID <ID>

               consistency state good, requires the option --state.
```

查看集群存储池状态：`beegfs-df`