## RocksDB

RocksDB 是由 Facebook 数据库工程团队基于 LevelDB 开发和维护的，旨在充分实现快存上存储数据的服务能力。RocksDB 是一个可嵌入的（内嵌式使用不用专门安装部署 RocksDB）、持久型的 key-value 存储代码库，特别适合在闪存驱动器上存储数据，Key 和 value 是任意大小的字节流，支持原子的读和写。RocksDB 采用 LSM 设计，在写放大因子（WAF）、读放大因子（RAF）和空间放大因子（SAF）之间进行了灵活的权衡。RocksDB 支持多线程压缩，特别适合在单个数据库中存储 TB 级别的数据

RocksDB 支持在不同的生产环境（纯内存、Flash、hard disks or HDFS）中调优，RocksDB 针对多核 CPU、高效快速存储（SSD)、I/O boundworkload 做了优化，支持不同的数据压缩算法、和生产环境 debug 的完善工具

- 官网：<https://rocksdb.org/>

- GitHub 仓库：<https://github.com/facebook/rocksdb>

- Release：<https://github.com/facebook/rocksdb/releases>

- 安装指引：<https://github.com/facebook/rocksdb/blob/main/INSTALL.md>

## 源码编译安装

```dockerfile
RUN --mount=type=cache,target=/var/cache,id=centos-compile-cache \
    --mount=type=cache,target=/tmp,id=centos-compile-tmp \
    --mount=type=bind,from=packages_passer,source=/packages,target=/packages,rw \
    \
    echo "CACHEKEY=2022-01-12-01 -> just to force it rebuild" \
    \
    # using set -x for debug, set -e to ensure that each command execution is successful
    && set -ex \
    \
    # update packages
    && yum clean metadata \
    && yum makecache \
    && yum update --exclude=centos-release* --skip-broken -y \
    \
    # check rocksdb source package
    && mkdir -p /opt/bigquant/rocksdb/ \
    && yum install -y unzip \
    && unzip /packages/rocksdb-8.1.1.zip -d /opt/bigquant/rocksdb/ \
    \
    && yum install -y snappy snappy-devel \
    zlib zlib-devel \
    bzip2 bzip2-devel \
    lz4-devel \
    libasan \
    libzstd-devel \
    cmake \
    \
    && cd /opt/bigquant/rocksdb/rocksdb-8.1.1 \
    # && make shared_lib -j$(nproc) >/dev/null \
    && make shared_lib -j2 >/dev/null \
    # && make install-shared INSTALL_PATH=/usr \
    # && pip3 install rocksdb-python \
    \
    && gcc --version \
    && g++ --version
```

