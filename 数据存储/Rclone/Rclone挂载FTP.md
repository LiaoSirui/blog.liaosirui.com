配置 rclone

```bash
rclone config
```

- <https://rclone.cn/storage/ftp/>

隐式 TLS

```bash
Options:
- type: ftp
- host: x.x.x.x
- user: xxx
- port: 1121
- pass: *** ENCRYPTED ***
- tls: true
- explicit_tls: true
- concurrency: 5
- no_check_certificate: true
- disable_epsv: true
- disable_mlsd: true
- allow_insecure_tls_ciphers: true
- encoding: Slash,Ctl,LeftPeriod
```

