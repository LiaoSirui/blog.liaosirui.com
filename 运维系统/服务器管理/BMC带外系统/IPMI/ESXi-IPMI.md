## esxcli

查看信息

```bash
esxcli hardware ipmi bmc get
```

设置 IP 信息

## 安装 ipmitool

下载 IPMI Tool

```bash
# 下载
wget https://vswitchzero.com/wp-content/uploads/2019/08/ipmitool-esxi-vib-1.8.11-2.zip
unzip ipmitool-esxi-vib-1.8.11-2.zip

# 安装
esxcli software acceptance set --level=CommunitySupported
esxcli software vib install -v /tmp/ipmitool-1.8.11-2.x86_64.vib
esxcli software vib get -n ipmitool

# 运行
/opt/ipmitool/ipmitool
```

静态编译

```bash
# 使用 Ubuntu 20.04 （编译要求的openssl较低）
apt update
apt install gcc-multilib libc6-i386 libc6-dev-i386 libreadline-dev wget -y

# wget https://github.com/ipmitool/ipmitool/releases/download/IPMITOOL_1_8_18/ipmitool-1.8.18.tar.gz
# tar zxvf ipmitool-1.8.18.tar.gz
wget http://deb.debian.org/debian/pool/main/i/ipmitool/ipmitool_1.8.18.orig.tar.bz2
tar xvf ipmitool_1.8.18.orig.tar.bz2

cd ipmitool-1.8.18
CC=gcc CFLAGS=-m64 LDFLAGS=-static ./configure
make -j

cd src
../libtool --silent --tag=CC --mode=link gcc -m64 -fno-strict-aliasing -Wreturn-type -all-static -o ipmitool.static ipmitool.o ipmishell.o ../lib/libipmitool.la plugins/libintf.la
file $PWD/ipmitool.static

# 关闭安全策略，允许未安装的二进制文件运行
# 如果不禁止，就会提示：-sh: ./ipmitool: Operation not permitted
esxcli system settings advanced set -o /User/execInstalledOnly -i 0
# 开启安全策略，不允许未安装的二进制文件运行
esxcli system settings advanced set -o /User/execInstalledOnly -i 1

```

修改 IP

```bash
# 打印当前 ipmi 地址配置信息
/opt/ipmitool/ipmitool lan print 1

# 设置 id 1 为静态 IP 地址
/opt/ipmitool/ipmitool lan set 1 ipsrc static

# 设置 IPMI 地址
/opt/ipmitool/ipmitool lan set 1 ipaddr 192.168.17.37

# 设置 IPMI 子网掩码
/opt/ipmitool/ipmitool lan set 1 netmask 255.255.255.0

# 设置 IPMI 网关
/opt/ipmitool/ipmitool lan set 1 defgw ipaddr 192.168.17.254
```
