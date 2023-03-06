```bash
> beegfs-fsck -h
BeeGFS File System Check (http://www.beegfs.com)
Version: 7.3.2

GENERAL USAGE:
 $ beegfs-fsck --<modename> --help
 $ beegfs-fsck --<modename> [mode_arguments] [client_arguments]

MODES:
 --checkfs     => Perform a full check and optional repair of
                  a BeeGFS instance.
 --enablequota => Set attributes needed for quota support in FhGFS.
                  Can be used to enable quota support on an existing
                  system.

USAGE:
 This is the BeeGFS file system consistency check and repair tool.

 Choose a mode from the list above and use the parameter "--help"
 to show arguments and usage examples for that particular mode.

 (Running beegfs-fsck requires root privileges.)

 Example: Show help for mode "--checkfs"
  $ beegfs-fsck --checkfs --help
```

