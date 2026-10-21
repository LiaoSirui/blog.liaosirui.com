具有 `CAP_SYS_RESOURCE` 或者 `CAP_SYS_ADMIN` 的进程不受 nproc 限制

源码 <https://github.com/torvalds/linux/blob/v4.19/kernel/fork.c#L1732-L1737>

```c
	if (atomic_read(&p->real_cred->user->processes) >=
			task_rlimit(p, RLIMIT_NPROC)) {
		if (p->real_cred->user != INIT_USER &&
		    !capable(CAP_SYS_RESOURCE) && !capable(CAP_SYS_ADMIN))
			goto bad_fork_free;
	}
```

源码 <https://github.com/torvalds/linux/blob/v4.19/kernel/fork.c#L2095-L2098>