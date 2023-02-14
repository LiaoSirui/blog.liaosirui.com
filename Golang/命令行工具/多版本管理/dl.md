## 多版本管理简介

官方的 Go 多版本管理，也是升级 Go 的方式：

```bash
> go get golang.org/dl/go1.19.5

> go1.19.5 download
Downloaded   0.0% (    16384 / 148949578 bytes) ...
Downloaded  25.7% ( 38305792 / 148949578 bytes) ...
Downloaded  50.6% ( 75399152 / 148949578 bytes) ...
Downloaded 100.0% (148949578 / 148949578 bytes)
Unpacking /root/sdk/go1.19.5/go1.19.5.linux-amd64.tar.gz ...
Success. You may now run 'go1.19.5'

> go1.19.5 version
```

### 为什么需要多个 Go 版本

以下一些场景，可能会希望有多版本：

- 一般为了稳定，线上版本通常不会激进升级到最新版本，但你本地很可能想试用新版本的功能，这时候就希望能方便的支持多版本；
- 为了测试或重现特定的问题，希望能够在特定的版本进行，这是为了避免不同版本干扰。

### 官方多版本的使用方式

安装某个版本的 Go，跟一般 Go 包安装一样，执行 go get 命令：

```bash
# 其中 <version> 替换为你希望安装的 Go 版本

go get golang.org/dl/go<version>		
```

这一步，只是安装了一个特定 Go 版本的包装器，真正安装特定的 Go 版本，还需要执行如下命令：

```bash
# 和上面一样，<version> 是具体的版本
go<version> download			
```

几个注意的点：

- 有一个特殊的版本标记：`gotip`，用来安装最新的开发版本；
- 因为 golang.org 访问不了，你应该配置 GOPROXY（所以，启用 Module 是必须的）；
- 跟安装其他包一样，go get 之后，go1.19.5 这个命令会被安装到 `$GOBIN` 目录下，默认是 `~/go/bin` 目录，所以该目录应该放入 PATH 环境变量；
- 没有执行 download 之前，运行 go1.19.5，会提示 `go1.19.5: not downloaded. Run 'go1.19.5 download' to install to ~/sdk/go1.19.5`；

## 原理

拉取 golang 源码仓库 <https://go.googlesource.com/dl>

```bash
git clone https://go.googlesource.com/dl
```

也可以从 GitHub 获取：<https://github.com/golang/dl>

查看该仓库代码，发现一堆以各个版本命名的目录：

```bash
> tree -L 1 . | head -30 
.
...
├── go.mod
├── go1.10
├── go1.10.1
├── go1.10.2
├── go1.10.3
├── go1.10.4
├── go1.10.5
├── go1.10.6
├── go1.10.7
├── go1.10.8
...
```

可见，每次发布新版本，都需要往这个仓库增加一个对应的版本文件夹。

这里以 go1.19.5 为例，看看里面包含什么文件：

```bash
> cd go1.19.5

> tree -L 1 .          
.
└── main.go
```

该目录中仅包含了一个 `main.go` 文件，内容如下：（gotip 的内容不一样，它调用的是 `version.RunTip()`）

```go
# ...
package main

import "golang.org/dl/internal/version"

func main() {
	version.Run("go1.19.5")
}

```

所以，关键在于 `internal/version` 包的 Run 函数（不同版本，version 参数不同）。注意以下代码我给的注释：

```go
// Run runs the "go" tool of the provided Go version.
func Run(version string) {
	log.SetFlags(0)

  // goroot 获取 go 安装的目录，即 ~/sdk/go<version>
	root, err := goroot(version)
	if err != nil {
		log.Fatalf("%s: %v", version, err)
	}

  // 执行下载操作
	if len(os.Args) == 2 && os.Args[1] == "download" {
		if err := install(root, version); err != nil {
			log.Fatalf("%s: download failed: %v", version, err)
		}
		os.Exit(0)
	}

  // 怎么验证是否已经下载好了 Go？在下载的 Go 中会创建一个 .unpacked-success 文件，用来指示下载好了。
	if _, err := os.Stat(filepath.Join(root, unpackedOkay)); err != nil {
		log.Fatalf("%s: not downloaded. Run '%s download' to install to %v", version, version, root)
	}

  // 运行下载好的 Go
	runGo(root)
}
```

这里主要是下载和运行 Go。

### 下载 Go

先看下载、安装 Go

当执行 `go1.19.5 download` 时，会运行 install 函数

```go
...
	if len(os.Args) == 2 && os.Args[1] == "download" {
		if err := install(root, version); err != nil {
			log.Fatalf("%s: download failed: %v", version, err)
		}
		os.Exit(0)
	}
...
```

查看该函数发现，它调用了 `versionArchiveURL` 函数获取要下载的 Go 的 URL：

```go
// directory as needed.
func install(targetDir, version string) error {
	if _, err := os.Stat(filepath.Join(targetDir, unpackedOkay)); err == nil {
		log.Printf("%s: already downloaded in %v", version, targetDir)
		return nil
	}

	if err := os.MkdirAll(targetDir, 0755); err != nil {
		return err
	}
	goURL := versionArchiveURL(version)
  res, err := http.Head(goURL)
	if err != nil {
		return err
	}
  if res.StatusCode == http.StatusNotFound {
		return fmt.Errorf("no binary release of %v for %v/%v at %v", version, getOS(), runtime.GOARCH, goURL)
	}
	if res.StatusCode != http.StatusOK {
		return fmt.Errorf("server returned %v checking size of %v", http.StatusText(res.StatusCode), goURL)
	}
  ...
```

`versionArchiveURL` 从 [https://dl.google.com](https://dl.google.com/) 下载 Go 包，最终的包是一个归档文件会放到 `~/sdk/go1.19.5` 目录下。

```go
// versionArchiveURL returns the zip or tar.gz URL of the given Go version.
func versionArchiveURL(version string) string {
	goos := getOS()

	ext := ".tar.gz"
	if goos == "windows" {
		ext = ".zip"
	}
	arch := runtime.GOARCH
	if goos == "linux" && runtime.GOARCH == "arm" {
		arch = "armv6l"
	}
	return "https://dl.google.com/go/" + version + "." + goos + "-" + arch + ext
}
```

之后通过 sha256 验证文件的完整性（因为服务端放了 sha256 校验文件），最后解压缩，并创建上面说的 `.unpacked-success` 空标记文件。这样这个版本的 Go 就安装成功了。

```bash
...
	base := path.Base(goURL)
	archiveFile := filepath.Join(targetDir, base)
	if fi, err := os.Stat(archiveFile); err != nil || fi.Size() != res.ContentLength {
		if err != nil && !os.IsNotExist(err) {
			// Something weird. Don't try to download.
			return err
		}
		if err := copyFromURL(archiveFile, goURL); err != nil {
			return fmt.Errorf("error downloading %v: %v", goURL, err)
		}
		fi, err = os.Stat(archiveFile)
		if err != nil {
			return err
		}
		if fi.Size() != res.ContentLength {
			return fmt.Errorf("downloaded file %s size %v doesn't match server size %v", archiveFile, fi.Size(), res.ContentLength)
		}
	}
	wantSHA, err := slurpURLToString(goURL + ".sha256")
	if err != nil {
		return err
	}
	if err := verifySHA256(archiveFile, strings.TrimSpace(wantSHA)); err != nil {
		return fmt.Errorf("error verifying SHA256 of %v: %v", archiveFile, err)
	}
	log.Printf("Unpacking %v ...", archiveFile)
	if err := unpackArchive(targetDir, archiveFile); err != nil {
		return fmt.Errorf("extracting archive %v: %v", archiveFile, err)
	}
	if err := ioutil.WriteFile(filepath.Join(targetDir, unpackedOkay), nil, 0644); err != nil {
		return err
	}
	log.Printf("Success. You may now run '%v'", version)
	return nil
}
```

注意，gotip 的下载是通过 git 获取源码的方式进行的，它会通过源码构建安装最新的 gotip 版本。具体逻辑在 `internal/version/gotip.go` 中。

### 运行

因为下载的 Go 是预编译好的，因此可以直接使用。

但是它将 Go 下载到了 `~/sdk/go<version>` 目录下，因为并没有将这个目录的 bin 目录加入 PATH，因此直接 go 命令运行的还是之前的版本，而不是刚安装的 go1.19.5。

上文说了，go1.19.5 只是一个包装器。当对应的 go1.19.5 安装成功后，再次运行 go1.19.5，会执行 internal/version/version.go 中的 runGo(root) 函数。

```go
func runGo(root string) {
	gobin := filepath.Join(root, "bin", "go"+exe())
	cmd := exec.Command(gobin, os.Args[1:]...)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	newPath := filepath.Join(root, "bin")
	if p := os.Getenv("PATH"); p != "" {
		newPath += string(filepath.ListSeparator) + p
	}
	cmd.Env = dedupEnv(caseInsensitiveEnv, append(os.Environ(), "GOROOT="+root, "PATH="+newPath))

	handleSignals()

	if err := cmd.Run(); err != nil {
		// TODO: return the same exit status maybe.
		os.Exit(1)
	}
	os.Exit(0)
}
```

该函数通过 os/exec 包运行 `~/sdk/go1.19.5/bin/go` 命令，并设置好响应的标准输入输出流等，同时为新运行的进程设置好相关环境变量，可以认为，执行 go1.19.5，相当于执行 `~/sdk/go1.19.5/bin/go`。

所以，go1.19.5 这个命令，一直都只是一个包装器。如果你希望新安装的 go1.19.5 成为系统默认的 Go 版本，即希望运行 go 运行的是 go1.19.5，方法有很多：

- 将 `~/sdk/go1.19.5/bin/go` 加入 PATH 环境变量（替换原来的）；
- 做一个链接，默认 go 执行 go1.19.5（推荐这种方式），不需要频繁修改 PATH；
- 移动 go1.19.5 替换之前的 go（不推荐）；

