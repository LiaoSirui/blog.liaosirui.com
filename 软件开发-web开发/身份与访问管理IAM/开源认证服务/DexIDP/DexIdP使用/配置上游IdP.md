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

## 参考文档

- <https://docs.trilio.io/kubernetes/advanced-configuration/management-console/oidc-ldap-and-openshift-authentication>