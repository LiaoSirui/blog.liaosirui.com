
## 通过 pip 安装

注意 pip 21.0 以后不再支持 python2 和 python3.5，需要如下安装

```bash
# To install pip for Python 2.7 install it from https://bootstrap.pypa.io/2.7/ :
curl -O https://bootstrap.pypa.io/pip/2.7/get-pip.py
python get-pip.py
python -m pip install --upgrade "pip < 21.0"
```

pip 安装 ansible（国内如果安装太慢可以直接用pip阿里云加速）

```bash
pip install ansible -i https://mirrors.aliyun.com/pypi/simple/
```

## 简易安装

```bash
yum install epel-release -y

yum install -y ansible
```

默认配置目录在/etc/ansible/，主要有以下两个配置：

- ansible.cfg：ansible 的配置文件
- hosts：配置 ansible 所连接的机器IP信息

## 适合生产环境的宿主机方式

保存 ansible 所需要的所有 rpm 包。

```bash
mkdir -p ~/ansible/repo/rpm

cd ~/ansible/repo/rpm
```

最好启动一个裸 centos 环境来下载包，避免其他包影响，导致缺失

```bash
docker run -it -v $PWD:/test -w /test  --rm centos:7.9.2009 bash
```

在容器中执行

```bash
yum install epel-release -y

yum makecache

yum install --downloadonly --downloaddir=. ansible-2.9.27-1.el7.noarch
```

还可以使用 yum-utils

```bash
yum install yum-utils

yumdownloader ansible-2.9.27-1.el7.noarch
```

查看 ansible 的依赖：

```bash
yum deplist ansible-2.9.27-1.el7.noarch
```

```text
[root@664d762fa045 test1]# yum deplist ansible-2.9.27-1.el7.noarch
Loaded plugins: fastestmirror, ovl
Loading mirror speeds from cached hostfile
 * base: mirrors.aliyun.com
 * epel: mirror.sjtu.edu.cn
 * extras: mirrors.cqu.edu.cn
 * updates: mirrors.aliyun.com
package: ansible.noarch 2.9.27-1.el7
  dependency: /usr/bin/python2
   provider: python.x86_64 2.7.5-90.el7
  dependency: PyYAML
   provider: PyYAML.x86_64 3.10-11.el7
  dependency: python(abi) = 2.7
   provider: python.x86_64 2.7.5-90.el7
  dependency: python-httplib2
   provider: python2-httplib2.noarch 0.18.1-3.el7
   provider: python-httplib2.noarch 0.9.2-1.el7
  dependency: python-jinja2
   provider: python-jinja2.noarch 2.7.2-4.el7
  dependency: python-paramiko
   provider: python-paramiko.noarch 2.1.1-9.el7
  dependency: python-setuptools
   provider: python-setuptools.noarch 0.9.8-7.el7
  dependency: python-six
   provider: python-six.noarch 1.9.0-2.el7
  dependency: python2-cryptography
   provider: python2-cryptography.x86_64 1.7.2-2.el7
  dependency: python2-jmespath
   provider: python2-jmespath.noarch 0.9.4-2.el7
  dependency: sshpass
   provider: sshpass.x86_64 1.06-2.el7
```

对比依赖文件是否正确：

```text
PyYAML-3.10-11.el7.x86_64.rpm                                 python-jinja2-2.7.2-4.el7.noarch.rpm
ansible-2.9.27-1.el7.noarch.rpm                               python-markupsafe-0.11-10.el7.x86_64.rpm
libyaml-0.1.4-11.el7_0.x86_64.rpm                             python-paramiko-2.1.1-9.el7.noarch.rpm
make-3.82-24.el7.x86_64.rpm                                   python-ply-3.4-11.el7.noarch.rpm
openssl-1.0.2k-24.el7_9.x86_64.rpm                            python-pycparser-2.14-1.el7.noarch.rpm
openssl-libs-1.0.2k-24.el7_9.x86_64.rpm                       python-setuptools-0.9.8-7.el7.noarch.rpm
python-babel-0.9.6-8.el7.noarch.rpm                           python-six-1.9.0-2.el7.noarch.rpm
python-backports-1.0-8.el7.x86_64.rpm                         python2-cryptography-1.7.2-2.el7.x86_64.rpm
python-backports-ssl_match_hostname-3.5.0.1-1.el7.noarch.rpm  python2-httplib2-0.18.1-3.el7.noarch.rpm
python-cffi-1.6.0-5.el7.x86_64.rpm                            python2-jmespath-0.9.4-2.el7.noarch.rpm
python-enum34-1.0.4-1.el7.noarch.rpm                          python2-pyasn1-0.1.9-7.el7.noarch.rpm
python-idna-2.4-1.el7.noarch.rpm                              sshpass-1.06-2.el7.x86_64.rpm
python-ipaddress-1.0.16-2.el7.noarch.rpm
```
