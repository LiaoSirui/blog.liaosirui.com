无法使用 M.2 NVMe SSD 作为系统盘

遇到这个问题是因为主板的 UEFI/BIOS 不支持 NVMe, 没有驱动导致的

解决方法：

- 更新最新固件：在新版 BIOS 可能会添加 NVMe 驱动，提供支持。
- 自行将 NVMe 驱动注入到固件
- 从其他可引导设备启动，载入 NVMe 驱动，引导进入

在硬盘上面划分一个 200M 的空间，COLVER 放在里面，然后 BIOS 从这个系统引导

Clover 配置 `config.plist` 如下：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Boot</key>
	<dict>
		<key>DefaultVolume</key>
		<string>EFI</string>
		<key>DefaultLoader</key>
		<string>\EFI\BOOT\BOOTX64.efi</string>
		<key>Fast</key>
		<true/>
	</dict>
	<key>GUI</key>
	<dict>
		<key>Custom</key>
		<dict>
			<key>Entries</key>
			<array>
				<dict>
					<key>Disabled</key>
					<false/>
					<key>Hidden</key>
					<false/>
					<key>Volume</key>
					<string>EFI</string>
					<key>Path</key>
					<string>\EFI\BOOT\BOOTX64.efi</string>
					<key>Title</key>
					<string>ESXI 8</string>
				</dict>
			</array>
		</dict>
	</dict>
</dict>
</plist>
```

