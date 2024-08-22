将 Ansible 视为一门编程语言（DSL）的现在，我们可以发现在 Ansible 文档中用 Roles 表示“模块”这个概念，用 import_tasks、include_tasks 等表示 import 这个概念

一个模块是一个业务功能的具体实现，当后期有修改的需求时只需要修改相关的模块即可，这正是 SOLID 原则中的 “SRP” (单一职责原则) 所提倡的。此外，模块化还支持像“搭积木”一样根据业务需求灵活地组织业务流程，这样就能最大限度地复用当前模块，这也符合编程原则中的 “DRY” (Don't Repeat Yourself)

```
├── defaults
│   └── main.yml
├── files
├── handlers
│   └── main.yml
├── meta
│   └── main.yml
├── tasks
│   └── main.yml
├── templates
├── tests
│   ├── inventory
│   └── test.yml
└── vars
    └── main.yml
```

这八个目录的作用是：

- tasks/main.yml：放置 role 执行任务时用到的文件。
- handlers/main.yml：处理程序，可以在 role 内部或外部使用
- library/my_module.py：模块，可以在 role 中使用(有关更多信息，请参见在rroles 中嵌入模块和插件)。
- defaults/main.yml：role 的默认变量(有关更多信息，请参阅使用变量)。这些变量具有所有可用变量中最低的优先级，并且可以被任何其他变量(包括库存变量)轻松覆盖。
- vars/main.yml：role 中的其他变量。（与 Ansible 模块中的 vars 作用一致，只不过这里的 vars 表示目录。）
- files/main.yml：role 部署时用到的文件。
- templates/main.yml：role 部署时用到的模板。与 Ansible 模块中的 templates 作用一致，只不过这里的 templates 表示目录。）
- meta/main.yml：role 使用到的元数据

Ansible 中已内置了一个命令行工具 ansible-galaxy 快速创建 role 的八大目录，减轻我们的工作量

```
ansible-galaxy init flink
```

Ansible Galaxy 也有一个在线社区 Galaxy[https://galaxy.ansible.com/home]，上面有开发者分享的各种已经开发好的 roles。方便我们搜索现成的 role 下载，也可以上传自己开发的 role 到 Galaxy

```
ansible-galaxy install username.role_name
```

