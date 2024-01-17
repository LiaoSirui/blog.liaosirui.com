## eCryptfs 简介

eCryptfs 是在 Linux kernel 实现的一个加密文件系统，在 Linux kernel 2.6.19 版本收纳入官方 Linux kernel。它采用堆叠式的设计思想，逻辑上位于 VFS 和传统文件系统之间。用户应用程序对传统文件系统的读写操作，经过系统调用通过 VFS 首先被 eCryptfs 截获，eCryptfs 对文件数据进行加解密的操作，再转发给传统文件系统，为应用提供透明、动态、高效的加密功能。

eCryptfs 对每个文件采用不同的文件加密密钥 ( File Encryption Key, FEK )，文件加密算法推荐使用 AES-128。FEK 不能以明文的形式存放，eCryptfs 使用用户提供的口令（Passphrase）、非对称密钥算法（如 RSA 算法）或 TPM（Trusted Platform Module）的公钥来加密保护 FEK。

例如，当使用用户口令的时候，口令先经 hash 函数处理，再做为密钥加密 FEK。口令/公钥称为文件加密密钥加密密钥（File Encryption Key Encryption Key，FEFEK），加密后的 FEK 则称为加密文件密钥（Encrypted File Encryption Key，EFEK )。如果一个文件被多个授权用户访问，则有多份 EFEK。 此外，eCryptfs 还支持文件名的加密

## 参考资料

- <https://blog.didiyun.com/index.php/2018/12/18/ecryptfs/>