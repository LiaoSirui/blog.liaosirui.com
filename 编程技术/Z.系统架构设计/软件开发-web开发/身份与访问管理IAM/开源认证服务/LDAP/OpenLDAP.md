## OpenLDAP 简介

OpenLDAP 是一个开源的用户系统实现，主要支持 LDAP 协议，可以给其他系统提供用户认证

- <https://www.openldap.org/>
- <https://git.openldap.org/openldap/openldap>

## 搭建 OpenLDAP

拉取镜像

```bash
docker-pull() {
  skopeo copy docker://${1} docker-daemon:${1}
}
docker-pull "docker.io/bitnami/openldap:2.6.8-debian-12-r9"
```

给 OpenLDAP 配置 TLS。首先用 OpenSSL 生成 CA 和证书：

```bash
CERT_HOST="alpha-quant.cc"

# setup CA
mkdir -p certs

openssl genrsa -out certs/ldap_ca.key 4096
openssl req -x509 -new -nodes -key certs/ldap_ca.key -sha256 -days 36500 -out certs/openldapCA.crt -subj "/CN=${CERT_HOST}/ST=Sichuan/L=Sichuan/O=AlphaQuant"

# setup cert
# CN must match hostname
openssl req -new -nodes -out certs/openldap.csr -newkey rsa:4096 -keyout certs/openldap.key -subj "/CN=${CERT_HOST}/ST=Sichuan/L=Sichuan/O=AlphaQuant"
openssl x509 -req -in certs/openldap.csr -CA certs/openldapCA.crt -CAkey certs/ldap_ca.key -CAcreateserial -out certs/openldap.crt -days 730 -sha256

chown -R 1001:root certs
```

创建数据目录

```bash
mkdir ./openldap-data
chown -R 1001:root ./openldap-data
```

启动一个 OpenLDAP 服务端

```yaml
services:
  openldap:
    image: docker.io/bitnami/openldap:2.6.8-debian-12-r9
    ports:
      # LDAP
      - '389:389'
      # LDAPS
      - '636:636'
    environment:
      - LDAP_PORT_NUMBER=389
      - LDAP_LDAPS_PORT_NUMBER=636
      - LDAP_ADMIN_USERNAME=admin
      - LDAP_ADMIN_PASSWORD=adminpassword
      - LDAP_ROOT=dc=alpha-quant,dc=cc
      - LDAP_ADMIN_DN=cn=admin,dc=alpha-quant,dc=cc
      - LDAP_ALLOW_ANON_BINDING=no
      - LDAP_ENABLE_TLS=yes
      - LDAP_TLS_CERT_FILE=/opt/bitnami/openldap/certs/openldap.crt
      - LDAP_TLS_KEY_FILE=/opt/bitnami/openldap/certs/openldap.key
      - LDAP_TLS_CA_FILE=/opt/bitnami/openldap/certs/openldapCA.crt
    volumes:
      - ./certs:/opt/bitnami/openldap/certs
      - ./openldap-data:/bitnami/openldap
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
LDAP_ADMIN_PASSWORD=12345678REDACTED
```

然后在 compose 中引用：

```yaml
# admin password
env_file: .env
```

然后就可以通过 ldapsearch 列出所有对象，默认情况下不需要登录（Bind DN），可以只读访问：

```bash
ldapsearch \
    -H ldap://localhost:389/ \
    -x \
    -D "cn=admin,dc=alpha-quant,dc=cc" \
    -b "dc=alpha-quant,dc=cc" \
    -W
```

可以用 LDAPS 来访问 LDAP Server：

```bash
echo "127.0.0.1 alpha-quant.cc" >> /etc/hosts

LDAPTLS_CACERT=$PWD/certs/openldap.crt ldapsearch \
    -H ldaps://alpha-quant.cc:636/ \
    -x \
    -D "cn=admin,dc=alpha-quant,dc=cc" \
    -b "dc=alpha-quant,dc=cc" \
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
    -H ldaps://alpha-quant.cc:636/ \
    -x \
    -S \
    -D "cn=admin,dc=alpha-quant,dc=cc" \
    -W \
    cn=user01,ou=users,dc=alpha-quant,dc=cc
```

用户修改密码

```bash
LDAPTLS_CACERT=$PWD/certs/openldap.crt ldappasswd \
    -H ldaps://alpha-quant.cc:636/ \
    -x \
    -S \
    -D "cn=user01,ou=users,dc=alpha-quant,dc=cc" \
    -W
```

并且 userPassword 也对非 admin 用户被隐藏

## 自助修改密码系统

问题解决，添加命令如下：

``` 
ldapmodify -Y EXTERNAL -H ldapi:/// -f updatepass.ldif
```

AD 自助修改密码 " 是 AD 服务中的一个重要功能，它允许用户通过 Web 界面自主更改自己的密码，无需管理员介入，提高了效率并降低了支持成本

- <https://github.com/ltb-project/self-service-password>
- <https://github.com/alvinsiew/ldap-self-service>

```yaml
services:
  ldap-server:  # https://github.com/osixia/docker-openldap
    image: osixia/openldap:latest
    container_name: ldap_server
    restart: always
    environment:
      - LDAP_ORGANISATION=hello
      - LDAP_DOMAIN=hello.org
      - LDAP_BASE_DN=dc=hello,dc=org
      - LDAP_ADMIN_PASSWORD=bad_pw_123
      - LDAP_RFC2307BIS_SCHEMA=true
      - LDAP_REMOVE_CONFIG_AFTER_SETUP=true
      - LDAP_TLS_VERIFY_CLIENT=never
    ports:
      - "20389:389"
    volumes:
      - ./openldap/var_lib_ldap:/var/lib/ldap
      - ./openldap/etc_ldap_slapd.d:/etc/ldap/slapd.d
    networks:
      - ldap-network

  ldap-manager:  # https://github.com/wheelybird/ldap-user-manager
    image: wheelybird/ldap-user-manager:latest
    container_name: ldap_manager
    restart: always
    environment:
      - LDAP_URI=ldap-server
      - LDAP_BASE_DN=dc=hello,dc=org
      - LDAP_ADMINS_GROUP=admins
      - LDAP_ADMIN_BIND_DN=cn=admin,dc=hello,dc=org
      - LDAP_ADMIN_BIND_PWD=bad_pw_123
      - LDAP_IGNORE_CERT_ERRORS=true
    ports:
      - "20080:80"
      - "20443:443"
    networks:
      - ldap-network

networks:
  ldap-network:
    name: ldap-network
    driver: bridge
```

## 参考资料

- <https://blog.csdn.net/achi010/article/details/130655238>
