## Wine 简介

Wine （“Wine Is Not an Emulator” 的首字母缩写）是一个能够在多种 POSIX-compliant 操作系统（诸如 Linux，macOS 及 BSD 等）上运行 Windows 应用的兼容层。Wine 不是像虚拟机或者模拟器一样模仿内部的 Windows 逻辑，而是將 Windows API 调用翻译成为动态的 POSIX 调用，免除了性能和其他一些行为的内存占用，让你能够干净地集合 Windows 应用到你的桌面

Wine 一直是一个开源的项目，但也有一个收费的版本（CrossOver），作为 wine 持续运行的支持

源代码：<https://gitlab.winehq.org/wine/wine>

## Wine 初始化

Wine 额外的运行 Runtime：

- wine-mono 是一个开源项目，旨在为 Wine（一款在类 Unix 操作系统上运行 Windows 应用程序的兼容层）提供对 Microsoft 的.NET Framework 和 Mono 框架的支持。具体来说，wine-mono 是一个跨平台的兼容库，它使得基于 `.NET` 平台的应用程序能够在非微软操作系统（如 Linux、macOS 等）上正常运行。

- Wine Gecko 是 Wine 从 Mozilla 借用的 HTML 页面排版渲染引擎，用于在 Wine 里模拟 Internet Explorer，以便正常打开网页，尤其是一些将浏览器嵌入的应用。

Wine 在初次安装并在终端输入 winecfg 后，会自动下载安装 wine-mono 和 wine-gecko 两个插件，但是自动下载会很慢，而且还不一定能下载成功，因此最好选择手动下载。下载地址：

- <http://mirrors.ustc.edu.cn/wine/wine/wine-mono/>
- <http://mirrors.ustc.edu.cn/wine/wine/wine-gecko>

```bash
wget https://mirrors.ustc.edu.cn/wine/wine/wine-mono/9.2.0/wine-mono-9.2.0-x86.msi
wget https://mirrors.ustc.edu.cn/wine/wine/wine-gecko/2.47.4/wine-gecko-2.47.4-x86_64.msi
```

下载之后，打开终端，进入文件所下载的目录，执行

```bash
wine start /i wine-mono-5.0.0-x86.msi
```

随后验证一下是否安装成功。终端打开 winetricks：

```bash
winetricks
# apt install winetricks
```

