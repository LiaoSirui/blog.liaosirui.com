AppArmor 配置（Ubuntu/Debian 系）

```bash
# 查看 AppArmor 状态
sudo aa-status

# 查看特定程序的配置文件
cat /etc/apparmor.d/usr.sbin.nginx

# AppArmor 模式
# enforce - 强制模式
# complain - 投诉模式（只记录不阻止）
# disabled - 禁用

# 切换到投诉模式（调试用）
sudo aa-complain /usr/sbin/nginx

# 切换到强制模式
sudo aa-enforce /usr/sbin/nginx

# 禁用特定配置
sudo aa-disable /usr/sbin/nginx

# 重新加载配置
sudo apparmor_parser -r /etc/apparmor.d/usr.sbin.nginx

# 查看日志
sudo dmesg | grep apparmor
sudo journalctl -k | grep apparmor
```

