## 运行在旧版本 glibc 的机器上

建议使用 patchelf `>=v0.18.x`

在远程主机上安装 patchelf 二进制文件和 sysroot <https://github.com/NixOS/patchelf>

创建以下 3 个环境变量：

- `VSCODE_SERVER_CUSTOM_GLIBC_LINKER`：sysroot 中动态链接器的路径（与 patchelf 的 `--set-interpreter` 选项一起使用）
- `VSCODE_SERVER_CUSTOM_GLIBC_PATH`：sysroot 中库位置的路径（与 patchelf 的 `--set-rpath` 选项一起使用）
- `VSCODE_SERVER_PATCHELF_PATH`：远程主机上 patchelf 二进制文件的路径

（1）下载 crosstool-NG 源码

从 [crosstool-ng.org](http://crosstool-ng.org/download/crosstool-ng/) 下载 crosstool-NG 源码，编译安装

```bash
wget http://crosstool-ng.org/download/crosstool-ng/crosstool-ng-1.27.0.tar.xz
tar -xJf crosstool-ng-*.tar.xz && rm crosstool-ng-*.tar.xz
cd crosstool-ng*

mkdir build && cd build
../configure --prefix="$HOME/.local"
make -j$(nproc)
make install
export PATH="$HOME/.local/bin:$PATH"
```

亦可考虑使用容器构建

```bash
FROM ubuntu:latest

RUN apt-get update && \
    apt-get install -y gcc g++ gperf bison flex texinfo help2man make libncurses5-dev \
            python3-dev autoconf automake libtool libtool-bin gawk wget bzip2 xz-utils \
            unzip patch rsync meson ninja-build && \
    apt-get clean
RUN wget http://crosstool-ng.org/download/crosstool-ng/crosstool-ng-1.27.0.tar.xz && \
    tar -xJf crosstool-ng-*.tar.xz && \
    rm crosstool-ng-*.tar.xz && \
    cd crosstool-ng-* && \
    ./configure --prefix=/opt/crosstool-ng && \
    make && \
    make install && \
    rm -rf crosstool-ng-*
RUN useradd ct-ng && \
    mkdir /toolchain && \
    chown ct-ng:ct-ng /toolchain
ENV PATH=/opt/crosstool-ng/bin:$PATH
USER ct-ng
WORKDIR /toolchain
```

（2）生成 sysroot

以下是一些可以作为起点的示例配置：

- [x86_64-gcc-8.5.0-glibc-2.28](https://github.com/microsoft/vscode-linux-build-agent/blob/main/x86_64-gcc-8.5.0-glibc-2.28.config)
- [aarch64-gcc-8.5.0-glibc-2.28](https://github.com/microsoft/vscode-linux-build-agent/blob/main/aarch64-gcc-8.5.0-glibc-2.28.config)
- [armhf-gcc-8.5.0-glibc-2.28](https://github.com/microsoft/vscode-linux-build-agent/blob/main/armhf-gcc-8.5.0-glibc-2.28.config)

```bash
mkdir toolchain && cd toolchain
wget -O .config https://raw.githubusercontent.com/microsoft/vscode-linux-build-agent/refs/heads/main/x86_64-gcc-10.5.0-glibc-2.28.config
unset LD_LIBRARY_PATH CPATH  # 清理环境变量
ct-ng build
```

配置文件来自 [vscode-linux-build-agent | GitHub](https://github.com/microsoft/vscode-linux-build-agent)

（3）安装 patchelf

```bash
wget https://github.com/NixOS/patchelf/releases/download/0.18.0/patchelf-0.18.0-x86_64.tar.gz
tar -xzf patchelf-*-x86_64.tar.gz -C ~/.local
rm patchelf-*-x86_64.tar.gz
```

（4）替换 glibc

将构建产物 `x86_64-linux-gnu` 上传到 CentOS 7 的 `~/.local/opt` 目录

```bash
rsync -aP x86_64-linux-gnu HOST:.local/opt/
```

将下面的内容加入 `~/.bashrc`

```bash
export VSCODE_SERVER_CUSTOM_GLIBC_LINKER="$HOME/.local/opt/x86_64-linux-gnu/x86_64-linux-gnu/sysroot/lib/ld-2.28.so"
export VSCODE_SERVER_CUSTOM_GLIBC_PATH="$HOME/.local/opt/x86_64-linux-gnu/x86_64-linux-gnu/sysroot/lib"
export VSCODE_SERVER_PATCHELF_PATH="$HOME/.local/bin/patchelf"
```

实际上作用的是如下脚本的位置 <https://github.com/microsoft/vscode/blob/1.101.2/resources/server/bin/code-server-linux.sh>

