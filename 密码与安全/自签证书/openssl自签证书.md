## 准备证书目录

进入证书目录

```bash
mkdir gen-certs && cd gen-certs
```

## 创建 CA 证书

生成 CA 私钥：

```bash
openssl genpkey \
    -algorithm RSA \
    -out ca-key.pem \
    -pkeyopt rsa_keygen_bits:2048
```

生成 CA 证书：

```bash
openssl req \
    -x509 -new -nodes \
    -key ca-key.pem -sha256 \
    -days 36500 \
    -out ca-cert.pem \
    -subj "/C=CN/ST=Sichuan/L=Chengdu/O=AlphaQuant Trust Services/CN=alpha-quant.tech"
```

## 签发泛域名证书

生成服务器私钥：

```bash
openssl genpkey \
    -algorithm RSA \
    -out server-key.pem \
    -pkeyopt rsa_keygen_bits:2048
```

创建证书签名请求 (CSR)， 创建一个配置文件 `server.csr.cnf`：

```ini
[req]
default_bits       = 2048
prompt             = no
default_md         = sha256
distinguished_name = dn

[dn]
C  = CN
ST = Sichuan
L  = Chengdu
O  = AlphaQuant Trust Services
CN = alpha-quant.tech

```

然后生成 CSR：

```bash
openssl req \
    -new \
    -key server-key.pem \
    -out server.csr \
    -config server.csr.cnf
```

创建证书扩展文件，创建一个配置文件 `server.ext`：

```ini
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth,clientAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = *.alpha-quant.tech
DNS.2 = alpha-quant.tech

```

签署服务器证书：

```bash
openssl x509 -req \
    -in server.csr \
    -CA ca-cert.pem \
    -CAkey ca-key.pem \
    -CAcreateserial \
    -out server-cert.pem \
    -days 36500 \
    -sha256 \
    -extfile server.ext \
    -subj "/C=CN/ST=Sichuan/L=Chengdu/O=AlphaQuant Trust Services/CN=*.alpha-quant.tech"
```
