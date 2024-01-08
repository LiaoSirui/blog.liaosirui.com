## 修改用户名

使用 `usermod` 来修改用户名。其语法为，

```bash
usermod -l new_username old_username
```

举个例子，假设我们有一个名叫 `dan` 的用户想要重命名为 `susan`，那么在终端下执行下面命令：

```bash
usermod -l susan dan
```

这只会更改用户名，而其他的东西，比如用户组，家目录，UID 等都保持不变。

注意：需要从要改名的帐号中登出并杀掉该用户的所有进程，要杀掉该用户的所有进程可以执行下面命令，

```bash
pkill -u dan

pkill -9 -u dan
```

## 修改家目录

要同时更改家目录，需要在执行 `usermod` 命令的同时加上 `-d` 选项，

```bash
usermod -d /home/susan -m susan
```

## 更改用户UID

执行下面命令修改用户 UID，

```bash
usermod -u 2000 susan
```

## 修改用户组名

要把用户组名从 `dan` 修改为 `susan`，我们需要使用 `groupmod` 命令。使用下面命令来修改用户组名，

```bash
groupmod -n susan dan
```

做完修改后，可以使用 `id` 命令来检查，

```bash
id susan
```

## Hugo UID

- <https://github.com/sagemathinc/cocalc/issues/2287>

过大的 UID 可能造成 `/var/log/lastlog` and `/var/log/faillog` 文件过大
