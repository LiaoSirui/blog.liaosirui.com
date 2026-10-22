- OIDC 上游（Keycloak）

```yaml
    connectors:
    - type: oidc
      id: keycloak
      name: keycloak
      config:
        issuer: https://<KeyCloak URL>
        clientID: XXXXXXX
        clientSecret: yyyyyyyyyyyyyyyyyyyy
        redirectURI: https://<ingress-domain>/dex/callback
        scopes:
        - openid
        - profile
        - email
        insecureSkipEmailVerified: true
        insecureEnableGroups: true
        insecureSkipVerify: true
        userIDKey: email
        userNameKey: email
```

- AD 域上游

```yaml
connectors:
- type: ldap
  name: ActiveDirectory
  id: ad
  config:
    host: ad.example.com:636

    insecureNoSSL: false
    insecureSkipVerify: true

    bindDN: Administrator@example.com
    bindPW: xxx

    usernamePrompt: Email Address

    userSearch:
      baseDN: cn=Users,dc=example,dc=com
      filter: "(objectClass=person)"
      username: sAMAcountNameß
      idAttr: sAMAcountNameß
      emailAttr: userPrincipalName
      nameAttr: sAMAcountNameß
      prefferdUserNameAttr: displayName

    groupSearch:
      baseDN: DC=example,DC=com
      filter: "(objectClass=group)"
      userMatchers:
      - userAttr: DN
        groupAttr: member
      nameAttr: cn
```



## 参考文档

- <https://docs.trilio.io/kubernetes/advanced-configuration/management-console/oidc-ldap-and-openshift-authentication>