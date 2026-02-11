添加如下的属性映射，修改邮箱

```python
email = ldap.get("mail")
username = ldap.get("uid")
if email is None:
    return {
      "email": [f"{username}@alpha-quant.tech"]
    }
return {
    "email": [m.replace("@ad.alpha-quant.tech", "@alpha-quant.tech") for m in email],
}
# return {
#     "email": ldap.get("mail"),
# }
```
