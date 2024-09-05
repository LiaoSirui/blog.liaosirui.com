## GNOME Keyring 简介

GNOME Keyring 是一个守护进程应用，用于管理用户的安全凭证，例如用户名和密码

敏感数据会被加密后存储在用户主目录中的”密钥环文件”中

默认密钥环使用登录密码进行加密，因此用户不需要记住另一个密码；

GNOME Keyring 作为守护程序实现，并使用 gnome-keyring-daemon 为进程名称。应用程序可以使用 libgnome-keyring 库来存储和请求使用密码；

GNOME Keyring 是 GNOME 桌面的组成部分之一，很多系统中都有类似的应用程序，比如 macOS 中的 Keychain Access，再 KDE 桌面环境中的 KWallet

```bash
# should add capability IPC_LOCK in container ??
# setcap -r /usr/bin/gnome-keyring-daemon

dbus-run-session -- /usr/bin/gnome-keyring-daemon --unlock --start --foreground --components=secrets 

```

## 参考资料

<https://blog.k4nz.com/3fed12e9274b7b42955bc26568a5c72f/>