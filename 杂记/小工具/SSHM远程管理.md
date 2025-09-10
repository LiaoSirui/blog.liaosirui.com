SSHM - SSH Manager

- <https://github.com/Gu1llaum-3/sshm>

启动 SSHM 后，快捷键：

- • `↑/↓` 或 `j/k`：浏览主机列表
- • `Enter`：连接到选定的主机
- • `a`：添加新主机
- • `e`：编辑选定主机
- • `d`：删除选定主机
- • `/`：搜索和过滤主机
- • `s`：切换排序方式
- • `q`：退出程序

SSHM 使用现代的 Go 技术栈构建：

- Cobra：命令行框架，提供优雅的 CLI 接口
- Bubble Tea：TUI 框架，负责终端界面渲染
- Bubbles：TUI 组件库，提供表格、表单等组件
- Lipgloss：样式库，让界面更加美观