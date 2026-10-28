## OpenLDAP 简介

OpenLDAP 是一个开源的用户系统实现，主要支持 LDAP 协议，可以给其他系统提供用户认证

- <https://www.openldap.org/>
- <https://git.openldap.org/openldap/openldap>

## OpenLDAP 基础概念

### 目录树概念

- `目录树`

在一个目录服务系统中，整个目录信息集可以表示为一个目录信息树，树中的每个节点是一个条目 (Entry)。

- `条目（Entry）`

条目，也叫记录项，是 LDAP 中最基本的颗粒，就像字典中的词条，或者是数据库中的记录。通常对 LDAP 的添加、删除、更改、检索都是以条目为基本对象的。

> LDAP 目录的条目（entry）由属性（attribute）的一个聚集组成，并由一个唯一性的名字引用，即**专有名称**（**distinguished name**，DN）。例如，DN 能取这样的值：" `cn=group,dc=eryajf,dc=net` "。

- `对象类（ObjectClass）`

对象类是属性的集合，LDAP 预想了很多人员组织机构中常见的对象，并将其封装成对象类。比如人员（ `person` ）含有姓（ `sn` ）、名（ `cn` ）、电话 ( `telephoneNumber` )、密码 ( `userPassword` ) 等属性，单位职工 ( `organizationalPerson` ) 是人员 ( `person` ) 的继承类，除了上述属性之外还含有职务（ `title` ）、邮政编码（ `postalCode` ）、通信地址 ( `postalAddress` ) 等属性。

- `属性 (Attribute)`

每个条目都可以有很多属性（Attribute），比如常见的人都有姓名、地址、电话等属性。每个属性都有名称及对应的值，属性值可以有单个、多个

### 属性详解

要注意，如下标识的字段，即 ldap 中可查询交互使用的字段，其中原有的大小写方式，需与之一致。

#### （1）基础字段

- `dc (Domain Component)`

域名的部分，其格式是将完整的域名分成几部分，如域名为 `eryajf.net` 变成 `dc=alpha-quant,dc=tech` 。

- `ou（Organization Unit）`

组织单位，组织单位可以包含其他各种对象 (包括其他组织单元)。

- `cn （Common Name）`

常用名称，可用作分组的名字，或者用户的全名。[参考(opens new window)](https://datatracker.ietf.org/doc/html/rfc4519#section-2.3)

- `dn （Distinguished Name）`

每一个条目都有一个唯一的标识名，dn 在 ldap 中全局唯一，相当于该条目的唯一 ID，如上边示例中的： `cn=group,dc=alpha-quant,dc=tech` 就是该条目的 dn。

- `rdn （Relative dn）`

一般指 dn 逗号最左边的部分，如 `cn=group,dc=alpha-quant,dc=tech` 的 rdn 就是 `cn=group` 。

- `Base DN`

LDAP 目录树的最顶部就是根，比如上边示例中的 base dn 为 `dc=alpha-quant,dc=tech` 。

- `description`

在不同类别中，对应不同类别的说明信息，比如用户的说明信息，分组的说明信息。

#### （2）用户字段

用户字段依然会用到基础字段，并不代表这部分内容与上边的内容是隔离的。

- `objectClass` ： `top` 、 `person` 、 `organizationalPerson` 、 `inetOrgPerson` 、 `posixAccount`

- `uid (User Id)`

用户的用户名，通常为中文拼音，或者用邮箱地址的用户名部分。

- `sn （Surname）`

用户的姓氏，对于中文环境下，可以直接用姓名填充。

- `givenName`

用户的名字，不包含姓，对于中文语境下，可灵活运用该字段。

- `displayName`

用户的显示名字，全名。

- `mail`

用户的邮箱。

- `title`

用户的职位。

- `employeeNumber`

用户的员工 ID，也可以理解为工号。

- `employeeType`

用户在单位中的角色。

- `departmentNumber`

用户所在部门的名称，通常为部门名，而非部门号。

- `businessCategory`

描述业务的种类，在中文语境中可灵活定义。[参考(opens new window)](https://datatracker.ietf.org/doc/html/rfc4519#section-2.1)

- `userPassword`

用户密码。

- `jpegPhoto`

用户的个人资料照片。

- `photo`

用户的照片，如上这两个字段都可以用。

- `postalAddress`

用户的邮政地址，也可以直接认为是用户地址。[参考(opens new window)](https://datatracker.ietf.org/doc/html/rfc4519#section-2.23)

- `entryUuid`

此用户专属的固定通用标识符，类似 union_id，通常用不到。

- `objectSid`

此用户专属的通用标识符，与 Windows 安全标识符兼容。

- `uidNumber`

用户的 POSIX UID 号码。如果为用户设置了 POSIX ID，这里则会显示此号码。否则，这里会显示专属的固定标识符。

- `gidNumber`

用户主要群组的 POSIX GID 号码。如果为用户设置了 POSIX GID，这里则会显示此号码。否则，则会显示与用户的 UID 相同的号码。

> **注意**：无法按 *uidNumber* 或 *gidNumber* 搜索用户，除非管理员使用 [Admin SDK API (opens new window)](https://developers.google.com/admin-sdk/directory/reference/rest/v1/users/update)设置了用户的 posixAccounts 属性。

- `homeDirectory`

用户的 POSIX 主目录。默认为 `/home/<用户名>` 。

- `loginShell`

用户的 POSIX 登录 shell。默认为 `/bin/bash` 。

- `carLicense`

车牌，通常用不上这个字段。

- `homePhone`

家庭固定电话，通常用不上这个字段。

- `homePostalAddress`

邮编，通常用不上这个字段。

- `roomNumber`

房间号码，通常用不上这个字段。

- `secretary`

秘书，通常用不上这个字段。

#### （3）分组字段

- `objectClass` ： `top` 、 `groupOfNames` 、 `posixGroup`

- `displayName`

用户可理解的群组显示名称。

- `description`

用户可理解的群组详细说明。

- `gidNumber`

群组的 POSIX GID 号码。这是固定的专属 ID，但无法通过此 ID 高效地查找群组。

- `entryUuid`

此群组专属的固定通用标识符。

- `member`

此群组中成员的完全符合条件的名称列表。

- `memberUid`

此群组中成员的用户名列表。 

##  搭建 OpenLDAP

拉取镜像

```bash
docker-pull() {
  skopeo copy docker://${1} docker-daemon:${1}
}
docker-pull "docker.io/bitnami/openldap:2.6.9-debian-12-r1"
```

给 OpenLDAP 配置 TLS。首先用 OpenSSL 生成 CA 和证书。

创建数据目录

```bash
mkdir ./openldap-data
chown -R 1001:root ./openldap-data

chown -R 1001:root certs
```

启动一个 OpenLDAP 服务端

```yaml
services:
  openldap:
    image: harbor.alpha-quant.tech/3rd/docker.io/bitnami/openldap:2.6.9-debian-12-r3
    ports:
      - "389:389" # LDAP
      # - '636:636' # LDAPS
    environment:
      - LDAP_PORT_NUMBER=389
      - LDAP_LDAPS_PORT_NUMBER=636
      - LDAP_ADMIN_USERNAME=${LDAP_ADMIN_USERNAME}
      - LDAP_ADMIN_PASSWORD=${LDAP_ADMIN_PASSWORD}
      - LDAP_USERS=${LDAP_USERS}
      - LDAP_PASSWORDS=${LDAP_PASSWORDS}
      - LDAP_ROOT=DC=alpha-quant,DC=tech
      - LDAP_ADMIN_DN=CN=${LDAP_ADMIN_USERNAME},DC=alpha-quant,DC=tech
      - LDAP_ALLOW_ANON_BINDING=no
      - LDAP_ENABLE_TLS=yes
      - LDAP_REQUIRE_TLS=no
      - LDAP_TLS_CERT_FILE=/opt/bitnami/openldap/certs/alpha-quant.tech.crt
      - LDAP_TLS_KEY_FILE=/opt/bitnami/openldap/certs/alpha-quant.tech.key
      - LDAP_TLS_CA_FILE=/opt/bitnami/openldap/certs/alpha-quant.tech.CA.crt
      - LDAP_TLS_DH_PARAMS_FILE=/opt/bitnami/openldap/certs/slapd.dh.params
    volumes:
      - ./certs:/opt/bitnami/openldap/certs
      - ./ldifs:/extra-ldifs
      - ${DATA_DIR}:/bitnami/openldap
    networks:
      - openldap
  phpldapadmin:
    image: harbor.alpha-quant.tech/infra/portal/openldap-pla:main-ecec623-250208171404
    depends_on:
      - openldap
    ports:
      - "11080:80"
    networks:
      - openldap
networks:
  openldap:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 172.28.1.0/24
          gateway: 172.28.1.254

```

admin 密码建议单独保存，例如写在 `.env` 中：

```bash
LDAP_ADMIN_USERNAME=sys-admin
LDAP_ADMIN_PASSWORD=12345678REDACTED

LDAP_USERS=sys-reader
LDAP_PASSWORDS=12345678REDACTED

DATA_DIR=/mnt/data-hdd1/openldap

```

指定最小 TLS 证书版本

```bash
docker compose exec -T openldap ldapmodify -Y EXTERNAL -H "ldapi:///" << __EOF__
dn: cn=config
changetype: modify
add: olcTLSProtocolMin
olcTLSProtocolMin: 3.3

__EOF__
```

访问方式：

- LDAP

```bash
ldapwhoami \
    -H ldap://ldap.alpha-quant.tech:389/ \
    -x \
    -D "cn=admin,dc=alpha-quant,dc=tech" \
    -W
```

- LDAP Over SSL

```bash
ldapwhoami \
    -H ldaps://ldap.alpha-quant.tech:636/ \
    -x \
    -D "cn=admin,dc=alpha-quant,dc=tech" \
    -W \
    -o TLS_CACERT="$PWD/certs/alpha-quant.tech.CA.crt"
```

- LDAP Over TLS

```bash
ldapwhoami \
    -H ldap://ldap.alpha-quant.tech:389/ \
    -x \
    -ZZ \
    -D "cn=admin,dc=alpha-quant,dc=tech" \
    -W \
    -o TLS_CACERT="$PWD/certs/alpha-quant.tech.CA.crt"
```

可以通过 ldapsearch 列出所有对象，默认情况下不需要登录（Bind DN），可以只读访问：

```bash
ldapsearch \
    -H ldap://localhost:389/ \
    -x \
    -D "cn=admin,dc=alpha-quant,dc=tech" \
    -b "dc=alpha-quant,dc=tech" \
    -W
```

管理员修改用户的密码，使用 ldappasswd 修改：

默认情况下，用户没有权限修改自己的密码。可以进入 Docker 容器，修改数据库的权限：

```bash
docker compose exec -T openldap ldapmodify -Y EXTERNAL -H "ldapi:///" << __EOF__

# Paste the following lines
# Allow user to change its own password
dn: olcDatabase={2}mdb,cn=config
changetype: modify
replace: olcAccess
olcAccess: {0}to attrs=userPassword
  by anonymous auth
  by self write
  by * none
olcAccess: {1}to *
  by * read

__EOF__

```

通过管理员修改密码

```bash
LDAPTLS_CACERT=$PWD/certs/openldap.crt ldappasswd \
    -H ldaps://ldap.alpha-quant.tech:636/ \
    -x \
    -S \
    -D "cn=admin,dc=alpha-quant,dc=tech" \
    -W \
    cn=user01,ou=users,dc=alpha-quant,dc=tech
```

用户修改密码

```bash
LDAPTLS_CACERT=$PWD/certs/openldap.crt ldappasswd \
    -H ldaps://ldap.alpha-quant.tech:636/ \
    -x \
    -S \
    -D "cn=user01,ou=users,dc=alpha-quant,dc=tech" \
    -W
```

并且 userPassword 也对非 admin 用户被隐藏

## LDAP 管理面板

## 自助修改密码系统

问题解决，添加命令如下：

``` 
ldapmodify -Y EXTERNAL -H ldapi:/// -f updatepass.ldif
```

"AD 自助修改密码" 是 AD 服务中的一个重要功能，它允许用户通过 Web 界面自主更改自己的密码，无需管理员介入，提高了效率并降低了支持成本

- <https://github.com/ltb-project/self-service-password>
- <https://github.com/alvinsiew/ldap-self-service>

## 用户和组管理

### 创建用户

## 参考资料

- <https://blog.csdn.net/achi010/article/details/130655238>

- <http://114.242.246.250:8036/basetool/ldap.html>

- OpenLDAP 基础概念 <https://ldapdoc.eryajf.net/pages/17ba17/#%E5%9F%BA%E7%A1%80%E5%AD%97%E6%AE%B5>
