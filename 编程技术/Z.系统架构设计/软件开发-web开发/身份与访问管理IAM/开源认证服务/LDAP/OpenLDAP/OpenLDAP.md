## OpenLDAP 简介

- <https://www.openldap.org/>
- <https://git.openldap.org/openldap/openldap>

## 双主搭建

## 自助修改密码系统

问题解决，添加命令如下：

``` 
ldapmodify -Y EXTERNAL -H ldapi:/// -f updatepass.ldif
```

AD 自助修改密码 " 是 AD 服务中的一个重要功能，它允许用户通过 Web 界面自主更改自己的密码，无需管理员介入，提高了效率并降低了支持成本

- <https://github.com/ltb-project/self-service-password>
- <https://github.com/alvinsiew/ldap-self-service>

```yaml
# https://hub.docker.com/r/wheelybird/ldap-user-manager
version: "3"

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

