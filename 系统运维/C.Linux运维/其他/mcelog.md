mcelog 是 Linux 系统上用来检查硬件错误，特别是内存和 CPU 错误的工具。未纠正的错误是关键异常，如果 CPU 无法恢复，往往会导致系统上的内核错误

```
mcelog: ERROR: AMD Processor family 23: mcelog does not support this processor.  Please use the edac_mce_amd module instead.
CPU is unsupported
```

AMD  CPU：mcelog 不支持该处理器。因此，建议使用 edac_mce_amd 内核模块来处理该处理器的错误

```
modprobe edac_mce_amd

# 禁用 mcelog 模块
systemctl disable mcelog.service
```

`mcelog` 是已弃用，应该使用 `rasdaemon`