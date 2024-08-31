Git Config 配置如下：

```ini
[user]
    email = cyril@liaosirui.com
    name = LiaoSirui

[core]
    quotepath = false
    editor = vim
    longpaths = true

[commit]
    template = /root/.git-config/commit-template

[merge]
    defaultToUpstream = true

[filter "lfs"]
    clean = git-lfs clean -- %f
    smudge = git-lfs smudge -- %f
    process = git-lfs filter-process
    required = true

```

