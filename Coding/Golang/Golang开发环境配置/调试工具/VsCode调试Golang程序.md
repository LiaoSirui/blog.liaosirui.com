打开 main.go 开始调试

快捷键：

- F5  开始调试，如果没有编译错误可以看到，变量显示，调用堆栈的显示还是非常清晰的
- F10 单步
- F11 进入函数

launch.json 示例

```json
{
    // 使用 IntelliSense 了解相关属性。 
    // 悬停以查看现有属性的描述。
    // 欲了解更多信息，请访问: https://go.microsoft.com/fwlink/?linkid=830387
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Debug Package",
            "type": "go",
            "request": "launch",
            // "mode": "auto",
            "mode": "debug",
            "program": "${fileDirname}/../lib/dex/cmd/dex/",
            "env": {},
            "args": [],
            "cwd": "${fileDirname}/../lib/dex",
            "buildFlags": "",
            "showGlobalVariables": false
        }
    ]
}

```

mode 需要更改为 debug，如果为 auto 时，F5 启动调试时：

- 如果当前文件是单元测试，便会执行当前包中所有的单元测试文件，即 mode 切换至 test
- 如果当前文件 `*.go`，才会执行 `main.go`，即 mode 切换至 debug
