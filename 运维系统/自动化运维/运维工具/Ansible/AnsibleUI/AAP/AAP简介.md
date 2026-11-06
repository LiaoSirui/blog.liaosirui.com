## AAP

Ansible Automation Platform （AAP）是红帽推出的一套可提供一个企业框架，用于从混合云到边缘大规模构建和运维 IT 自动化。Ansible 自动化平台使整个企业的用户（从开发、运维到安全和网络团队）能够创建、共享和管理自动化。

## 部署

新建用户

```bash
useradd aap
passwd aap
echo 'aap ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/aap
chmod 440 /etc/sudoers.d/aap
loginctl enable-linger aap    # keep rootless podman containers running after logout

dnf install -y crudini
```

准备下 hosts

```bash
# Example: give this host a resolvable FQDN
echo "$(hostname -I | awk '{print $1}') aap.lab.local $(hostname)" | sudo tee -a /etc/hosts
getent hosts aap.lab.local
```

切换到普通用户 aap，解压安装包

```bash
tar xvf ansible-automation-platform-setup-bundle-<version>.tar.gz
cd ansible-automation-platform-containerized-setup-<version>
```

准备环境

```bash
python3 -m venv --copies .venv
source .venv/bin/activate
pip install 'ansible-core>=2.14,<2.15' -i https://pypi.tuna.tsinghua.edu.cn/simple
```

修改配置

```bash
cp inventory inventory.enterprise.bak
cp inventory-growth inventory
sed -i 's/aap\.example\.org/aap.lab.local/g' inventory
```

填密码和 registry 账号

```bash
INV=inventory
PW='YourStrongPass'

crudini --set "$INV" all:vars registry_username 'cyril.liaosirui@gmail.com'
crudini --set "$INV" all:vars registry_password 'your_rhn_pass'
crudini --set "$INV" all:vars postgresql_admin_password "$PW"

for k in gateway_admin_password controller_admin_password hub_admin_password eda_admin_password \
         gateway_pg_password controller_pg_password hub_pg_password eda_pg_password \
         automationmetrics_pg_password automationmetrics_controller_read_pg_password; do
  crudini --set "$INV" all:vars "$k" "$PW"
done

# Should print nothing
grep -n '<' "$INV" | grep -v ':#'
```

在 Rocky 上，preflight 会在 `collections/ansible_collections/ansible/containerized_installer/roles/preflight/tasks/nodes.yml` 这里直接失败。要继续，只能把这一处断言改掉，比如把 `ansible_distribution == 'RedHat'` 改成 `ansible_distribution in ['RedHat', 'Rocky']`

执行安装

``` bash
ansible-playbook ansible.containerized_installer.install
```

使用 license 申请：<https://www.ansible.com/license>

Crack: `awx/main/utils/licensing.py`

卸载：

```bash
ansible-playbook ansible.containerized_installer.uninstall
```

