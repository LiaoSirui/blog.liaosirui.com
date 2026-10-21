安装包

```bash
dnf install -y tigervnc-server
```

切换到使用 VNC 的用户

```bash
su - cyril
```

配置一个 VNC 密码

```bash
vncpasswd
```

在创建一个用户之后，必须分配一个端口号，编辑 `/etc/tigervnc/vncserver.users` 文件并添加以下一行。

```bash
:1=cyrl
```

修改配置文件 `/etc/tigervnc/vncserver-config-defaults`

```bash
session=gnome
```

启动服务

```bash
systemctl daemon-reload
systemctl start vncserver@:1.service
```

VNC 关闭

```bash
vncserver -kill :1
```
