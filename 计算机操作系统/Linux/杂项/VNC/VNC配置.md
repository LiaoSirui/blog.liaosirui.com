安装包

```
apt install tightvncserver
```

初始化

```
> vncserver

# 提示如下
Output
You will require a password to access your desktops.

Password:
Verify:
```

改密码

```
vncpasswd
```

VNC 关闭

```
vncserver -kill :1
```

