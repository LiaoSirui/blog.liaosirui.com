定义好要增加的用户：

```bash
export CUSTOMIZED_USER=srliao \
CUSTOMIZED_GROUP=srliao \
CUSTOMIZED_UID=1801 \
CUSTOMIZED_GID=1801
```

如果要用 sudo 需要安装：

```bash
yum install -y sudo
```

增加用户和组

```bash
groupadd -g ${CUSTOMIZED_GID} ${CUSTOMIZED_GROUP} 

useradd -m -N -s /bin/bash -u ${CUSTOMIZED_UID} -g ${CUSTOMIZED_GROUP} ${CUSTOMIZED_USER} 

echo ${CUSTOMIZED_USER} ALL=\(ALL:ALL\) NOPASSWD: ALL >> /etc/sudoers

echo Defaults        secure_path="/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/nvidia/bin:/usr/local/cuda/bin" >> /etc/sudoers
```

拷贝一些文件：

```bash
mkdir -p /home/${CUSTOMIZED_USER}/.pip
cp /root/.pip/pip.conf /home/${CUSTOMIZED_USER}/.pip/pip.conf

mkdir -p /home/${CUSTOMIZED_USER}/.kube
cp /root/.kube/config /home/${CUSTOMIZED_USER}/.kube/config
```

别忘记把家目录改权限：

```bash
mkdir -p /home/${CUSTOMIZED_USER}
chown -R ${CUSTOMIZED_USER}:${CUSTOMIZED_GROUP} /home/${CUSTOMIZED_USER}
```

修改密码，比较简单的方式的是：

```bash
passwd srliao
```

如果使用非交互模式

```bash
echo "srliao:f" |chpasswd
```
