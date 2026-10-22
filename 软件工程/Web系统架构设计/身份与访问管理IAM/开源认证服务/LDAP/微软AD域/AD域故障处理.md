## sysvol

`sysvol` is not properly replicated between your AD DCs

用来存储域公共文件服务器副本的共享文件夹，例如我们用得最多的组策略设置、脚本等都是存在这个共享目录中的。如果组织内有多台域控制器，那么它们就在域中所有的域控制器之间通过 FRS 服务相互复制

`C:\Windows\SYSVOL\sysvol`

执行 `dcdiag /v`  目录服务器诊断故障源

查询 state 结果会罗列出所有 DC 的 SYSVOL 同步状态，0 = Uninitialized，1 = Initialized，2 = Initial Sync，3 = Auto Recovery，4 = Normal，5 = In Error

```bash
For /f %i IN ('dsquery server -o rdn') do @echo %i && @wmic /node:"%i" /namespace:\\root\microsoftdfs path dfsrreplicatedfolderinfo WHERE replicatedfoldername='SYSVOL share' get replicationgroupname,replicatedfoldername,state
```

其中 AD 是正常，AD-1 和 AD-2 异常，打开 ADSI Edit

```bash
DC=corp,DC=com >> OU=Domain Controllers >> CN=AD >> CN=DFSR-LocalSettings >> Domain System Volume >> SYSVOL Subscription
```

最后这个右键点击它修改属性，找到 msDFSR-Enabled 把它的值由 True 改成 False，把 msDFSR-options 把它的值由 0 或 not set 改成 1。这里改成 1 的意思就是把它设为了权威，注意这里选择的 DC2，这是我的 PDC。改成 False 的意思就是停止了自动复制模式，改为手动模式

然后继续在 ADSI Edit 里把 AD1 和 AD2 的 msDFSR-Enabled 把它的值由 True 改成 False，msDFSR-options 不用改，因为权威只能有一个

进入 AD，打开 ADSI Edit，将 AD 的 msDFSR-Enabled 由 False 改成 True

执行（powershell）

```
repadmin /kcc
repadmin /syncall /e
repadmin /syncall /e /P
Net Stop Netlogon
Net Start Netlogon
IPconfig /registerdns
```

运行 `dfsrdiag PollAD` 命令更新 DFRS 全局状态，期待的结果为显示“Operation Succeeded”

如提示说系统没有这个命令，就在 PowerShell 里面运行 `Add-WindowsFeature RSAT-DFS-Mgmt-Con` 来安装一下它

在 ADSI Edit 里把 AD1 和 AD2 的 msDFSR-Enabled 把它的值由 False 改成 True，再次运行上面的 powershell 语句，然后再运行 `dfsrdiag PollAD`

参考资料：

- <https://bobwang1.wordpress.com/2021/07/30/%E8%A7%A3%E5%86%B3dc%E4%B8%A2%E5%A4%B1sysvol%E5%92%8Cnetlogon%E5%85%B1%E4%BA%AB%E4%BB%A5%E5%8F%8A%E5%90%8C%E6%AD%A5%E5%8A%9F%E8%83%BD%E5%87%BA%E7%8E%B0%E9%9A%9C%E7%A2%8D%E7%9A%84%E4%B8%80%E7%B3%BB/>