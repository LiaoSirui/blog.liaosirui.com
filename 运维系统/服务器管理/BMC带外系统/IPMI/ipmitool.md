## IPMItool

IPMItool 用于访问 IPMI 的功能 - 智能平台管理接口，该系统接口管理和监视带外计算机系统。它是一个命令提示符，用于控制和配置 IPMI 支持的设备。

IPMItool 是一种可用在 linux 系统下的命令行方式的 ipmi 平台管理工具，它支持 ipmi 1.5 规范（最新的规范为 ipmi 2.0）.IPMI 是一个开放的标准，监控，记录，回收，库存和硬件实现独立于主 CPU，BIOS，以及操作系统的控制权。 服务处理器（或底板管理控制器，BMC）的背后是平台管理的大脑，其主要目的是处理自主传感器监控和事件记录功能。

## IPMItool 常用命令

### 电源控制

```bash
# 查看开关机状态
ipmitool power status

# 开机
ipmitool power on

# 关机
ipmitool power off

# 重启
ipmitool power reset

# 注意 power cycle 和 power reset 的区别在于前者从掉电到上电有１秒钟的间隔，而后者是很快上电)
ipmitool power cycle
```

### 读取系统状态类

#### Sensor 信息查看

```bash
# 查看 SDR Sensor 信息
ipmitool sdr

# 查看 Sensor 信息
ipmitool sensor list
```

#### SEL 日志查看

```bash
# 显示所有系统事件日志
ipmitool sel list

# 删除所有系统日志
ipmitool sel clear

# 查看当前 BMC 时间
ipmitool sel time get
# 设置当前 BMC 的时间
ipmitool sel time set  "mm/dd/yyyy hh:mm:ss"
```

### 启动类

```bash
# 重启后停在 BIOS 菜单
ipmitool chassis bootdev bios

# 重启后从 PXE 启动
ipmitool chassis bootdev pxe
```

## IPMItool 使用

### channel 参数

```bash
ipmitool channel info
```

- channel setaccess：这是 ipmitool 中的一个命令，用于设置 IPMI 通道的访问权限。
- 1：表示要设置的通道号，这个命令中是通道号为 1。
- 5：表示要设置的用户 ID，这个命令中是用户 ID 为 5。
- `callin=off`：表示禁止该通道的用户通过 IPMI 远程呼叫进行访问。
- `ipmi=on`：表示允许该通道的用户通过 IPMI 进行访问。
- `privilege=4`：表示设置用户的权限等级为 4，即操作员级别权限。

### 修改 IP

```bash
# 打印当前 ipmi 地址配置信息
ipmitool lan print 1

# 设置 id 1 为静态 IP 地址
ipmitool lan set 1 ipsrc static

# 设置 IPMI 地址
ipmitool lan set 1 ipaddr 192.168.17.253

# 设置 IPMI 子网掩码
ipmitool lan set 1 netmask 255.255.255.0

# 设置 IPMI 网关
ipmitool lan set 1 defgw ipaddr 192.168.17.254
```

### 修改账号

```bash
# 显示 IPMI 用户列表
ipmitool user list

# 创建用户，一般服务器有默认的超级用户（root,admin,ADMIN）
ipmitool user set name 3 root

# 创建密码
ipmitool user set password 3 calvin

# 设置权限
# ipmitool channel setaccess 1 用户ID
ipmitool channel setaccess 1 3 callin=on ipi=on link=on privilege=4

# 查看 chanenel 1 的用户信息
ipmitool user list 1

# 可以直接修改超级用户的密码，不用重新创建
# 修改用户 id 1 的密码 为 abc-123
ipmitool user set password 1 abc-123
```

## 参考文档

- <https://www.cnblogs.com/HByang/p/16127044.html>
- <https://cloud.tencent.com/developer/article/2422636>

- <https://www.cnblogs.com/zhangxinglong/p/5012441.html>
