## 创建只读账号

菜单中选择“系统管理” 栏目，展开界面后点击”用户和组”，选择域”`vsphere.local`”（这个域可能在创建 vCenter 的时候会有所不同，总之不要选择 locals），添加用户

![image-20250516130910763](./.assets/vCenter/image-20250516130910763.png)

将用户添加到组 ReadOnlyUsers 中完成授权

![image-20250516131359879](./.assets/vCenter/image-20250516131359879.png)