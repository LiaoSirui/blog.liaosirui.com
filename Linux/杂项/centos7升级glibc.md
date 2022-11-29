升级 make 和 glibc，Dockerfile 对应部分如下：

```dockerfile
RUN --mount=type=cache,target=/var/cache,id=cache \
    --mount=type=cache,target=/tmp,id=tmp \
    \
    # update make
    cd $(mktemp -d) \
    && curl -sL https://mirrors.aliyun.com/gnu/make/make-4.3.tar.gz -o make-4.3.tar.gz  \
    && tar -zxf make-4.3.tar.gz \
    && cd make-4.3/ \
    && mkdir build && cd build \
    && ../configure --prefix=/usr > /dev/null \
    && make > /dev/null && make install > /dev/null \
    \
    # update libc
    && /lib64/libc.so.6 \
    && cd $(mktemp -d) \
    && curl -sL https://mirrors.aliyun.com/gnu/glibc/glibc-2.28.tar.gz -o glibc-2.28.tar.gz \
    && tar -zxf glibc-2.28.tar.gz \
    && cd glibc-2.28/ \
    && cat INSTALL | grep -E "newer|later" \
    # add '   && $name ne "nss_test2"' after line 127
    && sed -i '127a    && $name ne "nss_test2"' scripts/test-installation.pl \
    # add 'libnsl-routines += nss-default' after line 71
    && sed -i '71alibnsl-routines += nss-default' nis/Makefile \
    && mkdir build && cd build \
    && ../configure --prefix=/usr --disable-profile --enable-add-ons --with-headers=/usr/include \
    --with-binutils=/usr/bin --disable-sanity-checks --disable-werror --enable-obsolete-nsl > /dev/null \
    && make -j4 > /dev/null && make install > /dev/null 

```

参考资料：

- <https://cloud.tencent.com/developer/article/1669876>
- <https://garlicspace.com/2020/07/18/centos7-%E5%8D%87%E7%BA%A7-glibc-gcc/#nss_test2>