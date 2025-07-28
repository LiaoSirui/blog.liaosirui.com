每个命令行 session 都有运行独立的 ssh-agent，如果这个 session 一直开着，并且之前已经有老的 key 加入，哪怕更新了 config 文件，后续还是使用内存里已存在的 key，所以导致一直验证失败

查看当前使用的密钥列表

```bash
ssh-add -l
```

手动删除 ssh-agent 里的 key

```bash
# 删除老的 key
ssh-add -d ~/.ssh/id_rsa
# 显示
# Identity removed: ./id_rsa RSA

# 手动加新 key
ssh-add ~/.ssh/id_rsa_new

# 或者全部删掉, 大写 D
ssh-add -D
```

如果不想手动删的话，可以直接关掉当前 session 的 agent，再重开就可以了

```bash
eval "$(ssh-agent -s)"
# Agent pid 20654
# 然后杀进程
kill -9 20654

# 启动 agent
eval `ssh-agent -s`
```

