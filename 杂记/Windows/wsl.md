## wsl 端口转发

打开 PowerShell，添加端口转发：

```powershell
netsh interface portproxy add v4tov4 listenport=80 connectaddress=172.19.155.182 connectport=80 listenaddress=* protocol=tcp 
```

如果删除端口转发，执行：

```powershell
netsh interface portproxy delete v4tov4 listenport=80 protocol=tcp
```

## wsl 资源配置

按下 Windows + R 键，输入 %UserProfile% 并运行进入用户文件夹，新建文件 `.wslconfig`，文件内容格式如下

```json
[wsl2]
memory=2048MB # 限制最大使用内存
swap=2G       # 限制最大使用虚拟内存
processors=1  # 限制最大使用cpu个数
localhostForwarding=true
```

然后运行cmd，输入 `wsl --shutdown` 来关闭当前的子系统，重新运行 `bash` 进入子系统