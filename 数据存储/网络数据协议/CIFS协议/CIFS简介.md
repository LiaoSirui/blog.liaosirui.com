CIFS 协议通过不同的命令码（Command Codes）实现文件和会话操作

<https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-cifs/32b5d4b7-d90b-483f-ad6a-003fd110f0ec>

常见：

- 5   CREATE（打开/创建文件）
- 6   CLOSE
- 7   FLUSH
- 8   READ
- 9   WRITE
- 14  QUERY_DIRECTORY（目录列举）
- 16  QUERY_INFO
- 17  SET_INFO
- 18  OPLOCK_BREAK

调试连接信息

```bash
cat /proc/fs/cifs/DebugData | grep -i -E 'address|ip'
```

查看容器挂载

```bash
grep cifs /proc/self/mountinfo |grep 37e01c35
```

调试

```bash
cd /sys/kernel/tracing
echo 1 > events/cifs/smb3_read_enter/enable
echo 1 > events/cifs/smb3_read_done/enable
echo 1 > events/cifs/smb3_read_err/enable
cat trace_pipe

# 完成后用 echo 0 关闭上面的事件
echo 0 > events/cifs/smb3_read_enter/enable
echo 0 > events/cifs/smb3_read_done/enable
echo 0 > events/cifs/smb3_read_err/enable
```

SMB 用 credits 限制同时在途的请求数量。credits 不足时，即使带宽充足也读不快：

```bash
grep -i -E 'credits|In Flight|in_flight' /proc/fs/cifs/DebugData
```

用 ss 看连接信息

```bash
ss -tni dst 192.168.15.248 dport = :445
```

