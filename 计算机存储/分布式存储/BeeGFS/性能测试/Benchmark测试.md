

## dd 工具

```bash
mkdir -p /mnt/beegfs/dd-test

dd if=/dev/zero of=/mnt/beegfs/dd-test/test-file bs=1MB count=5000
```

## sysbench 工具

```bash
dnf install -y epel-release
dnf install -y sysbench
mkdir -p /mnt/beegfs/sysbench-test
cd /mnt/beegfs/sysbench-test
sysbench --test=fileio --threads=20 --file-total-size=1G --file-test-mode=rndrw prepare
sysbench --test=fileio --threads=20 --file-total-size=1G --file-test-mode=rndrw run
```

## 网络测试

开启测试模式

```bash
echo 1 > /proc/fs/beegfs/<clientID>/netbench_mode
```

开始测试

关闭测试模式

```bash
echo 0 > /proc/fs/beegfs/<clientID>/netbench_mode
```

## 官方 Benchmark

官方文档：<https://www.beegfs.io/wiki/Benchmark>

## IO500 测试

参考：IO500 测试部分的内容
