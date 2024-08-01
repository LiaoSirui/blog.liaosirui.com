一般会习惯性地以为，用 root 用户登录服务器之后就可以为所欲为：修改所有的文件、随便修改网络配置、监视各个进程的内存等等。但其实真正赋予这些敏感权限的并不是 root 这个用户，而是叫做 capability 的 feature

capability 以分组的方式拆分了 root 用户的各种权限，以便我们基于场景以更小的粒度对不同的进程进行赋权。使用 getcap 或者 setcap 命令查看可执行文件所拥有的的 capability

比如说，想要修改路由表，需要 CAP_NET_ADMIN，想要使用 chown 命令修改文件的归属，需要 CAP_CHOWN……；使用命令 man capabilities 可以查看完整的 man page

查看进程拥有什么 capability：

```bash
getpcaps PID
```