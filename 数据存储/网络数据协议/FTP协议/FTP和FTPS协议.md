## FPTS

FTPS 是在安全套接层使用标准的 FTP 协议和指令的一种增强型 FTP 协议，为 FTP 协议和数据通道增加了 SSL 安全功能。FTPS 也称作 “FTP-SSL” 和 “FTP-over-SSL”。SSL 是一个在客户机和具有 SSL 功能的服务器之间的安全连接中对数据进行加密和解密的协议。

## CurlFtpFS

报错：`Error setting curl: CURLOPT_SSL_VERIFYHOST no longer supports 1 as value!`

修改 `ftpfs.c`

```c
1627   if (ftpfs.no_verify_hostname) {
1628     /* The default is 2 which verifies even the host string. This sets to 1
1629      * which means verify the host but not the string. */
1630     curl_easy_setopt_or_die(easy, CURLOPT_SSL_VERIFYHOST, 0);
1631   }
```

## 参考资料

- <https://blog.csdn.net/juanxiaseng0838/article/details/126302293>