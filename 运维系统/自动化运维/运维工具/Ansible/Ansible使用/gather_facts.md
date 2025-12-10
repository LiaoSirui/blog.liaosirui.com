## Gathering Facts

Ansible playbook 默认第一个 task 是 Gathering Facts 收集各主机的 facts 信息，以方便在 paybook 中直接引用 facts 里的信息

Facts 的全部字段查询：<https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_vars_facts.html>

ansible 两个模块叫 setup、gather_facts，用于获取远程主机的相关信息，并可以将这些信息作为变量在 playbook 里进行调用。而 setup 模块获取这些信息的方法就是依赖于 fact

```bash
ansible localhost -m setup
ansible localhost -m gather_facts
```

### 过滤指定的 fact

```bash
ansible localhost -m setup -a 'filter=ansible_eth*’
```

## 自定义 facts

### Local Facts

ansible 除了能获取到预定义的 fact 的内容，还支持手动为某个主机定制 fact。称之为本地 fact。本地 fact 默认存放于被控端的 `/etc/ansible/facts.d` 目录下，如果文件为 `ini` 格式或者 `json` 格式，ansible 会自动识别。以这种形式加载的 fact 是 key 为 `ansible_local` 的特殊变量。

### set_fact

`set_fact` 模块可以自定义 facts，这些自定义的 facts 可以通过 template 或者变量的方式在 playbook 中使用。如果你想要获取一个进程使用的内存的百分比，则必须通过 set_fact 来进行计算之后得出其值，并将其值在 playbook 中引用

```yaml
- name: set_fact example
  hosts: test
  tasks:
    - name: Calculate InnoDB buffer pool size
      set_fact: innodb_buffer_pool_size_mb="{{ ansible_memtotal_mb / 2 |int }}"
      
    - debug: var=innodb_buffer_pool_size_mb

```

## Fact 缓存

如果不需要用到 facts 信息的话，可以设置 `gather_facts: false`，来省去 facts 采集这一步以提高 playbook 效率

```yaml
---

- name: copy to all hosts
  hosts: agents
  become: yes
  gather_facts: False
  roles:
    - upload_passwordfile_to_allhosts

```

如果既想用 facts 信息，又希望能提高 playbook 的效率的话，可以采用 facts 缓存来实现

facts 缓存支持多种方式：

- json 文件方式
- redis 方式
- memcache 方式等

各种方式的配置都是在 ansible.cfg 中配置

### Json 缓存

```ini
gathering=smart
fact_caching_timeout=86400
fact_caching=jsonfile
fact_caching_connection=/tmp/ansible_fact_cache

```

这里的 86400 单位为秒，表示缓存的过期时间。保存 facts 信息的 json 文件保存在 `/ path/to/ansible_fact_cache` 下面，文件名是按照 `inventory hostname` 来命名的。

### Redis 方式

需要注意的是，facts 存储不支持远端的 redis，需要在 ansible 的控制服务器上安装 redis；同时，还需要安装 python 的 redis 模块。

```ini
gathering=smart
fact_caching_timeout=86400
fact_caching=redis

```

### Memcached 方式

与 redis 方式类似，需要运行 memcached 服务，同时，安装 python 的 memcached 依赖包。

```ini
gathering=smart
fact_caching_timeout=86400
fact_caching=memcached

```

