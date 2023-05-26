## mkcert 简介

平时在本地开发时，有时会要求通过 HTTPS 请求来访问。一个通用的做法是用 OpenSSL 生成自签证书，然后对 Web 服务进行配置。但 OpenSSL 的命令比较繁琐，参数也比较复杂，用起来不够方便，一个替代方案：mkcert

`mkcert` 是 GO 编写的，一个简单的零配置的用来生成自签证书的工具；`mkcert` 自动生成并安装一个本地 CA 到 root stores，并且生成 locally-trusted 证书

官方：

- GitHub 仓库：<https://github.com/FiloSottile/mkcert>

## mkcert 安装

```bash
# refer: https://github.com/FiloSottile/mkcert/releases

export INST_MKCERT_VERSION=v1.4.4

curl -sL "https://github.com/FiloSottile/mkcert/releases/download/${INST_MKCERT_VERSION}/mkcert-${INST_MKCERT_VERSION}-linux-amd64" \
    -o /usr/local/bin/mkcert-${INST_MKCERT_VERSION}
chmod +x /usr/local/bin/mkcert-${INST_MKCERT_VERSION}
update-alternatives --install /usr/bin/mkcert mkcert /usr/local/bin/mkcert-${INST_MKCERT_VERSION} 1
alternatives --set mkcert /usr/local/bin/mkcert-${INST_MKCERT_VERSION}
```

## mkcert 使用

示例：

```bash
mkcert -install

mkcert example.com "*.example.com" example.test localhost 127.0.0.1 ::1

ncat -lvp 1589 --ssl-key example.com+5-key.pem --ssl-cert example.com+5.pem
```

mkcert 生成证书的命令很简单，格式如下：

```bash
mkcert domain1 [domain2 [...]]
```

多个域名/IP用空格分隔，一个自签名的证书可以这样创建：

```bash
mkcert 192.168.128.134 example.com localhost 127.0.0.1 ::1
```

在这个证书中，192.168.128.134 是服务器的内网地址。命令执行后会生成两个文件：`192.168.128.134+4-key.pem` 和 `192.168.128.134+4.pem`，前者是私钥，后者是证书

CA 文件的位置，可以通过 `mkcert -CAROOT` 来打印这个目录位置

```bash
> mkcert -CAROOT
/root/.local/share/mkcert
```



