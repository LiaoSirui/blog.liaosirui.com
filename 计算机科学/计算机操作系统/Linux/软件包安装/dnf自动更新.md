首先安装 dnf-automatic

```bash
dnf install dnf-automatic

dnf install -y epel-release
dnf install -y crudini
```

自定义参数

```bash
vim /etc/dnf/automatic.conf
```

打开自动安装更新，将以下选项改为 yes

```bash
apply_updates = yes

# crudini --set /etc/dnf/automatic.conf 'commands' 'apply_updates' 'yes'
```

根据个人需要可以调整更新的内容和提示方式

```bash
# 默认安装所有包和安全更新
upgrade_type = default
# crudini --set /etc/dnf/automatic.conf 'commands' 'upgrade_type' 'default'

# 只安装安全更新
upgrade_type = security
# crudini --set /etc/dnf/automatic.conf 'commands' 'upgrade_type' 'security'

# 直接在屏幕输出更新结果
emit_via = stdio
# crudini --set /etc/dnf/automatic.conf 'emitters' 'emit_via' 'stdio'

# 每次登录的时候输出更新结果
emit_via = motd
# crudini --set /etc/dnf/automatic.conf 'emitters' 'emit_via' 'motd'
```

检查和启动

```bash
# 检查是否有语法错误
dnf-automatic

# 启动服务 (每天 6 点会自动执行更新)
systemctl enable --now dnf-automatic.timer
```