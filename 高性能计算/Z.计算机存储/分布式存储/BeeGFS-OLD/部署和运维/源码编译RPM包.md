## 获取源码

官方文档：<https://doc.beegfs.io/latest/advanced_topics/building_from_sources.html>

获取源码：

```bash
git clone https://git.beegfs.io/pub/v7 beegfs-v7
```

## RPM 包构建环境准备

### CentOS 7 环境

启动一个虚拟机用于构建，如下：

```bash
virt-builder centos-7.8 \
    --size 20G \
    --output /var/lib/libvirt/images/gitlab-runner-centos7-base.qcow2 \
    --format qcow2 \
    --hostname gitlab-runner-centos7 \
    --root-password password:f
```

阅读 `BUILD.txt`，需要安装如下包：

```bash
yum install -y libuuid-devel \
  libibverbs-devel librdmacm-devel \
  libattr-devel redhat-rpm-config \
  rpm-build xfsprogs-devel zlib-devel ant gcc-c++ gcc \
  redhat-lsb-core java-devel \
  unzip libcurl-devel elfutils-libelf-devel \
  kernel-devel libblkid-devel
```

需要将 gcc 版本升级到高版本，支持 C++14，安装 scl

```bash
yum install -y centos-release-scl

yum install -y devtoolset-7
```

开启 devtoolset-7

```bash
scl enable devtoolset-7 bash
```

构建 RPM 包：

```bash
# 构建
make package-rpm PACKAGE_DIR=packages-rpm

# 并行构建，n 为并行的数量
make package-rpm PACKAGE_DIR=packages-rpm RPMBUILD_OPTS="-D 'MAKE_CONCURRENCY <n>'"

# 自动并行构建
make package-rpm PACKAGE_DIR=packages-rpm RPMBUILD_OPTS="-D \"MAKE_CONCURRENCY $(nproc)\""
```

可以一行 shell 完成使用 devtoolset-7 构建：

```bash
scl enable devtoolset-7 bash << __EOF__
gcc --version
make package-rpm PACKAGE_DIR=packages-rpm RPMBUILD_OPTS="-D \"MAKE_CONCURRENCY $(nproc)\"" > /dev/null
__EOF__
```

注意 centos7 还需要更新下 git 版本

```bash
yum install -y https://repo.ius.io/ius-release-el7.rpm

yum erase -y git*
yum install -y git-core git-lfs
git lfs install --skip-repo
```

### Rocky 9 环境

与 centos7 类似

需要安装的包如下：
```bash
dnf install -y epel-release

dnf groupinstall -y "Development Tools"

rpm -e --nodeps curl
dnf install -y curl-minimal

dnf install -y libuuid-devel \
    libibverbs-devel librdmacm-devel \
    libattr-devel redhat-rpm-config \
    rpm-build xfsprogs-devel zlib-devel ant gcc-c++ gcc \
    java-devel \
    unzip libcurl-devel elfutils-libelf-devel \
    kernel-devel libblkid-devel
```

## 源码编译分析

### Makefile

查看 Makefile，BeeGFS 自己实现了一个简单的 Makefile 工程模板，所有的子模块都使用这一套模板来变异，十分简单高效：

```bash
> make -j$(nproc) -C meta/build help

make: Entering directory '/code/git.beegfs.io/pub/beegfs-v7/meta/build'
Optional arguments:
  BEEGFS_DEBUG=1             Enables debug information and symbols
  BEEGFS_DEBUG_OPT=1         Enables internal debug code, but compiled
                             with optimizations
  CXX=<compiler>             Specifies a c++ compiler
  DISTCC=distcc              Enables the usage of distcc
  V=1                        Print command lines of tool invocations
  BEEGFS_COMMON_PATH=<path>  Path to the common directory
  BEEGFS_THIRDPARTY_PATH=<path>
                             Path to the thirdparty directory

Targets:
  all (default)     build only
  clean             delete compiled files
  help              print this help message
make: Leaving directory '/code/git.beegfs.io/pub/beegfs-v7/meta/build'

```

`meta/build/Makefile` 的 Makefile 内容如下：

```makefile
include ../../build/Makefile

main := ../source/program/Main.cpp
sources := $(filter-out $(main), $(shell find ../source -iname '*.cpp'))

$(call build-static-library,\
   Meta,\
   $(sources),\
   common dl blkid uuid,\
   ../source)

$(call define-dep-lib,\
   Meta,\
   -I ../source,\
   $(build_dir)/libMeta.a)

$(call build-executable,\
   beegfs-meta,\
   $(main),\
   Meta common dl blkid uuid)

$(call build-test,\
   test-runner,\
   $(shell find ../tests -name '*.cpp'),\
   Meta common dl blkid uuid,\
   ../tests)

# enable special reference DirInode debug code
ifneq ($(BEEGFS_DEBUG_RELEASE_DIR),)     # extra release dir debugging
   CXXFLAGS += -DBEEGFS_DEBUG_RELEASE_DIR
endif
```

` build/Makefile` 内容如下：

```makefile
...

define define-dep-lib
$(strip
   $(eval _DEP_LIB_CXX[$(strip $1)] = $(strip $2))
   $(eval _DEP_LIB_LD[$(strip $1)] = $(strip $(or $4, $3)))
   $(eval _DEP_LIB_DEPS[$(strip $1)] = $(strip $3))
   $(eval $(strip $3): ))
endef

...

# build-executable
#
# define a new executable for the build
# arguments:
#  #1: name of the executable
#  #2: sources
#  #3: required libraries
#  #4: include directories
build-executable = $(eval $(call -build-executable-fragment,$(strip $1),$2,$3,$4))
define -build-executable-fragment
all: $1

CLEANUP_FILES += $1 $(addsuffix .o,$2) $(addsuffix .d,$2)

$(addsuffix .o .tidy-%,$2): CXXFLAGS += \
   $(foreach lib,$3,$(call resolve-dep-cflags,$(lib))) $(addprefix -I, $4)

$1: LDFLAGS += \
   -Wl,--start-group $(foreach lib,$3,$(call resolve-dep-ldflags,$(lib))) -Wl,--end-group

$1: $(addsuffix .o,$2) $(foreach lib,$3,$(call resolve-dep-deps,$(lib)))
	@echo "[LD]	$$@"
	$$V$$(CXX) -o $$@ $(addsuffix .o,$2) $$(LDFLAGS)

-include $(addsuffix .d,$2)

$(call make-tidy-rule, $1, $2,\
   $(foreach lib,$3,$(call resolve-dep-cflags,$(lib))) $(addprefix -I, $4))
endef

# build-test
#
# build a test runner from specified test files. acts much like build-executable, except that it
# includes gtest in the build as a non-library .a
#  #1: name if the test executable
#  #2: sources
#  #3: required libraries (not including gtest)
#  #4: included directories (not including gtest)
define build-test
$(call build-executable, $1, $2, $3, $4 -isystem $(GTEST_INC_PATH))

$1: LDFLAGS += $(GTEST_LIB_PATH)/libgtest.a
endef

# build-static-library
#
# define a new (static) library for the build
# arguments:
#  #1: name of the library
#  #2: sources
#  #3: required libraries
#  #4: include directories
build-static-library = $(eval $(call -build-static-library-fragment,lib$(strip $1).a,$2,$3,$4))
define -build-static-library-fragment
all: $1

CLEANUP_FILES += $1 $(addsuffix .o,$2) $(addsuffix .d,$2)

$(addsuffix .o .tidy-%,$2): CXXFLAGS += \
   $(foreach lib,$3,$(call resolve-dep-cflags,$(lib))) $(addprefix -I, $4)

$(build_dir)/$1: $(addsuffix .o,$2)
	@echo "[AR]	$1"
	@rm -f $$@
	$$V$(AR) -rcs $$@ $$^

$1: $(build_dir)/$1

-include $(addsuffix .d,$2)

$(call make-tidy-rule, $1, $2,\
   $(foreach lib,$3,$(call resolve-dep-cflags,$(lib))) $(addprefix -I, $4))
endef

...

```

### RPM 构建脚本

查看构建 `RPM` 包的方法，直接打包源码目录，并使用一个 `RPM SPEC` 文件模板，使用 `sed` 动态生成一个 `SPEC` 文来进行构建：

### RPM 配置

参考资料：<https://blog.csdn.net/chiminlai5815/article/details/100857009>