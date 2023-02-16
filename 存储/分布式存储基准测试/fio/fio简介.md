顺序读测试 (任务数：1):

```bash
fio --name=sequential-read --directory=${TEST_DIR} --rw=read --refill_buffers --bs=4M --size=4G
```

顺序写测试 (任务数：1):

```bash
fio --name=sequential-write --directory=${TEST_DIR} --rw=write --refill_buffers --bs=4M --size=4G --end_fsync=1
```

顺序读测试 (任务数：16):

```bash
fio --name=big-file-multi-read --directory=${TEST_DIR} --rw=read --refill_buffers --bs=4M --size=4G --numjobs=16
```

顺序写测试 (任务数：16):

```bash
fio --name=big-file-multi-write --directory=${TEST_DIR} --rw=write --refill_buffers --bs=4M --size=4G --numjobs=16 --end_fsync=1
```