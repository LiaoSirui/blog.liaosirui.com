## MDTest 简介

MDTest 是一个测试文件系统元数据性能的工具，被设计用于测试文件系统的元数据性能并生成测试报告。

官方：

- 原 GitHub 仓库：<https://github.com/MDTEST-LANL/mdtest/tree/master/old>
- 合并至 ior：<https://github.com/hpc/ior>

mdtest 工具已经变成了 ior 工具的一部分了。

```plain
On October 23, 2017, mdtest was merged into IOR. Accordingly, this repo is now deprecated. If for some reason, you want the old version that was here before the merge, it is available in the ./old subdirectory.
```

## 参数

MDTest 参数说明

| 参数 | 说明                              |
| ---- | --------------------------------- |
| -F   | 只创建文件                        |
| -L   | 只在目录树的子目录层创建文件/目录 |
| -z   | 目录树深度                        |
| -b   | 目录树的分支数                    |
| -I   | 每个树节点包含的项目数            |
| -u   | 为每个工作任务指定工作目录        |
| -d   | 指出测试运行的目录                |

## 测试

单个客户端单个进程

```bash
./mdtest -F -L -z 4 -b 2 -I 1562 -u -d /mnt/fs1/mdtest/
```

单个客户端 4 个进程

```bash
mpirun --allow-run-as-root -np 4 ./mdtest -F -L -z 4 -b 2 -I 1562 -u \
  -d /mnt/fs1/mdtest1/@/mnt/fs2/mdtest2@/mnt/fs3/mdtest3@/mnt/fs4/mdtest4
```

5 个客户端 4 个进程

```bash
mpirun --allow-run-as-root --mca plm_rsh_no_tree_spawn 1 -npernode 4 -hostfile /root/test/hosts ./mdtest -F -L -z 4 -b 2 -I 1562 -u \
 -d /mnt/fs1/mdtest1/@/mnt/fs2/mdtest2@/mnt/fs3/mdtest3@/mnt/fs4/mdtest4@/mnt/fs1/mdtest5/@/mnt/fs2/mdtest6@/mnt/fs3/mdtest7@/mnt/fs4/mdtest8@/mnt/fs1/mdtest9/@/mnt/fs2/mdtest10@/mnt/fs3/mdtest11@/mnt/fs4/mdtest12@/mnt/fs1/mdtest13/@/mnt/fs2/mdtest14@/mnt/fs3/mdtest15@/mnt/fs4/mdtest16@/mnt/fs1/mdtest17/@/mnt/fs2/mdtest18@/mnt/fs3/mdtest19@/mnt/fs4/mdtest20
```

