## 连接 Console

直接在终端上，输入命令 `screen /dev/cu.usbserial-xxxxxx 9600` 其中9600是波特率

如果需要跳出，就要用 `ctrl -`

需要重新连接，先找到原来的连接 `screen -ls` 然后用 `screen -r 16582`，16582 为通过前面命令查看到的连接的数字

## 重启终端密码

长按（6秒以上）PNP键，使交换机恢复出厂配置并自动重新启动

- S200，S1700，S5700交换机忘记密码怎么办？如何修改或清除密码？<https://support.huawei.com/enterprise/zh/doc/EDOC1100197181>

### bootrom 密码

V100R003C00：9300

V100R005C01：huawei

V100R006C00–V100R006C03：框式交换机为 9300，盒式为 huawei

V100R006C05：`Admin@huawei.com`

V200R001C00–V200R0012C00及之后版本：`Admin@huawei.com`

### Console 口密码

对于 V200R010C00 之前版本，使用 Console 口首次登录设备时没有缺省密码，首次登录时的界面会提示用户配置 Console 口登录密码

对于 V200R010C00-V200R019 版本，使用 Console 口登录设备的缺省用户名为`admin`，缺省密码为`admin@huawei.com`

对于 V200R020 版本，使用 Console 口首次登录设备时没有缺省密码，首次登录时的界面会提示用户配置 Console 口登录密码

## 参考资料

- <https://blog.csdn.net/weixin_39137153/article/details/126898949>