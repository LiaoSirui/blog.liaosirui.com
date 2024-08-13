## playbook

用 AD-HOC 临时命令来快速执行任务，但是 Ansible 真正的重点在于 Playbook 的编写，因为在自动化运维中批量进行系统配置和部署服务才是自动化的核心用

### Playbook 介绍

Playbook 是一种非常简单的配置管理系统以及是多机器部署系统的基础，十分适合复杂的应用部署。同时，Playbook 还可以用于声明配置，以及编排有序的执行过程，使得在多组机器之间有序的执行指定步骤，或者同步或异步地发起任务。

Playbook 也是一个任务列表，这个列表中的可以包含一个或者多个 plays，所有的操作放在这么一个文件中，然后一次性地执行。而它与 AD-HOC 最大的不同之处就在于它是把这些任务放在源码中进行控制。

对于 Ansible 来说，几乎每个 YAML 文件都以一个列表开始。列表中的每个项都是 key: value （键值对）的列表，通常称为 Hash 或 Dictionary。

- 文件均以 `---` 作为开始，以 `...` 结束。
- 列表中同级别的项使用相同缩进以及短横线加空格（-）开始。
- 字典（dictionary）用 key: value 的简单形式表示，其中冒号后面必须有个空格。value 部分可以用几种形式（yes/no/true/false）来指定布尔值。
- 换行符：value 部分还可以使用 `|` 或 `>`，使用 `|` 可以将内容进行分行处理，而使用 `>` 将忽略换行符，任何情况下缩进都会被忽略。
- 语句过长可以使用 `""` 括起来，例如：`foo: "somebody said I should put a colon here: so I did"`。

### Playbook 语法结构

Playbook 是由一个或多个 plays 组成，也就是它的内容是以 plays 为元素的列表。Plays 的内容也被称为 tasks（任务），执行一个任务就是对模块的调用。

```yaml
---
- hosts: host1,host2
  remote_user: root
  become: yes
  vars:
    http_port: 80
  tasks:
    - name: Install the package "bc"
      apt:
        name: bc
        state: present
  handlers:
  - name: restart bc
      service:
        name: bc
        state: restarted
...
```

#### 主机、用户、权限

`hosts` 参数表示一个或多个主机或组，多个时用逗号或冒号分隔，用 all 或 * 表示所有的主机。在示例中，hosts 参数指定了两台主机 host1 和 host2。

`remote_user` 表示用户名，参数可以是普通用户，也可以是 root 等超级用户。

`become` 是 Ansible 最新的权限提升关键词，取代了原来 sudo 和 sudo_user 等权限管理相关的关键词。become: yes 表示允许权限提升，而默认提权用户为 root，所以在上面的例子中，下面的任务将以 root 用户的身份执行。

如果不希望以 root 身份执行任务，则要用到另一个关键词 `become_user`。如 become_user: admin 指定使用 admin 身份执行任务。注意在使用 become_user 前必须先使用 become: yes 或 become: true 允许权限升级操作。

注意 remote_user 和 become_user 之间的区别，remote_user 决定的是连接远程主机的用户身份，become_user 决定的是执行任务的用户身份。因此为了安全考虑，在实践中 remote_user 常设置为普通用户进行 SSH 连接，执行任务时再使用 become 和 become_user 进行权限升级，进而以更高的权限执行任务。

#### vars（变量）

在任务行中可以使用变量来定义，像这样 "`{{ item }}`" 括起来。

将变量独立出来，可以方便后期的修改和维护等，也可以在其他任务中使用。

变量的定义可以放在如下几处：

1. Inventory 中；
2. 全局中（var:）或者某个任务（task）中，在上面的例子中，定义了一个全局的变量 http_port，且该变量的值为 80；
3. 在 roles 结构中用于存放单独的文件；
4. 在 registered 模块中注册变量，主要用于调试和判断。

变量的高级用法：<https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html#advanced-syntax>

#### tasks（任务）

在运行 Playbook 时是从上到下依次执行，并且一个 task 在其对应的所有主机上执行完毕之后才会执行下一个 task。

如果一个 host 执行 task 失败，那么这个 host 将会从整个 Playbook 的 rotation 中移除。如果发生执行失败的情况，需要修正 playbook 中的错误，然后再重新执行。

每一个 task 必须有一个 name，这样在输出任务时才可以清楚地辨别出属于哪个任务，若没有定义将会被特定标记。在上面的例子中，设置了一个名为 Install the package "bc" 的任务，从任务名可看出该任务用于安装名为 “bc” 的软件包。往后继续观察，可见该任务使用了 apt 模块，该模块用于管理 ubuntu 等系统下的 apt 包，具体的使用会在后续学习中使用。从例子可见 task 的 name 应当与具体的任务内容相关联，便于理解和区分各个任务的目标，也方便后续的调整和改进。

#### handlers（可选项）

handlers 和一般的 tasks 没有什么区别，也是一个列表项，只是通过名字来对它进行引用。

handlers 是由通知者进行 notify，如果没有被通知 handlers 不会被执行，不管有多少个通知者进行了 notify，等到所有 task 执行完成之后，handlers 也只会被执行一次。同时 handlers 也会按照声明的顺序执行。

handlers 最佳的应用场景是用来重启服务，或者触发系统重启操作，除此以外很少用到了。在上面的示例中，我们在 handlers 中使用 service 模块，对安装好的服务程序 “bc” 进行重启。

### Playbook 运行

常用以下命令执行 Playbook：

```bash
ansible-playbook <playbook 文件名> [选项]
```

ansible-playbook 支持大量选项，如 -f 指定执行进程的并行数量，-b 提升执行权限等。

与 AD-HOC 命令类似，执行 Playbook 也会返回大量的运行状态信息，如 ok、changed 和 failed 等，根据这些状态信息，结合 TASK 中的任务名，可以快速定位到发生错误的位置，分析出错误的原因。

测试 ping 模块：

```yaml
---
- hosts: all
  tasks:
    - name: test connection
      ping: # ping 模块，常用于测试 ansible 的连接情况
```

运行 Playbook

```bash
ansible-playbook -i inventory.py ping.yaml
```

## Playbook 模块

Ansible 的模块（modules），也被称为 task plugins 或者 library plugins （ 注意和后面将要学习的 plugins 插件是不同的 ），是在 Ansible 中真正进行实际工作方式，在每个任务中执行相应的内容。

模块具有幂等性，即在一个序列中多次运行一个模块和运行一次的效果相同，换句话说，当你再次执行模块时，模块只会执行必要的改动，所以要实现幂等性的一个办法就是让模块检测出已经到达了期望的最终状态，那么退出时就不会再执行任何的动作了。因而重复多次执行 Playbook 也会是安全的。

### service 模块

这是一个比较基本的模块定义，主要用于管理服务。使用 key=value 这种参数格式来书写。

```yaml
---
# 开启服务
- hosts: all
  tasks:
    - name: make sure nginx is running
      service: name=nginx state=started

# 也可以用下面这种 key：value 参数格式来书写
- hosts: all
  tasks:
    - service:
        name: nginx
        state: started
...

```

name 用于指定要管理的服务，在示例中为 httpd 服务。

state 表示设置的服务状态，常用的选项有：

- reloaded（重载）
- restarted（重启）
- started （启动）
- stopped （停止）

类似地，还有参数 enabled，该参数的值为 yes/no ，表示服务是否在机器启动时运行。注意使用 service 模块时，必须指定服务为 state 的四个状态之一，或者指定 enabled 的值。

### playbook 中的 shell 模块

shell 模块用法很简单也很常用，就像直接输入执行命令一样。不过，shell 模块（和 command 模块）是唯一不会使用 key=value 参数格式的模块，它们只取得参数的列表。

```yaml
- name: make install gucad
  shell: ./configure --with-init-dir=/etc/init.d && make && make install && ldconfig && update-rc.d guacd defaults
  args:
      chdir: /home/ubuntu/src/guacamole-server-0.9.9/
```

不过在 shell 命令中大多数的常用命令已经被做成了一个模块，可以直接使用而不用采用 shell 命令来执行，只是有些命令的参数还未完全转化成模块，这种情况下才采用 shell 模块来实现。

## Playbook 过滤器

Ansible 的过滤器（Filter）特性实际上是通过 Jinja2 模板引擎支持实现的，过滤器常用于在模板表达式中转换数据，Jinja2 提供了大量内建的过滤器

<https://jinja.palletsprojects.com/en/2.11.x/templates/#builtin-filters>

### 列表过滤器

列表过滤器作用在列表变量上，常用的有 min、max 和 flatten 等。

- min

min 过滤器作用是获取列表中的最小值，如下所示：

```jinja
{{ [3, 4, 2] | min }}
```

上面的例子中，使用管道将列表 `[3, 4, 2]` 作为 min 过滤器的输入，获取列表中的最小值，所以例子中的模板最终获得的值是 2。

类似地，max 过滤器获取列表中的最大值。

- flatten

flatten 过滤器作用是对列表进行扁平化处理，如下所示：

```jinja
{{ [3, [4, 2] ] | flatten }}
```

上面例子中，输入的列表中仍包含了一层列表 `[4, 2]`，通过 flatten 过滤器处理，该列表将会被扁平化处理为 `[3, 4, 2]`。实际上，flatten 过滤器还可以指定参数 levels，即扁平化的层数，上面的例子实际上隐含了默认参数值 levels=1。如下所示：

```jinja
{{ [3, [4, [2]] ] | flatten(levels=2) }}
```

在上面例子中，三层嵌套的列表，需要将扁平化参数设为 2，才能获得 `[3, 4, 2]` 这种一层的列表；如果参数使用默认的 1，扁平化后的列表为 `[3, 4, [2]]` ，注意最后一个元素仍为列表。

### 集合过滤器

集合过滤器作用在集合或列表上，返回一个没有重复元素的集合。

- unique

unique 过滤器可去除集合中的重复元素，获得元素唯一的集合，如下所示：

```jinja
{{ [1, 1, 2, 3] | unique }}
```

经过 unique 过滤器处理后，原列表 `[1, 1, 2, 3]` 将变为 `[1, 2, 3]`。

- union

union 过滤器作用是合并两个集合，相当于求并集，如下所示：

```jinja
{{ [1, 1, 2, 3] | union([2, 3, 4, 5]) }}
```

上面例子的结果为 `[1, 2, 3, 4, 5]` 。

- intersect

intersect 过滤器的作用是求两个集合都有的元素，相当于求交集，如下所示：

```jinja
{{ [1, 1, 2, 3] | intersect([2, 3, 4, 5]) }}
```

上面例子的结果为 `[2, 3]`。

- difference

difference 过滤器作用是求前一个集合有，而后一个集合没有的元素，相当于求差集，如下所示：

```jinja
{{ [1, 1, 2, 3] | difference([2, 3, 4, 5]) }}
```

上面例子的结果为 `[1]`。

- symmetric_difference

从字面上理解，symmetric_difference 过滤器的作用是求对称差集，即求两个集合中除了交集以外的元素，如下所示：

```jinja
{{ [1, 1, 2, 3] | symmetric_difference([2, 3, 4, 5]) }}
```

上面例子的结果为 `[1, 4, 5]`。

## Playbook 控制语句

### Playbook 条件

- When 语句

通常一个任务的结果会取决于变量的值、事件、或者之前任务的结果，然后通过某些条件是否满足来判断如何控制执行。

一个条件执行可以像如下语句所示：

```yaml
vars:
  flag: true

tasks:

- shell: echo "True."
  when: flag

- shell: echo "False."
  when: not flag

```

在上面的例子中，第一个任务 when 语句对布尔值变量 flag 的进行判断，flag 值为真，因此会执行 shell 模块中的命令；第二个任务的 when 语句中使用了 not，判断条件为假，则不执行 shell 模块。

对于 Playbook 中没有声明的变量，常使用 Jinja2 的 defined 和 undefined 去判断变量是否被定义，如下示例：

tasks:

```yaml
- shell: echo "I've got '{{ foo }}' and am not afraid to use it!"
  when: foo is defined

- fail: msg="Bailing out. this play requires 'bar'"
  when: bar is undefined

```

在上面的例子中，如果 foo 变量已经定义，则执行 shell 模块中的命令；如果 bar 变量未定义，则执行 fail 模块。

fail 模块用于 Playbook 的错误处理，遇到错误时，起到中断任务、输出错误信息的作用；因为要对错误进行判断，因此 fail 模块经常与 when 语句搭配使用。

Playbook 还有一类在 when 语句中频繁使用的数值，这些数值与操作系统的类型和版本有关，用于针对操作系统编写不同的任务。如下示例：

```yaml
tasks:
  - name: 'shut down CentOS 6 systems'
      command: /sbin/shutdown -t now
      when:
      - ansible_facts['distribution'] == "CentOS"
      - ansible_facts['distribution_major_version'] == "6"

```

在上面的例子中，when 语句有两个判断条件，首先是 `ansible_facts['distribution']` 这个变量代表操作系统的类型，接着 `ansible_facts['distribution_major_version']` 代表系统的具体版本。上面的任务可描述为：对于使用 CentOS 6 操作系统的主机，执行立即关机命令。通过这个例子我们也发现了 when 语句中可以使用 == 、>、< 这类比较符号。

### Playbook 循环

若在一个任务中想要创建大量用户或安装许多包，或者重复轮询步骤，这是通过循环（loop）就能高效的实现结果。

和一般循环相似，Playbook 也有标准循环、嵌套循环、哈希循环等等。

- 标准循环

下面是最简单的循环形式，重复的对象为普通的列表。

添加多个用户

```yaml
- name: add several users
  user: # user模块用于管理系统中的用户信息
    name: '{{ item }}'
    state: present
    groups: 'group1' # 用户组名
  loop:
  - testuser1
  - testuser2
```

item 是用于放置需要读取的变量的位置，loop 下的列表元素将会一次放置在 item 处。上面的语句相当于如下写法：

```yaml
- name: add user testuser1
  user:
    name: 'testuser1'
    state: present
    groups: 'group1'
- name: add user testuser2
  user:
    name: 'testuser2'
    state: present
    groups: 'group1'
```

从示例中可以发现，loop 与编程语言中的循环语句类似，能够节省大量的重复代码。

- 列表循环

已定义好的列表也可以用于循环，如下示例：

添加多个用户

```yaml
vars:
  somelist: ['testuser1', 'testuser2']
tasks:

- name: add several users
    user:
      name: '{{ item }}'
      state: present
      groups: 'group1'
    loop: '{{ somelist }}'
```

- 哈希循环

哈希循环就是对哈希表（散列表）进行循环操作，也属于标准循环，和列表循环主要区别在于能够在循环中引用子键，如下示例：

添加多个用户

```yaml
- name: add several users
  user:
    name: '{{ item.name }}'
    state: present
    groups: '{{ item.groups }}'
  loop:
  - { name: 'testuser1', groups: 'group1' }
  - { name: 'testuser2', groups: 'group2' }

```

- 嵌套循环

嵌套循环是指具有多层嵌套结构的循环。

嵌套循环示例

```yaml
- name: nested loop
  shell: 'echo {{ item[0] }} - {{ item[1] }}'
  loop: "{{ ['a', 'b'] |product(['1', '2', '3'])|list }}"

```

上面是嵌套循环的示例，loop 部分使用了 Jinja 管道和过滤器。首先将列表 `['a', 'b']` 通过管道传给过滤器 `product()` ，过滤器 `product()` 的主要作用是求两个对象的笛卡尔积（Cartesian product）。这种运算相当于将集合中的元素两两组合，例如 a 和 1 组合成 `['a', '1']`，接着 a 再和 2 组合成 `['a', '2']`，以此类推。但这些组合的结果是分散的，不满足 loop 输入必须为列表的要求，因此要通过管道将 product 的结果传给 list，即对运算结果进行列表化处理。

经过以上处理，loop 部分相当于转换为以下的形式：

```jinja
loop: [['a', '1'], ['a', '2'], ['a', '3'], ['b', '1'], ['b', '2'], ['b', '3']]
```

而 Jinja 模板中 `{{ item[0] }}` 代表组合结果中的第一个元素，例如 `['a','1']` 中的 'a'，`{{ item[1] }}` 同理。

- 比较 loop 和 `with_*`

Loop 是 Ansible 较新版本才加入的特性，其目的是为了逐步取代 `with_*` 这类关键词（ 如 with_items ），但由于loop 功能还不完善，无法完全替代 `with_*`，`with_*` 在未来的一段时间内仍可被使用。

官方推荐在 Playbook 中更多地使用 loop ，同时也在不断地改进 loop 的语法和功能。这两者之间主要有以下区别：

- `with_<lookup>` 关键词依赖 Lookup 插件；
- loop 关键词等效于 with_list，对于普通的循环而言，使用这两个关键词是最合适的选择；
- loop 不接受一个字符串作为输入，必须保证 loop 的输入是列表；with_items 既支持单个字符串，也支持列表作为输入。

将 `with_*` 迁移至 loop

由于 Ansible 官方推荐使用 loop，但存在许多旧项目中使用 `with_*` 语法，因此出于方便考虑，官方文档提供了许多 `with_*` 和 loop 用法间的对应关系，还给出迁移的方案。

`with_list`

`with_list` 可以直接使用 loop 替代，如下示例：

```yaml
- name: with_list
  shell: 'echo {{ item }}'
  with_list:
  - one
  - two

- name: with_list -> loop
  shell: 'echo {{ item }}'
  loop:
  - one
  - two
```

`with_items`

如果使用 with_items，上面的 Playbook 可写成如下示例：

```yaml
- name: with_items
  shell: 'echo {{ item }}'
  with_items: [1, [2, 3], 4]

- name: with_items -> loop
  shell: 'echo {{ item }}'
  loop: '{{ [1,[2,3],4] |flatten(levels=1) }}'

```

注意 with_items 自带一层扁平化效果，而 loop 没有。即上面的 with_items 循环中，item 依次为 1, 2, 3, 4；loop 循环中，如果不使用 `flatten(levels=1)` 语句进行一层扁平化处理，item 本应依次为 `1, [2, 3], 4` ，这就是用到 `flatten()` 过滤器的原因。