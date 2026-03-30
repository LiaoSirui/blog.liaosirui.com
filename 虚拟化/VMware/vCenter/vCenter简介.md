## 安装后配置

### 调整密码策略

![image-20260330152715170](./.assets/vCenter简介/image-20260330152715170.png)

### 时间服务器和时区

进入 vCenter 管理，通常运行在 5480 端口。

修改时区，时间同步使用 NTP 模式。

![image-20260330152725539](./.assets/vCenter简介/image-20260330152725539.png)

### 许可证

## 其他

修改域

```bash
cmsso-util domain-repoint -m execute --src-emb-admin Administrator --dest-domain-name vsphere.local
```

