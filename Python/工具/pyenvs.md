## 安装

### 依赖

```bash
dnf install -y \
	gcc make patch \
	gdbm-devel \
	openssl-devel \
	sqlite-devel \
	readline-devel \
	zlib-devel \
	bzip2-devel \
	ncurses-devel \
	libffi-devel
```

### 离线安装

下载最新版本

```bash
curl -sL https://github.com/pyenv/pyenv/archive/refs/tags/v2.3.6.tar.gz -o pyenv-v2.3.6.tar.gz
```

解压至家目录

```bash
tar -zxvf pyenv-v2.3.6.tar.gz && mv pyenv-2.3.6 .pyenv
```

新建 cache 目录

```bash
mkdir .pyenv/cache
```

环境变量设置如下：

```bash
cat >> ~/.bashrc <<'EOF'
### pyenv ###
export PYENV_ROOT="$HOME/.pyenv" 
export PATH="$PYENV_ROOT/bin:$PATH"
export PATH="$PYENV_ROOT/shims:$PATH"
eval "$(pyenv init -)"
EOF

source ~/.bashrc

pyenv --version
# pyenv 2.3.6
```

查询可安装的Python版本

```bash
pyenv install --list
```

安装 Python 版本

```
pyenv install -v 3.9.15
```

查看已经安装的版本

```bash
> pyenv versions

  3.8.15
  3.9.15
```

`pyenv local `指定文件夹 Python 版本

```
pyenv local 3.9.15
```

## 虚拟环境

pyenv-virtualenv-1.1.5

```bash
curl -sL https://github.com/pyenv/pyenv-virtualenv/archive/refs/tags/v1.1.5.tar.gz -o pyenv-virtualenv-v1.1.5.tar.gz 

tar -zxvf pyenv-virtualenv-v1.1.5.tar.gz && mv pyenv-virtualenv-1.1.5 .pyenv/plugins/pyenv-virtualenv

echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.bashrc
```

创建项目环境

```bash
pyenv virtualenv 3.9.7 telnet_switch
```

切换虚拟环境

```bash
 pyenv local telnet_switch
(telnet_switch) [root@Python telnet_switch]# 
```

查看当前虚拟环境

```bash
pyenv virtualenvs

  3.9.15/envs/telnet_switch (created from /root/.pyenv/versions/3.9.15)
* telnet_switch (created from /root/.pyenv/versions/3.9.15)
```

删除当前环境

```bash
pyenv uninstall telnet_switch 
```
