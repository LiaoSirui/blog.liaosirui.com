## 环境准备

基于 rocky linux 进行开发

```bash
> cat /etc/os-release

NAME="Rocky Linux"
VERSION="8.6 (Green Obsidian)"
ID="rocky"
ID_LIKE="rhel centos fedora"
VERSION_ID="8.6"
PLATFORM_ID="platform:el8"
PRETTY_NAME="Rocky Linux 8.6 (Green Obsidian)"
ANSI_COLOR="0;32"
CPE_NAME="cpe:/o:rocky:rocky:8:GA"
HOME_URL="https://rockylinux.org/"
BUG_REPORT_URL="https://bugs.rockylinux.org/"
ROCKY_SUPPORT_PRODUCT="Rocky Linux"
ROCKY_SUPPORT_PRODUCT_VERSION="8"
REDHAT_SUPPORT_PRODUCT="Rocky Linux"
REDHAT_SUPPORT_PRODUCT_VERSION="8"
```

## 工具依赖列表

官方文档地址：<https://github.com/coder/code-server/blob/v4.8.3/docs/CONTRIBUTING.md#requirements>

- node v16.x
- git v2.x or greater
- git-lfs
- yarn: Used to install JS packages and run scripts（用于安装 JS 包和运行脚本）
- nfpm: Used to build .deb and .rpm packages（用于构建 deb 和 rpm 包）
- jq:  Used to build code-server releases（用于发布）
- gnupg: All commits must be signed and verified; see GitHub's Managing commit signature verification or follow this tutorial
- quilt: Used to manage patches to Code（用于管理代码补丁）
- rsync and unzip: Used for code-server releases（用于发布）
- bats: Used to run script unit tests

vscode 需要的依赖，官方文档地址：<https://github.com/microsoft/vscode/wiki/How-to-Contribute#prerequisites>

需要安装：

- `dnf groupinstall "Development Tools"`
- `dnf install --enablerepo=powertools libX11-devel.x86_64 libxkbfile-devel.x86_64 libsecret-devel` 
  - 开启 PowerTools 仓库：`dnf install dnf-plugins-core && dnf install epel-release && dnf config-manager --set-enabled powertools`

### node 使用 nvm 进行管理

```bash
nvm install "${DEV_NODEJS_VERSION:-v16.18.1}"

nvm use "${DEV_NODEJS_VERSION:-v16.18.1}"
```

### quilt 安装

```bash
dnf install -y quilt
```

### yarn

```bash
npm install -g yarn
```

### jq

```bash
dnf install -y jq
```

### ripgrep

```bash
dnf install -y ripgrep
```

## 开发环境

开启 git 代理（也可以使用系统代理）

```bash
git config --global http.https://github.com.proxy socks5://10.244.244.103:8899
git config --global https.https://github.com.proxy socks5://10.244.244.103:8899
git config --global http.https://github.com.sslVerify false
git config --global https.https://github.com.sslVerify false

# 如果需要关闭，执行：
git config --global --unset http.https://github.com.proxy
git config --global --unset https.https://github.com.proxy
git config --global --unset http.https://github.com.sslVerify
git config --global --unset https.https://github.com.sslVerify
```

拉取仓库

```bash
git clone https://github.com/coder/code-server.git
```

切换到一个稳定分支进行

```bash
# alias gco='git checkout'
gco v4.8.3
```

更新子模块

```bash
git submodule update --init
```

把 patch 包全部应用

```bash
quilt push -a
```

安装依赖

```bash
yarn
```

启动应用

```bash
yarn watch
```
