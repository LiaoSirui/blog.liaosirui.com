
按下 Windows + R 键，输入 %UserProfile% 并运行进入用户文件夹，新建文件 `.wslconfig`，文件内容格式如下

```json
[wsl2]
memory=2048MB # 限制最大使用内存
swap=2G       # 限制最大使用虚拟内存
processors=1  # 限制最大使用cpu个数
localhostForwarding=true
```

然后运行cmd，输入 `wsl --shutdown` 来关闭当前的子系统，重新运行 `bash` 进入子系统
