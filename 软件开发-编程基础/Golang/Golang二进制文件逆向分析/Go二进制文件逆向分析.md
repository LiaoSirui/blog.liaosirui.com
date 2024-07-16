Go 语言的编译工具链会全静态链接构建二进制文件，把标准库函数和第三方 package 全部做了静态编译，再加上 Go 二进制文件中还打包进去了 runtime 和 GC(Garbage Collection，垃圾回收) 模块代码，所以即使做了 strip 处理( `go build -ldflags "-s -w"` )，生成的二进制文件体积仍然很大。在反汇编工具中打开 Go 语言二进制文件，可以看到里面包含动辄几千个函数。再加上 Go 语言的独特的函数调用约定、栈结构和多返回值机制，使得对 Go 二进制文件的分析，无论是静态逆向还是动态调式分析，都比分析普通的二进制程序要困难很多

参考文档：

- <https://www.anquanke.com/post/id/214940>
- <https://jiayu0x.com/2020/08/28/go-binary-reverse-engineering-metainfo-symbols-and-srcfile-path/>

- <https://jiayu0x.com/2020/09/02/go-binary-reverse-engineering-types/>
- <https://jiayu0x.com/2020/09/25/go-binary-reverse-engineering-itab-and-strings/>
- <https://jiayu0x.com/2020/09/28/go-binary-reverse-engineering-tips-and-example/>