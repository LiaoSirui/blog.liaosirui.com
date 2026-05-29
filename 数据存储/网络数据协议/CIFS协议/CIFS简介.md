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