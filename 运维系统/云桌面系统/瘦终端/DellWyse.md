## Dell 升级固件

这里以 Dell Wyse 5070 Thin Client 为例：<https://www.dell.com/support/home/zh-cn/product-support/product/wyse-5070-thin-client/drivers>

- 适用于戴尔 Wyse 5070 瘦客户端的 ThinOS 2402 （9.5.1079） Merlin Image 文件：带有 Merlin 字样的是线刷包，用 USB 工具刷，其余的支持 FTP/Web 远程刷

- ThinOS 9.1.3129 或更高版本到 ThinOS 2402 （9.5.1079） Upgrade Image 文件：小版本升级包

启动盘制作过程：

- 在 PC 上安装 USB Imaging Tools 工具
- 在 Dell 官方网站下载对应的 OS 镜像文件到 PC 上，注意使用 U 盘部署，一定要下载带有 "Merlin" 标识的镜像文件
- 在 PC 上打开，并解压缩下载的镜像文件，双击打开 “WIOSPcoIP_Wyse_5070_Thin_Client_16GB_0” 文件夹，找到格式为 RSP 的文件；在 RSP 文件上点击鼠标右键，选择使用记事本方式打开，在此文件中按下 "Ctrl+H", 然后全局搜索 “FFFFFFFF"替换为"00000000", 选择" 全部替换 "，点击全部替换后关闭，并保存此修改后的文件

- 然后在文件夹目录中找到 "CommandsXml.xml" 文件，在 "CommandsXml.xml" 文件上点击鼠标右键，选择使用记事本方式打开，在此文件中按下 "Ctrl+H"，然后全局搜索 “FFFFFFFF"替换为"00000000", 选择" 全部替换 "，点击全部替换后关闭，并保存此修改后的文件。

- 在 PC 上插入 U 盘，格式化为 FAT 格式，并打开 "USB Imaging Tools" 工具；在左侧 "Available drive" 上选择要制作并且已经格式化 U 盘的盘符，然后在右边选择 "Image Push"；在 "Select OS architecture" 这里选择 64bit，然后选择下面的 "+Add a new image"；找到我们之前修改的 `.rsp` 格式文件，点击打开；点击右下角的 "Configure USB Drive"，开始制作 U 盘并等待

- 进程走完会提示成功，表示 U 盘启动已经制作成功，拔下 U 盘即可

远程更新：

- 使用 FTP 服务器功能升级映像
- Wyse 管理套件 WMS

## WMS

Wyse Management Suite (WMS) 是下一代瘦客户端管理软件，允许组织集中配置、监控、管理和优化您的设备

Wyse Management Suite 提供以下版本：

- 标准（免费）— Wyse Management Suite 的标准版提供基本功能，仅用于私有云部署。无需许可证密钥便可使用标准版。此版本只能管理 Dell 瘦客户端。标准版适合中小型企业
- Pro（付费） — Wyse Management Suite 的 Pro 版是更稳健的解决方案。它可用于公有云和私有云部署。使用 Pro 版本需要许可证密钥（基于订阅的许可）。利用 Pro 解决方案，如果需要，组织能够采用介于私有云与公有云之间的混合型号和浮动许可证。此版本是管理任何基于 Teradici 的设备、基于 Wyse Covert for PC 的瘦客户端、Dell 混合客户端设备、嵌入式 PC 和边缘网关设备所必需的。它还提供更多高级功能来管理 Dell 瘦客户端。对于公有云部署，Pro 版本可以在非公司网络上进行管理（例如家庭办公、第三方、合作伙伴、移动瘦客户端等）

直接DELL官网下载最新版，下载地址：<https://www.dell.com/support/home/zh-cn/product-support/product/wyse-wms/drivers>

安装和初始化：

- IE 增强安全配置要求关闭

  ![image-20250731151450837](./.assets/DellWyse/image-20250731151450837.png)

- 下载后直接安装，右键用管理员权限运行安装程序。典型安装就好，按照提示输入自有创建的数据库密码，邮箱，登录密码，注意数据库密码尽量不要带有特殊字符。设置好之后，自动安装。（Server 2016 和 Server 2019 都支持，不能安装 IIS。）建议是安装在非 C 盘。

- 安装完成后，会自动启动浏览器，输入账户和密码，初始化，选择中文语言。许可证选择标准版（免费的），邮件警报，证书就不用管，设备注册验证默认勾选。

- 仪表盘，和公有云试用版一样。组注册密钥记录下来，瘦客户机那边等会需要设置。

瘦客户机如何注册到管理控制台：进入瘦客户机之后，设置，集中配置，填写组注册密钥和WMS服务器地址，并验证，（没有 CA 可以取消勾选底部 Enable CA Validation）通过后会提示：“已签入 WMS 服务器！”，按确定即可，瘦客户机这端配置完成。返回 WMS 管理控制台，登陆后可以看到设备已经注册到 WMS 控制台，并处于注册待定状态。找到该设备勾选，验证注册。
