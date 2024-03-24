## IOR 简介

IOR 设计用于测量 POSIX 和 MPI-IO 级别的并行文件系统的 I/O 的性能

IOR 使用 MPI 进行进程同步（也可以使用 srun 或其他工具） - 通常在 HPC（High Performance Computing）集群中的多个节点上并行运行 IOR 进程，在安装目标文件系统的每个客户机节点上运行一个 IOR 进程。

官方：

- GitHub 仓库：<https://github.com/hpc/ior>
- 文档：<https://ior.readthedocs.io/en/latest/>

## 构建

安装依赖程序

```bash
dnf install -y gcc gcc-c++ gcc-gfortran
```

安装 openmpi，最新版本可查询：<https://www.open-mpi.org/software/> 或者 <https://github.com/open-mpi/ompi>，Rocky9 源中已自带

```bash
dnf install -y openmpi openmpi-devel
```

修改 `/etc/profile` 或者 `${USER}/.bash_profile`，追加如下内容：

```bash
if [ -z "$OPENMPI_ADDED" ]; then
    export PATH=/usr/lib64/openmpi/bin${PATH:+:${PATH}}
    export OPENMPI_ADDED=yes
    export LD_LIBRARY_PATH=/usr/lib64/openmpi/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
    export MPI_CC=mpicc
fi

```

下载 ior 源码后进行编译安装：

```bash
./configure

make 

make install
```

## 测试

单个客户端单个进程

```ini
# ior-conf-11
===============> start script <===============

IOR START

  api=POSIX

  hintsFileName=hintsFile

  testFile=/mnt/fs1/iortest/f11-1

  repetitions=1

  readFile=1

  writeFile=1

  filePerProc=1

  segmentCount=1

  blockSize=128g

  transferSize=1024k

  collective=0

IOR STOP

===============> stop script <===============
```

单个客户端 4 个进程

```ini
# ior-conf-14
===============> start script <===============

IOR START

  api=POSIX

  hintsFileName=hintsFile

  testFile=/mnt/fs1/iortest/f14-1@/mnt/fs2/iortest/f14-2@/mnt/fs3/iortest/f14-3@/mnt/fs4/iortest/f14-4

  repetitions=1

  readFile=1

  writeFile=1

  filePerProc=1

  segmentCount=1

  blockSize=32g

  transferSize=1024k

  collective=0

IOR STOP

===============> stop script <===============
```

5 个客户端 4 个进程

```bash
===============> start script <===============

IOR START

  api=POSIX

  hintsFileName=hintsFile

  testFile=/mnt/fs1/iortest/f54-1@/mnt/fs2/iortest/f54-2@/mnt/fs3/iortest/f54-3@/mnt/fs4/iortest/f54-4@/mnt/fs1/iortest/f54-5@/mnt/fs2/iortest/f54-6@/mnt/fs3/iortest/f54-7@/mnt/fs4/iortest/f54-8@/mnt/fs1/iortest/f54-9@/mnt/fs2/iortest/f54-10@/mnt/fs3/iortest/f54-11@/mnt/fs4/iortest/f54-12@/mnt/fs1/iortest/f54-13@/mnt/fs2/iortest/f54-14@/mnt/fs3/iortest/f54-15@/mnt/fs4/iortest/f54-16@/mnt/fs1/iortest/f54-17@/mnt/fs2/iortest/f54-18@/mnt/fs3/iortest/f54-19@/mnt/fs4/iortest/f54-20

  repetitions=1

  readFile=1

  writeFile=1

  filePerProc=1

  segmentCount=1

  blockSize=32g

  transferSize=1024k

  collective=0

IOR STOP

===============> stop script <===============
```

注：进行多个客户端测试时，需要在每个节点的对应目录下都上传测试脚本，测试命令中的 hosts 文件内容如下：

```bash
# hosts
test1 slots=4
test2 slots=4
test3 slots=4
test4 slots=4
test5 slots=4
```

