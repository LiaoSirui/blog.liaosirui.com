## 基本概念

端口敲门服务，即：knockd服务。该服务通过动态的添加iptables规则来隐藏系统开启的服务，使用自定义的一系列序列号来“敲门”，使系统开启需要访问的服务端口，才能对外访问。不使用时，再使用自定义的序列号来“关门”，将端口关闭，不对外监听。进一步提升了服务和系统的安全性

端口敲门是一种通过在预设的一组关闭端口上生成连接尝试来从外部打开防火墙端口的方法。一旦收到正确的连接尝试序列，防火墙规则就会动态修改，允许发送连接尝试的主机通过特定端口连接。此技术通常用于隐藏重要服务（例如SSH），以防止暴力破解或其他未经授权的攻击

## 工作原理

端口敲门的工作原理基于以下步骤：

1. 闭合端口：默认情况下，所有重要端口（如 22 端口）在防火墙上都是关闭的
2. 发送敲门序列：用户在尝试连接之前，首先需要向一组预定义的端口发送一系列 TCP/UDP 包。这些端口可能是随机选择的，例如 1234、5678 和 9101
3. 验证序列：防火墙监视传入流量，检测这些特定的端口敲门序列
4. 打开端口：如果敲门序列正确，防火墙会暂时打开 SSH 端口，让用户能够连接到服务器
5. 超时或关闭端口：一段时间后，如果没有进一步的连接，端口会自动关闭

## knockd 配置示例

knockd 敲门服务的默认配置文件路径为：

```bash
> /etc/knockd.conf

[options]
    UseSyslog

[opencloseSSH]
    sequence      = 2222:udp,3333:tcp,4444:udp
    seq_timeout   = 15
    tcpflags      = syn,ack
    start_command = /sbin/iptables -A INPUT -s %IP% -p tcp --dport ssh -j ACCEPT
    cmd_timeout   = 10
    stop_command  = /sbin/iptables -D INPUT -s %IP% -p tcp --dport ssh -j ACCEPT
```

配置 knockd 服务

```bash
> cat /etc/knockd.conf

[options]
    # UseSyslog
    LogFile = /var/knock/knock.log
[openSSH]
    # 定义敲门暗号顺序
    sequence    = 7000,8000,9000
    # 设置超时时间，时间太小可能会出错
    seq_timeout = 30
    # 设置敲门成功后所执行的命令
    # 在 ubuntu 系统 iptables 规则默认是禁止所有的规则，如果直接添加规则默认是在 drop all 规则之后，因此需要先删除 drop all 的规则再添加所要设置的规则，最后重新添加 drop all 的规则
    # command = /sbin/iptables -D INPUT -p tcp --dport 10022 -j DROP && /sbin/iptables -A INPUT -s [允许远程的IP] -p tcp --dport 10022 -j ACCEPT && /sbin/iptables -A INPUT -p tcp --dport 10022 -j DROP
    command     = /sbin/iptables -I INPUT -s %IP% -p tcp --dport 10022 -j ACCEPT
    tcpflags    = syn
[closeSSH]
    sequence    = 9000,8000,7000
    seq_timeout = 30
    command     = /sbin/iptables -D INPUT -s %IP% -p tcp --dport 10022 -j ACCEPT
    tcpflags    = syn
```

配置文件里有两个参数:

- Options：你可以在此字段中找到 knockd 的配置选项。正如你在上面屏幕截图中所看到，它使用 syslog 进行日志记录
- OpenSSH：该字段包括序列、序列超时、命令和 tcp 标志
- Sequence：它显示可由客户软件用作启动操作的模式的端口序列。sequence 按照顺序依次访问端口，command 执行的条件。比如这里是依次访问 7000, 8000, 9000 端口，默认使用 TCP 访问
- Sequence timeout：它显示分配给客户端以完成所需的端口试探序列的总时间
- command：这是一旦客户软件的试探序列与序列字段中的模式，执行的命令。command 当 knockd 监测到 sequence 端口访问完成，然后执行此处 command，这里为通过 iptables 开启关闭 ssh 外部访问
- TCP_FLAGS：这是必须针对客户软件发出的试探设置的标志。如果标志不正确，但试探模式正确，不会触发动作

主动阻止端口

```bash
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p tcp --dport 10022 -j REJECT
```

查看规则

```bash
iptables -L INPUT
```

假设目标服务器开启了 knockd 敲门服务，序列号为 7000/8000/9000，开启其 ssh 端口方法为：

```bash
for x in 7000 8000 9000; do 
    nmap -Pn --host_timeout 201 --max-retries 0 -p $x [目标IP];
done 
```

或者

```bash
# Open:
nc -z <target> 7000 8000 9000

# Close:
nc -z <target> 9000 8000 7000
```

使用 knock 程序

```bash
# 开启
knock -v SERVER_IP 7000 8000 9000 -d 500

# 关闭
knock -v SERVER_IP 9000 8000 7000 -d 500
```

ssh config 中添加

```bash
Match host repo03 exec "nc -zw 3 %h 10022 || knock -d 500 %h 7000 8000 9000"
Host repo03
    HostName 192.168.16.45
    User root
    Port 10022
```

## 其他

注意事项：

- 安全性：虽然端口敲门提高了安全性，但仍然需要结合其他安全措施，如强密码和双因素认证。
- 日志管理：由于敲门序列是通过日志监控实现的，确保日志的安全性和完整性也是必要的

Ansible 敲门：

- <https://github.com/berlic/ansibledaily/blob/master/connection_plugins/ssh_pkn.py>
- <https://ansibledaily.com/ssh-with-port-knocking/>
- <https://github.com/progmaticltd/ansible-ssh-connection-fwknop>

```python
from ansible.plugins.connection.ssh import Connection as ConnectionSSH
from ansible.errors import AnsibleError
from socket import create_connection
from time import sleep

try:
    from __main__ import display
except ImportError:
    from ansible.utils.display import Display
    display = Display()

class Connection(ConnectionSSH):

    def __init__(self, *args, **kwargs):

        super(Connection, self).__init__(*args, **kwargs)
        display.vvv("SSH_PKN (Port KNock) connection plugin is used for this host", host=self.host)

    def set_host_overrides(self, host, hostvars=None):

        if 'knock_ports' in hostvars:
            ports = hostvars['knock_ports']
            if not isinstance(ports, list):
                raise AnsibleError("knock_ports parameter for host '{}' must be list!".format(host))

            delay = 0.5
            if 'knock_delay' in hostvars:
                delay = hostvars['knock_delay']

            for p in ports:
                display.vvv("Knocking to port: {0}".format(p), host=self.host)
                try:
                    create_connection((self.host, p), 0.5)
                except:
                    pass
                display.vvv("Waiting for {0} seconds after knock".format(delay), host=self.host)
                sleep(delay)
```

