## Ansible 模块

- synchronize，copy，unarchive 都可以上传文件
- ping：检查指定节点机器是否还能连通。主机如果在线，则回复 pong
- dnf, apt：这两个模块都是在远程系统上安装包的
- pip：远程机器上 python 安装包
- user，group：用户管理
- systemd：管理服务

## ad-hoc

ad-hoc 是指临时命令，是在输入内容后，快速执行某些操作，但不希望保存下来的命令。

一般来说，Ansible 主要在于我们后面会学到的 Playbook 的脚本编写，但是，ad-hoc 相较来说，它的优势在于当你收到一个临时任务时，你只用快速简单地执行一个 ad-hoc 临时命令，而不用去编写一个完整的 Playbook 脚本。

Ansible 的 ad-hoc 的一般用法

```bash
ansible 主机名或组名 -m 模块名 -a [模块参数] 其他参数
```

ad-hoc 返回类型：

- success：这个结果表示操作成功，其中有两种情况，第一种情况是当执行一些查询的简单操作并且不需要修改内容时，表示该操作没问题；第二种情况就是当这个操作曾经执行过再执行时就会直接表示成功。
- changed： 这样的结果表示执行的一些修改操作执行成功，如上文的创建了一个文件，或者修改了配置文件，复制了一个文件等等这类的操作就会有这样的结果。
- failed：这样的结果表示这个操作执行失败，可能是密码错误，参数错误等等，具体看提示中的 msg 的值。并且在 Playbook 中会有多个任务，中间的某个任务出现这样的情况都不会继续往下执行。

## 常用模块

### ping 模块

```bash
# 对所有机器执行命令
ansible -i inventory.py all -m ping
```

得到输出

```json
10.24.8.1 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    }, 
    "changed": false, 
    "ping": "pong"
}
```

### setup 模块

执行命令查看 setup 模块中所有我们需要操作的机器的信息。

```bash
ansible -i inventory.py all -m setup
```

### file 模块

执行如下命令让 test 组中的主机在指定目录下创建文件夹，并设置权限。

```bash
ansible -i inventory.py all -m file -a "dest=/root/test_ansible state=directory mode=777" 
```

得到输出：

```json
10.24.8.1 | CHANGED => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    }, 
    "changed": true, 
    "gid": 0, 
    "group": "root", 
    "mode": "0777", 
    "owner": "root", 
    "path": "/root/test_ansible", 
    "size": 6, 
    "state": "directory", 
    "uid": 0
}
```

执行如下命令让 test 组中的主机在指定目录下创建文件，并设置权限。

```bash
ansible -i inventory.py all -m file -a "dest=/root/test_ansible/file state=touch mode=777"
```

得到输出

```json
10.24.8.1 | CHANGED => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    }, 
    "changed": true, 
    "dest": "/root/test_ansible/file", 
    "gid": 0, 
    "group": "root", 
    "mode": "0777", 
    "owner": "root", 
    "size": 0, 
    "state": "file", 
    "uid": 0
}
```

### shell 模块

对于使用 shell 操作在 Ansible 中没有相应的模块支持的操作时，我们可以尝试的解决办法是直接使用 shell 模块来执行命令即可

```bash
ansible -i inventory.py all -m shell -a "ls -alh /root/test_ansible | grep file"
```

得到输出：

```text
10.24.8.1 | CHANGED | rc=0 >>
-rwxrwxrwx   1 root root    0 Mar 13 15:08 file
```

### command 模块

Ansible 还可以不指定任何模块，例如执行下面的命令，让操作的机器输出 Hello Ansible。

```bash
ansible -i inventory.py all -a "/bin/echo Hello Ansible"
```

实际上这默认使用了模块 command，因此上面的命令等效于：

```bash
ansible -i inventory.py all -m command -a "/bin/echo Hello Ansible"
```

command 模块和 shell 模块的功能十分接近。shell 模块可以看作 command 模块的加强版本，比 command 模块支持更多的功能特性，如前面例子中的管道。

### synchronize 模块

| 场景类型         | 推荐参数组合                                  |
| ---------------- | --------------------------------------------- |
| 完整目录备份     | `archive: yes, delete: yes`                   |
| 增量日志收集     | `mode: pull, existing_only: yes`              |
| 安全敏感文件传输 | `compress: yes, rsync_path: "/usr/bin/rsync"` |

推送本地文件到远程主机

```yaml
- hosts: web
  tasks:
    - name: Push local script to remote
      synchronize:
        src: /tmp/time.sh
        dest: /usr/local/bin/
        mode: push
```

从远程主机拉取日志

```yaml
- hosts: web
  tasks:
    - name: Pull remote logs to local
      synchronize:
        src: /var/log/nginx/
        dest: /backup/logs/
        mode: pull
        delete: yes  # 清理本地多余文件
```

排除特定文件类型

```yaml
- hosts: web
  tasks:
    - name: Sync with file exclusion
      synchronize:
        src: /data/
        dest: /backup/
        rsync_opts: "--exclude=.log --exclude=*.tmp"
```
