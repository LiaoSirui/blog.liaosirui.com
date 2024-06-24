AD 域控配置 NTP 时间服务器方法

查看该域控是否为 NTPServer；如下图 Ntpserver 中，“Enabled” 值为 “1” 说明当前域控是 NTP 服务器；若该值为 “0”，则需要在注册表的下列位置

```powershell
w32tm /query /configuration
#  HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\NtpServer
# 将 Enabled 值改为 1
```

用命令查看主机的时间源信息，可以看到当前 PDC 主机的时间来源为系统时钟

```powershell
w32tm /query /status
```

验证 NTP 时间源是否与 AD 域通讯是否正常

```powershell
w32tm /stripchart /computer:[NTP_IP]
```

在域控主机上执行命令

```powershell
w32tm /config /manualpeerlist:[NTP_IP] /syncfromflags:manual /reliable:yes /update
```

