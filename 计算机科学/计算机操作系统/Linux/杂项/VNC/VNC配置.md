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

使用 GNome

安装桌面环境所需的软件包，包括系统面板、窗口管理器、文件浏览器、终端等桌面应用程序

```
apt install gnome-panel gnome-settings-daemon metacity nautilus gnome-terminal ubuntu-desktop dbus-x11 xfont-base 

apt-get install xfonts-100dpi
apt-get install xfonts-100dpi-transcoded
apt-get install xfonts-75dpi
apt-get install xfonts-75dpi-transcoded
apt-get install xfonts-base
```

GNOME Flashback 桌面环境和 metacity 窗口管理器

```
#!/bin/sh
export XKL_XMODMAP_DISABLE=1
export XDG_CURRENT_DESKTOP="GNOME-Flashback:GNOME"
export XDG_MENU_PREFIX="gnome-flashback-"
gnome-session --session=gnome-flashback-metacity --disable-acceleration-check
```

另一个版本

```
#!/bin/sh

unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

export XKL_XMODMAP_DISABLE=1
export XDG_CURRENT_DESKTOP="GNOME-Flashback:GNOME"
export XDG_MENU_PREFIX="gnome-flashback-"

[ -x /etc/vnc/xstartup ] && exec /etc/vnc/xstartup
[ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources
xsetroot -solid grey
vncconfig -iconic &

gnome-session --builtin --session=gnome-flashback-metacity --disable-acceleration-check --debug &
nautilus &
gnome-terminal &
```



重新启动 VNC

```
vncserver -geometry 1920x1080 :1
vncserver -fp "/usr/share/fonts/X11/misc,/usr/share/fonts/X11/Type1,built-ins" -geometry 1920x1080 :1
```

## 参考资料

- <https://linuxstory.org/how-to-install-and-configure-vnc-on-ubuntu-22-04/>
