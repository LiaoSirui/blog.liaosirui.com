有严格安全策略的 Kubernetes 集群中，容器经常被分配一个随机的、非 root 的 UID 来运行（例如以 UID 10001 运行）。

很多传统的 Linux 工具（如 `ssh`、`postgres` 等）在启动时，会尝试通过系统 API 查找当前 UID 对应的用户名。如果系统的 `/etc/passwd` 里没有记录这个随机 UID，程序就会报错并拒绝启动

像 PostgreSQL 官方 Docker 镜像 等很多镜像，内部都集成了 `nss_wrapper`。它会在容器启动时动态生成一个包含当前随机 UID 的临时 passwd 文件，并将其注入，让程序顺利识别当前用户并启动。

`nss_wrapper` 利用了 Linux 的 `LD_PRELOAD` 机制。当它被加载到进程中时，它会劫持标准 C 库（glibc）中与名称服务相关的 API（如 `getpwnam`, `getpwuid`, `getgrnam`, `getaddrinfo` 等）。

不想让 `/etc/passwd` 可写：用 nss_wrapper 完成

```bash
cp /etc/passwd /tmp/passwd
echo "user$(id -u):x:$(id -u):$(id -g)::${HOME}:/bin/sh" >> /tmp/passwd

# 1. 启用 nss_wrapper 库
export LD_PRELOAD=libnss_wrapper.so

# 2. 指定你自定义的用户、用户组、主机映射文件
# export NSS_WRAPPER_PASSWD=/path/to/custom_passwd
export NSS_WRAPPER_PASSWD=/tmp/passwd
# export NSS_WRAPPER_GROUP=/path/to/custom_group
export NSS_WRAPPER_GROUP=/etc/group
# export NSS_WRAPPER_HOSTS=/path/to/custom_hosts

# 3. 运行你的应用程序
./myapplication
```

PG init db: <https://github.com/docker-library/postgres/blob/master/19/bookworm/docker-entrypoint.sh#L63-L99>

```bash
# initialize empty PGDATA directory with new database via 'initdb'
# arguments to `initdb` can be passed via POSTGRES_INITDB_ARGS or as arguments to this function
# `initdb` automatically creates the "postgres", "template0", and "template1" dbnames
# this is also where the database user is created, specified by `POSTGRES_USER` env
docker_init_database_dir() {
	# "initdb" is particular about the current user existing in "/etc/passwd", so we use "nss_wrapper" to fake that if necessary
	# see https://github.com/docker-library/postgres/pull/253, https://github.com/docker-library/postgres/issues/359, https://cwrap.org/nss_wrapper.html
	local uid; uid="$(id -u)"
	if ! getent passwd "$uid" &> /dev/null; then
		# see if we can find a suitable "libnss_wrapper.so" (https://salsa.debian.org/sssd-team/nss-wrapper/-/commit/b9925a653a54e24d09d9b498a2d913729f7abb15)
		local wrapper
		for wrapper in {/usr,}/lib{/*,}/libnss_wrapper.so; do
			if [ -s "$wrapper" ]; then
				NSS_WRAPPER_PASSWD="$(mktemp)"
				NSS_WRAPPER_GROUP="$(mktemp)"
				export LD_PRELOAD="$wrapper" NSS_WRAPPER_PASSWD NSS_WRAPPER_GROUP
				local gid; gid="$(id -g)"
				printf 'postgres:x:%s:%s:PostgreSQL:%s:/bin/false\n' "$uid" "$gid" "$PGDATA" > "$NSS_WRAPPER_PASSWD"
				printf 'postgres:x:%s:\n' "$gid" > "$NSS_WRAPPER_GROUP"
				break
			fi
		done
	fi

	if [ -n "${POSTGRES_INITDB_WALDIR:-}" ]; then
		set -- --waldir "$POSTGRES_INITDB_WALDIR" "$@"
	fi

	# --pwfile refuses to handle a properly-empty file (hence the "\n"): https://github.com/docker-library/postgres/issues/1025
	eval 'initdb --username="$POSTGRES_USER" --pwfile=<(printf "%s\n" "$POSTGRES_PASSWORD") '"$POSTGRES_INITDB_ARGS"' "$@"'

	# unset/cleanup "nss_wrapper" bits
	if [[ "${LD_PRELOAD:-}" == */libnss_wrapper.so ]]; then
		rm -f "$NSS_WRAPPER_PASSWD" "$NSS_WRAPPER_GROUP"
		unset LD_PRELOAD NSS_WRAPPER_PASSWD NSS_WRAPPER_GROUP
	fi
}
```

HOME 权限靠构建时的 `chgrp 0` + `chmod g=u` + setgid + `umask 002` 保证；nss_wrapper 只负责让随机 UID 获得用户名和 HOME 路径。

出于安全原因，setuid 二进制文件和具有文件功能的二进制文件都禁用了`LD_PRELOAD`
