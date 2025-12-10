## 配置文件

文档：<https://docs.ansible.com/projects/ansible/latest/reference_appendices/config.html#the-configuration-file>

Ansible 会尝试从以下路径读取设置：

- `ANSIBLE_CONFIG` 环境变量（如果有设置的话）
- `./ansible.cfg`
- `~/.ansible.cfg`
- `/etc/ansible/config`

可以配置的项：<https://docs.ansible.com/projects/ansible/latest/reference_appendices/config.html#common-options>

## 默认配置

生成默认的配置文件

```bash
ansible-config init --disabled > ansible.cfg
```

## 示例

```ini
[defaults]
inventory = hosts.yaml # inventory 是声明 hosts 配置文件
```

