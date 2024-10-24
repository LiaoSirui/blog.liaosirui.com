## 配置最基础的邮件服务器

docker-mailserver

- <https://docker-mailserver.github.io/docker-mailserver/latest/>
- <https://github.com/docker-mailserver/docker-mailserver>

`docker-mailserver` 使用 `docker compose` 来管理

```bash
mkdir ~/mailserver && cd ~/mailserver
 
DMS_GITHUB_URL='https://raw.githubusercontent.com/docker-mailserver/docker-mailserver/master'
wget "${DMS_GITHUB_URL}/docker-compose.yml"
wget "${DMS_GITHUB_URL}/mailserver.env"
wget "${DMS_GITHUB_URL}/setup.sh"
chmod a+x ./setup.sh
```

配置 mailserver 本身。首先需要添加一个邮件账户并设置密码，在未添加账户的情况下 mailserver 会反复重启

```bash
docker compose exec -ti mailserver setup email add postmaster@alpha-quant.tech
```

## DNS

### A/AAAA 记录

使用了 `mail.alpha-quant.tech` 来指示邮件服务器，因此需要添加一条指向邮件服务器 IP 的 A 记录来实现解析

### MX 记录

MX 记录标记了对本域名负责的邮件服务器地址，以便想给你发信的人找到投递目标。在这里需要添加一条 Host 为 `alpha-quant.tech`，指向 `mail.alpha-quant.tech` 的 MX 记录。这条记录含义为 `*@alpha-quant.tech` 的邮件由 `mail.alpha-quant.tech` 负责。

| TYPE | HOST                  | ANSWER                |
| ---- | --------------------- | --------------------- |
| A    | mail.alpha-quant.tech | <MAIL_SERVER_IP>      |
| MX   | alpha-quant.tech      | mail.alpha-quant.tech |

有了这两条记录，就准备好接收信件了。任何人发往 `*@alpha-quant.tech` 的邮件应当能被正确指引到刚刚启动的邮件服务器

mailserver 并不是来者不拒照单全收，而是会通过各种手段检查发信方的身份。当发信的时候，收信方往往也会进行同样的甚至更严格的检查。为了不让发出的信件被丢进垃圾桶，需要一条 rDNS 和一些特殊格式的 TXT 记录证明 “我就是我”

### rDNS

rDNS 的设置并不在你的域名管理处，而是在你的主机管理处。普通 DNS 查询域名返回 IP，rDNS 则是查询 IP 返回域名。当服务器收到邮件时，会通过 rDNS 查询来源服务器的 IP，比对返回结果与 HELO。不匹配的邮件会被认为是可疑的。

如果你的主机管理面板没有设置 rDNS 的地方，你可能需要咨询主机提供商客服。在这里，我将承载我邮件服务器的主机的 rDNS 设为 `mail.alpha-quant.tech`，和上文设置的 A 记录遥相呼应

测试

```
$ dig @1.1.1.1 +short MX alpha-quant.tech
mail.alpha-quant.tech
$ dig @1.1.1.1 +short A mail.alpha-quant.tech
11.22.33.44
$ dig @1.1.1.1 +short -x 11.22.33.44
mail.alpha-quant.tech
```

## DKIM, DMARC & SPF

### SPF

SPF 记录用于指定哪些服务器是指定的发信服务器，以阻止伪造的信件。

向 `alpha-quant.tech` 添加一条值为 `v=spf1 mx ~all` 的 TXT 记录，我们就完成了 SPF 配置。这条记录的含义是：

- 这是一条需要使用 spf1 语法解析的记录
- 允许 MX 记录指向的服务器发信（在这里是 `mail.alpha-quant.tech`）
- 对其余所有来源软拒绝（标记为可疑邮件）

在设置这条记录后，仅有来源于 MX 的发信能够通过 SPF 检查。如果你需要从多个服务器发信，可以按 SPF 记录语法加入所需的其他服务器

```bash
"v=spf1 mx mx:alpha-quant.tech -all"
# 允许当前域名和 alpha-quant.tech 的 mx 记录对应的 IP 地址。
```

### DKIM

相较于 SPF，DKIM 是更进一步的身份验证。DKIM 使用了与 SSL 证书类似的非对称机制，但通过 TXT 记录取代了 CA 的位置。我们通过一条符合 DKIM 语法的 TXT 记录发布公钥，在发信时附上私钥的签名。收信人通过 DNS 查询获得公钥验签，以确认发信人权威性。

在设置记录前，需要先生成用于 DKIM 的密钥对。在这里指定使用 2048 位长度，因为默认的 4096 位可能存在兼容性问题

```bash
docker compose exec -ti mailserver setup config dkim keysize 2048
cat docker-data/dms/config/opendkim/keys/alpha-quant.tech/mail.txt
```

此时你应该看到形如 `mail._domainkey IN TXT ( "v=DKIM1; h=sha256; k=rsa; ...")` 的输出，这就是需要添加的记录。考虑到部分 DNS 限制 TXT 记录长度，记录被拆成三行。如果你的 DNS 和博主一样不限制，建议将双引号内的值连接成一条后添加，避免出现问题

根据文件指示，添加一条 host 为 `mail._domainkey.alpha-quant.tech`，值为 `v=DKIM1; h=sha256; k=rsa;p=XXXX` 的记录。添加完毕后可以通过 [MX Toolbox DKIM Lookup](https://mxtoolbox.com/dkim.aspx) 来验证格式是否正确

重启容器以应用 DKIM 密钥

### DMARC

DMARC 用于指导收件人应当如何处理未通过 SPF/DKIM 认证的邮件。当服务器收到来自本域名却未通过认证的邮件，会按照 DMARC 指示处理可疑邮件并汇报。如果有坏蛋在伪装我们发信，我们可以通过报告察觉到这种行为。

可以使用这个工具 <https://dmarcguide.globalcyberalliance.org/#/?lang=zh-CN> 来生成适合你的 DMARC。或者直接使用如下片段，修改 ruf 和 rua 为自己的回报地址

```bash
_dmarc IN TXT "v=DMARC1; p=quarantine; rua=mailto:dmarc.report@example.com; ruf=mailto:dmarc.report@example.com; fo=0; adkim=r; aspf=r; pct=100; rf=afrf; ri=86400; sp=quarantine"
```

将引号内的片段作为值，添加一条 host 为`_dmarc.alpha-quant.tech` 的 TXT 记录。上述工具也可以用于验证你的 DMARC 设置是否正确

### 测试发信

| TYPE | HOST                             | ANSWER                                                       |
| ---- | -------------------------------- | ------------------------------------------------------------ |
| TXT  | alpha-quant.tech                 | v=spf1 mx include:alpha-quant.tech ~all                      |
| TXT  | _dmarc.alpha-quant.tech          | v=DMARC1; p=quarantine; rua=mailto:dmarc.report@alpha-quant.tech; ruf=mailto:dmarc.report@alpha-quant.tech; sp=quarantine; ri=86400 |
| TXT  | mail._domainkey.alpha-quant.tech | v=DKIM1; h=sha256; k=rsa;p=MII…LONG_PUBLIC_KEY…QAB           |

加上这三条 TXT 记录和一条 rDNS 记录，我们应当已经有能力证明 “我是我” 这件事

## 个性化设置

- `Catch-All`

```bash
docker compose exec -ti mailserver setup email add info@alpha-quant.tech
echo "@alpha-quant.tech info@alpha-quant.tech" >> docker-data/dms/config/postfix-virtual.cf
```

将所有未匹配到收件人的邮件转投给这个账户

尝试给存在的账户发信，也会被转发。这是由于 `postfix` 具有虚拟高于真实的查找优先级，发向真实账户的邮件没来及匹配真实账户就被 Catch All 规则匹配走了。

解决方法也很简单：既然被优先级抢走了，就用更高的优先级抢回来。对于任何不想被 Catch All 捕获的地址，添加一条指向自己的别名。至于文件内规则的顺序并不重要，别名拥有高于 Catch All 的优先级。例如，我希望 `admin@alpha-quant.tech` 不被捕获，可以添加别名：

```bash
echo "admin@alpha-quant.tech admin@alpha-quant.tech" >> docker-data/dms/config/postfix-virtual.cf
```

- `no-reply`

```bash
docker compose exec -ti mailserver setup email add no-reply@alpha-quant.tech 
echo "devnull: /dev/null" >> docker-data/dms/config/postfix-aliases.cf
echo "no-reply@alpha-quant.tech devnull\ndevnull@alpha-quant.tech devnull" >> docker-data/dms/config/postfix-virtual.cf
```

注册一个别名 `devnull` 指向 `/dev/null`，然后将 `no-reply` 账户的邮件全部转到 `devnull`。此时此刻我们又要感谢虚拟的高优先级，否则我们无法将发往 `no-reply` 这个真实账户的信件转发

需要特别注意的是，如果设置了任何 Catch-All 规则，则需要额外添加一条 `devnull@alpha-quant.tech devnull` 规则

- `config/postfix-main.cf`

```bash
smtpd_helo_required=no
smtpd_helo_restrictions=
```

