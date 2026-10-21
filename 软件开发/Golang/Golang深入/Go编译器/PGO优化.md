## Golang PGO

Go 1.21 中的 PGO 支持已准备好用于生产，文档 <https://go.dev/doc/pgo>

当构建 Go 二进制文件时，Go 编译器会执行优化，尝试生成性能最佳的二进制文件。例如，常量传播可以在编译时计算常量表达式，从而避免运行时成本。逃逸分析避免了本地范围对象的堆分配，从而避免了 GC 开销。内联将简单函数的主体复制到调用者中，通常可以在调用者中进行进一步优化（例如额外的常量传播或更好的逃逸分析）。去虚拟化将对类型可以静态确定的接口值的间接调用转换为对具体方法的直接调用（这通常可以实现调用的内联）。

Go 在各个版本之间不断改进优化，但这样做并不是一件容易的事。有些优化是可调的，但编译器不能在每次优化时都“调至 11”，因为过于激进的优化实际上会损害性能或导致构建时间过长。其他优化要求编译器对函数中的“常见”和“不常见”路径做出判断。编译器必须基于静态启发法做出最佳猜测，因为它无法知道哪些情况在运行时会常见

由于没有关于如何在生产环境中使用代码的明确信息，编译器只能对包的源代码进行操作。但确实有一个评估生产行为的工具：分析。如果向编译器提供配置文件，它可以做出更明智的决策：更积极地优化最常用的函数，或更准确地选择常见情况

使用应用程序行为配置文件进行编译器优化称为配置文件引导优化 (PGO)（也称为反馈定向优化 (FDO)）

## 示例

### 示例服务

建一个将 Markdown 转换为 HTML 的服务：用户将 Markdown 源文件上传到`/render`，它返回 HTML 转换，可以使用 `gitlab.com/golang-commonmark/markdown` 来轻松实现这一点

```
go mod init example.com/markdown

go get gitlab.com/golang-commonmark/markdown
```

`main.go` 文件：

```go
package main

import (
	"bytes"
	"io"
	"log"
	"net/http"
	_ "net/http/pprof"

	"gitlab.com/golang-commonmark/markdown"
)

func render(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		http.Error(w, "Only POST allowed", http.StatusMethodNotAllowed)
		return
	}

	src, err := io.ReadAll(r.Body)
	if err != nil {
		log.Printf("error reading body: %v", err)
		http.Error(w, "Internal Server Error", http.StatusInternalServerError)
		return
	}

	md := markdown.New(
		markdown.XHTMLOutput(true),
		markdown.Typographer(true),
		markdown.Linkify(true),
		markdown.Tables(true),
	)

	var buf bytes.Buffer
	if err := md.Render(&buf, src); err != nil {
		log.Printf("error converting markdown: %v", err)
		http.Error(w, "Malformed markdown", http.StatusBadRequest)
		return
	}

	if _, err := io.Copy(w, &buf); err != nil {
		log.Printf("error writing response: %v", err)
		http.Error(w, "Internal Server Error", http.StatusInternalServerError)
		return
	}
}

func main() {
	http.HandleFunc("/render", render)
	log.Printf("Serving on port 8080...")
	log.Fatal(http.ListenAndServe(":8080", nil))
}

```

构建并运行服务器：

```bash
go build -o markdown.nopgo.exe

./markdown.nopgo.exe
```

尝试从另一个终端发送一些 Markdown

```bash
curl -o README.md -L "https://raw.githubusercontent.com/golang/go/master/README.md"

curl --data-binary @README.md http://localhost:8080/render
```

### 分析

现在已经有了一个可以运行的服务，收集一个配置文件并使用 PGO 进行重建，看看是否可以获得更好的性能。

在 `main.go中`，导入了`net/http/pprof`，它会自动`/debug/pprof/profile`向服务器添加一个端点以获取 CPU 配置文件。

一个简单的程序来在收集配置文件时生成负载。获取并启动负载生成器：

```go
package main

import (
	"bytes"
	"flag"
	"fmt"
	"io"
	"log"
	"math"
	"net/http"
	"os"
)

var (
	source = flag.String("source", "./README.md", "path to markdown file to upload")
	addr   = flag.String("addr", "http://localhost:8080", "address of server")

	count = flag.Int("count", math.MaxInt, "Number of requests to send")
	quit  = flag.Bool("quit", false, "Send /quit request after sending all requests")
)

// generateLoad sends count requests to the server.
func generateLoad(count int) error {
	if *source == "" {
		return fmt.Errorf("-source must be set to a markdown source file")
	}
	if *addr == "" {
		return fmt.Errorf("-addr must be set to the address of the server (e.g., http://localhost:8080)")
	}

	src, err := os.ReadFile(*source)
	if err != nil {
		return fmt.Errorf("error reading source: %v", err)
	}
	reader := bytes.NewReader(src)

	url := *addr + "/render"

	for i := 0; i < count; i++ {
		reader.Seek(0, io.SeekStart)

		resp, err := http.Post(url, "text/markdown", reader)
		if err != nil {
			return fmt.Errorf("error writing request: %v", err)
		}
		if _, err := io.Copy(io.Discard, resp.Body); err != nil {
			return fmt.Errorf("error reading response body: %v", err)
		}
		resp.Body.Close()
	}

	return nil
}

func main() {

	fmt.Println("Generate Load")
	flag.Parse()

	if err := generateLoad(*count); err != nil {
		log.Fatal(err)
	}

	if *quit {
		http.Get(*addr + "/quit")
	}
}

```

运行上述的测试负载

```bash
go run ./main.go --source=$(pwd)/README.md
```

当它运行时，从服务器下载配置文件：

```bash
curl -o cpu.pprof "http://localhost:8080/debug/pprof/profile?seconds=30"
```

完成后，终止负载生成器和服务器

### 使用配置文件

当 Go 工具链在主包目录中找到`default.pgo`时，它将自动启用 PGO。或者在 go build 的时候采用 -pgo 用于 PGO 的配置文件的路径

建议将`default.pgo`文件提交到你的源码库。将配置文件与源代码一起存储可确保用户只需获取源码库（通过版本控制系统或通过`go get`）即可自动访问配置文件，并且构建保持可重现

```bash
go build -pgo cpu.pprof -o markdown.withpgo.exe

# mv cpu.pprof default.pgo
```

可以使用以下 `go version` 命令检查 PGO 是否在构建中启用：

```bash
> go version -m markdown.withpgo.exe

markdown.withpgo.exe: go1.21.3
...
        build   -pgo=/tmp/tmp.4r53chETDV/cpu.pprof
```

### 评估

将使用负载生成器的 Go 基准版本来评估 PGO 对性能的影响

首先，将对没有 PGO 的服务器进行基准测试。启动该服务器：

```bash
./markdown.nopgo.exe
```

基准

```go
// Copyright 2023 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package main

import (
	"testing"
)

func BenchmarkLoad(b *testing.B) {
	if err := generateLoad(b.N); err != nil {
		b.Errorf("generateLoad got err %v want nil", err)
	}
}

```

当它运行时，运行几个基准迭代：

```bash
go test -bench=. -count=40 -source $(pwd)/README.md > nopgo.txt
```

完成后，终止原始服务器并使用 PGO 启动该版本：

```bash
./markdown.withpgo.exe
```

当它运行时，运行几个基准迭代：

```bash
go test -bench=. -count=40 -source $(pwd)/README.md > withpgo.txt
```

完成后，比较一下结果：

```bash
go install golang.org/x/perf/cmd/benchstat@latest

benchstat nopgo.txt withpgo.txt
```

得到：

```bash
goos: linux
goarch: amd64
pkg: example.com/markdown/load
cpu: 12th Gen Intel(R) Core(TM) i5-12400
        │  nopgo.txt  │            withpgo.txt             │
        │   sec/op    │   sec/op     vs base               │
Load-12   75.47µ ± 0%   74.31µ ± 0%  -1.53% (p=0.000 n=40)
```

在 Go 1.21 中，启用 PGO 后工作负载的 CPU 使用率通常会提高 2% 到 7%。配置文件包含大量有关应用程序行为的信息，Go 1.21 刚刚开始通过使用这些信息进行一组有限的优化来探索表面。随着编译器的更多部分利用 PGO，未来的版本将继续提高性能。

### 下一步

收集配置文件后，使用原始构建中使用的完全相同的源代码重建了服务器。在现实世界中，总是有持续的改进。因此，可以从生产中收集运行上周代码的配置文件，并使用它来构建今天的源代码。

Go 中的 PGO 可以毫无问题地处理源代码的微小更改。当然，随着时间的推移，源代码会越来越漂移，因此偶尔更新配置文件仍然很重要。

### 探索 PGO

差异分析的技术来对此进行比较，收集两个配置文件（一个带有 PGO，一个没有）并进行比较。对于差异分析，重要的是两个配置文件代表相同的工作量**，**而不是相同的时间量，因此调整了服务以自动收集配置文件，并将负载生成器调整为发送固定数量的请求，然后退出服务

```yaml
// Copyright 2023 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package main

import (
	"bytes"
	"io"
	"log"
	"net/http"
	_ "net/http/pprof"
	"os"
	"runtime"
	"runtime/pprof"

	"gitlab.com/golang-commonmark/markdown"
)

func render(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		http.Error(w, "Only POST allowed", http.StatusMethodNotAllowed)
		return
	}

	src, err := io.ReadAll(r.Body)
	if err != nil {
		log.Printf("error reading body: %v", err)
		http.Error(w, "Internal Server Error", http.StatusInternalServerError)
		return
	}

	md := markdown.New(
		markdown.XHTMLOutput(true),
		markdown.Typographer(true),
		markdown.Linkify(true),
		markdown.Tables(true),
	)

	var buf bytes.Buffer
	if err := md.Render(&buf, src); err != nil {
		log.Printf("error converting markdown: %v", err)
		http.Error(w, "Malformed markdown", http.StatusBadRequest)
		return
	}

	if _, err := io.Copy(w, &buf); err != nil {
		log.Printf("error writing response: %v", err)
		http.Error(w, "Internal Server Error", http.StatusInternalServerError)
		return
	}
}

func main() {
	f, err := os.Create("/tmp/cpu.pprof")
	if err != nil {
		panic(err)
	}
	if err := pprof.StartCPUProfile(f); err != nil {
		panic(err)
	}
	http.HandleFunc("/quit", func(http.ResponseWriter, *http.Request) {
		pprof.StopCPUProfile()
		f.Close()

		f, err := os.Create("/tmp/heap.pprof")
		if err != nil {
			panic(err)
		}
		runtime.GC()
		if err := pprof.WriteHeapProfile(f); err != nil {
			panic(err)
		}
		f.Close()

		os.Exit(0)
	})

	http.HandleFunc("/render", render)
	log.Printf("Serving on port 8080...")
	log.Fatal(http.ListenAndServe(":8080", nil))
}

```

按照先前的方式编译 nopgo 和 withpgo 的版本，测试的参数有所改变，执行为 300k 次

运行测试负载

```bash
go run ./main.go --source=$(pwd)/README.md --count=300000 --quit
```

运行完成后拷贝 pprof 文件

```bash
# nopgo
mv /tmp/cpu.pprof ./cpu.nopgo.pprof
mv /tmp/heap.pprof ./heap.nopgo.pprof

# withpgo
mv /tmp/cpu.pprof ./cpu.withpgo.pprof
mv /tmp/heap.pprof ./heap.withpgo.pprof

```

作为快速一致性检查，检查处理所有 300k 请求所需的总 CPU 时间：

```bash
> go tool pprof -top cpu.nopgo.pprof | grep "Total samples"
Duration: 37.59s, Total samples = 27.64s (73.53%)

> go tool pprof -top cpu.withpgo.pprof | grep "Total samples"
Duration: 28.63s, Total samples = 26.40s (92.20%)
```

打开差异配置文件来寻找节省的空间：

```bash
> go tool pprof -diff_base cpu.nopgo.pprof cpu.withpgo.pprof

File: markdown.withpgo.exe
Type: cpu
Time: Oct 25, 2023 at 4:39pm (CST)
Duration: 66.22s, Total samples = 27.64s (41.74%)
Entering interactive mode (type "help" for commands, "o" for options)
(pprof) top -cum
Showing nodes accounting for -0.44s, 1.59% of 27.64s total
Dropped 42 nodes (cum <= 0.14s)
Showing top 10 nodes out of 673
      flat  flat%   sum%        cum   cum%
     0.04s  0.14%  0.14%     -0.96s  3.47%  runtime.systemstack
         0     0%  0.14%     -0.70s  2.53%  net/http.(*conn).serve
         0     0%  0.14%     -0.65s  2.35%  main.render
     0.01s 0.036%  0.18%     -0.64s  2.32%  net/http.HandlerFunc.ServeHTTP
     0.01s 0.036%  0.22%     -0.59s  2.13%  net/http.(*ServeMux).ServeHTTP
     0.02s 0.072%  0.29%     -0.57s  2.06%  net/http.serverHandler.ServeHTTP
    -0.01s 0.036%  0.25%     -0.41s  1.48%  runtime.gcBgMarkWorker
    -0.12s  0.43%  0.18%     -0.41s  1.48%  runtime.growslice
    -0.03s  0.11%  0.29%      0.37s  1.34%  runtime.netpoll
    -0.36s  1.30%  1.59%     -0.36s  1.30%  runtime.futex
(pprof) top 
Showing nodes accounting for 0.07s, 0.25% of 27.64s total
Dropped 42 nodes (cum <= 0.14s)
Showing top 10 nodes out of 673
      flat  flat%   sum%        cum   cum%
    -0.52s  1.88%  1.88%     -0.35s  1.27%  gitlab.com/golang-commonmark/markdown.ParserBlock.Parse
    -0.36s  1.30%  3.18%     -0.36s  1.30%  runtime.futex
     0.30s  1.09%  2.10%      0.30s  1.09%  gitlab.com/golang-commonmark/markdown.ruleText
     0.26s  0.94%  1.16%     -0.30s  1.09%  runtime.mallocgc
     0.21s  0.76%   0.4%      0.21s  0.76%  runtime/internal/syscall.Syscall6
     0.19s  0.69%  0.29%      0.18s  0.65%  gitlab.com/golang-commonmark/markdown.ruleReplacements
    -0.17s  0.62%  0.33%     -0.34s  1.23%  runtime.deductAssistCredit
     0.15s  0.54%  0.22%      0.04s  0.14%  gitlab.com/golang-commonmark/markdown.(*Renderer).renderToken
     0.15s  0.54%  0.76%      0.12s  0.43%  strings.ToLower
    -0.14s  0.51%  0.25%     -0.14s  0.51%  indexbytebody
```

指定时 `pprof -diff_base`，pprof 中显示的值是两个配置文件之间的差异。例如，`gitlab.com/golang-commonmark/markdown.ParserBlock.Parse` 使用 PGO 时比不使用 PGO 时使用的 CPU 时间少 0.52 秒。另一方面，`runtime.mallocgc` 多使用了 CPU 时间。在差异分析中，通常希望查看绝对值（flat 和 cum 列），因为百分比没有意义。

- `top -cum`显示累积变化的最大差异。也就是说，函数和该函数的所有传递被调用者的 CPU 差异。这通常会显示程序调用图中的最外层框架，例如`main`或另一个 goroutine 入口点。在这里可以看到大部分节省来自 `runtime.systemstack`

- `top`显示最大的差异仅限于函数本身的变化。这通常会显示程序调用图中的内部框架，其中大部分实际工作都在其中发生。在这里可以看到，这些单个的调用节省主要来自 `runtime`

查看一下调用堆栈看看它们来自哪里：

```bash
(pprof) peek mallocgc$
Showing nodes accounting for -1.19s, 4.31% of 27.64s total
----------------------------------------------------------+-------------
      flat  flat%   sum%        cum   cum%   calls calls% + context              
----------------------------------------------------------+-------------
                                            -0.26s 86.67% |   runtime.newobject
                                            -0.21s 70.00% |   runtime.growslice
                                             0.13s 43.33% |   internal/bytealg.MakeNoZero
                                             0.08s 26.67% |   runtime.makeslice
                                            -0.02s  6.67% |   runtime.makechan
                                            -0.02s  6.67% |   runtime.slicebytetostring
                                                 0     0% |   runtime.rawstring
     0.26s  0.94%  0.94%     -0.30s  1.09%                | runtime.mallocgc
                                            -0.34s 113.33% |   runtime.deductAssistCredit
                                            -0.19s 63.33% |   runtime.(*mcache).nextFree
                                             0.10s 33.33% |   runtime.memclrNoHeapPointers
                                            -0.09s 30.00% |   runtime.nextFreeFast (inline)
                                            -0.07s 23.33% |   runtime.gcStart
                                            -0.06s 20.00% |   runtime.releasem (inline)
                                             0.04s 13.33% |   runtime.divRoundUp (inline)
                                            -0.04s 13.33% |   runtime.acquirem (inline)
                                             0.03s 10.00% |   runtime.getMCache (inline)
                                             0.03s 10.00% |   runtime.publicationBarrier
                                             0.02s  6.67% |   runtime.makeSpanClass (inline)
                                             0.02s  6.67% |   runtime.profilealloc
                                             0.01s  3.33% |   runtime.heapBitsSetType
                                            -0.01s  3.33% |   runtime.gcTrigger.test
                                            -0.01s  3.33% |   runtime.gcmarknewobject
----------------------------------------------------------+-------------
```

GC 和分配器成本的降低意味着总体分配的数量更少

看一下堆配置文件了解更多信息：

```bash
> go tool pprof -sample_index=alloc_objects -diff_base heap.nopgo.pprof heap.withpgo.pprof

File: markdown.withpgo.exe
Type: alloc_objects
Time: Oct 25, 2023 at 4:40pm (CST)
Entering interactive mode (type "help" for commands, "o" for options)
(pprof) top
Showing nodes accounting for -12937164, 8.92% of 145003284 total
Dropped 74 nodes (cum <= 725016)
Showing top 10 nodes out of 63
      flat  flat%   sum%        cum   cum%
  -5185335  3.58%  3.58%   -5185335  3.58%  gitlab.com/golang-commonmark/mdurl.Parse
  -4068815  2.81%  6.38%   -4068815  2.81%  gitlab.com/golang-commonmark/mdurl.(*URL).String
  -1471862  1.02%  7.40%   -2003250  1.38%  gitlab.com/golang-commonmark/markdown.(*StateInline).PushPending
  -1148533  0.79%  8.19%   -1148533  0.79%  bytes.(*Buffer).String (inline)
   -625506  0.43%  8.62%   -9041203  6.24%  gitlab.com/golang-commonmark/markdown.ruleLinkify
   -573455   0.4%  9.02%    -580541   0.4%  gitlab.com/golang-commonmark/markdown.(*StateInline).PushToken
    532511  0.37%  8.65%     641923  0.44%  bytes.(*Buffer).grow
    507919  0.35%  8.30%    1057815  0.73%  gitlab.com/golang-commonmark/markdown.ruleHeading
   -499724  0.34%  8.64%    -460690  0.32%  gitlab.com/golang-commonmark/markdown.ruleParagraph
   -404364  0.28%  8.92%    -404364  0.28%  strings.(*Builder).grow
```

该 `-sample_index=alloc_objects` 选项向我们显示分配的数量，无论大小如何。这很有用，因为正在调查 CPU 使用率的下降，而这往往与分配数量而不是大小相关。这里有相当多的减少，但让关注最大的减少是，`mdurl.Parse`

作为参考，看看没有 PGO 的情况下该函数的总分配计数：

```bash
> go tool pprof -sample_index=alloc_objects -top heap.nopgo.pprof | grep mdurl.Parse

 5185335  3.58% 69.46%    5185335  3.58%  gitlab.com/golang-commonmark/mdurl.Parse
```

之前的总计数是 5185335，这意味着 `mdurl.Parse` 已经消除了 100% 的分配

#### 内联

回到差异概况，收集更多背景信息：

```bash
> go tool pprof -diff_base cpu.nopgo.pprof cpu.withpgo.pprof

(pprof) peek mdurl.Parse
Showing nodes accounting for -1.19s, 4.31% of 27.64s total
----------------------------------------------------------+-------------
      flat  flat%   sum%        cum   cum%   calls calls% + context              
----------------------------------------------------------+-------------
                                            -0.04s 400.00% |   gitlab.com/golang-commonmark/markdown.normalizeLinkText
                                             0.03s 300.00% |   gitlab.com/golang-commonmark/markdown.normalizeLink
     0.04s  0.14%  0.14%     -0.01s 0.036%                | gitlab.com/golang-commonmark/mdurl.Parse
                                            -0.20s 2000.00% |   runtime.newobject
                                             0.08s 800.00% |   strings.IndexAny
                                             0.04s 400.00% |   gitlab.com/golang-commonmark/mdurl.split
                                             0.03s 300.00% |   gitlab.com/golang-commonmark/mdurl.findScheme
                                             0.03s 300.00% |   strings.ToLower
                                            -0.02s 200.00% |   gcWriteBarrier
                                            -0.02s 200.00% |   strings.HasPrefix (inline)
                                             0.01s   100% |   strings.IndexByte (inline)
----------------------------------------------------------+-------------
```

对`mdurl.Parse` 的调用来自`markdown.normalizeLink`和`markdown.normalizeLinkText`

```bash
(pprof) list mdurl.Parse
Total: 27.64s
ROUTINE ======================== gitlab.com/golang-commonmark/mdurl.Parse in /root/go/pkg/mod/gitlab.com/golang-commonmark/mdurl@v0.0.0-20191124015652-932350d1cb84/parse.go
      40ms      -10ms (flat, cum) 0.036% of Total
     -20ms      -20ms     60:func Parse(rawurl string) (*URL, error) {
      10ms       40ms     61:   n, err := findScheme(rawurl)
         .          .     62:   if err != nil {
         .          .     63:           return nil, err
         .          .     64:   }
         .          .     65:
         .     -200ms     66:   var url URL
         .          .     67:   rest := rawurl
         .          .     68:   hostless := false
         .          .     69:   if n > 0 {
         .          .     70:           url.RawScheme = rest[:n]
      10ms       40ms     71:           url.Scheme, rest = strings.ToLower(rest[:n]), rest[n+1:]
      10ms       10ms     72:           if url.Scheme == "javascript" {
         .          .     73:                   hostless = true
         .          .     74:           }
         .          .     75:   }
         .          .     76:
         .      -20ms     77:   if !hostless && strings.HasPrefix(rest, "//") {
         .          .     78:           url.Slashes, rest = true, rest[2:]
         .          .     79:   }
         .          .     80:
         .          .     81:   if !hostless && (url.Slashes || (url.Scheme != "" && !slashedProtocol[url.Scheme])) {
      10ms      -10ms     82:           hostEnd := strings.IndexAny(rest, "#/?")
         .          .     83:           atSign := -1
         .          .     84:           i := hostEnd
         .          .     85:           if i == -1 {
         .          .     86:                   i = len(rest) - 1
         .          .     87:           }
         .          .     88:           for i >= 0 {
         .          .     89:                   if rest[i] == '@' {
         .          .     90:                           atSign = i
         .          .     91:                           break
         .          .     92:                   }
      30ms       30ms     93:                   i--
         .          .     94:           }
         .          .     95:
         .          .     96:           if atSign != -1 {
         .          .     97:                   url.Auth, rest = rest[:atSign], rest[atSign+1:]
         .          .     98:           }
         .          .     99:
         .      100ms    100:           hostEnd = strings.IndexAny(rest, "\t\r\n \"#%'/;<>?\\^`{|}")
         .          .    101:           if hostEnd == -1 {
         .          .    102:                   hostEnd = len(rest)
         .          .    103:           }
         .          .    104:           if hostEnd > 0 && hostEnd < len(rest) && rest[hostEnd-1] == ':' {
         .          .    105:                   hostEnd--
         .          .    106:           }
         .          .    107:           host := rest[:hostEnd]
         .          .    108:
         .          .    109:           if len(host) > 1 {
         .          .    110:                   b := host[hostEnd-1]
         .          .    111:                   if digit(b) {
         .          .    112:                           for i := len(host) - 2; i >= 0; i-- {
         .          .    113:                                   b := host[i]
         .          .    114:                                   if b == ':' {
         .          .    115:                                           url.Host, url.Port = host[:i], host[i+1:]
         .          .    116:                                           break
         .          .    117:                                   }
         .          .    118:                                   if !digit(b) {
         .          .    119:                                           break
         .          .    120:                                   }
         .          .    121:                           }
         .          .    122:                   } else if b == ':' {
         .          .    123:                           host = host[:hostEnd-1]
         .          .    124:                           hostEnd--
         .          .    125:                   }
         .          .    126:           }
         .          .    127:           if url.Port == "" {
         .      -10ms    128:                   url.Host = host
         .          .    129:           }
     -10ms      -10ms    130:           rest = rest[hostEnd:]
         .          .    131:
         .          .    132:           if ipv6 := len(url.Host) > 2 &&
         .          .    133:                   url.Host[0] == '[' &&
         .          .    134:                   url.Host[len(url.Host)-1] == ']'; ipv6 {
         .          .    135:                   url.Host = url.Host[1 : len(url.Host)-1]
         .          .    136:                   url.IPv6 = true
         .       10ms    137:           } else if i := strings.IndexByte(url.Host, ':'); i >= 0 {
         .          .    138:                   url.Host, rest = url.Host[:i], url.Host[i:]+rest
         .          .    139:           }
         .          .    140:   }
         .          .    141:
      10ms       70ms    142:   rest, url.Fragment, url.HasFragment = split(rest, '#')
     -10ms      -40ms    143:   url.Path, url.RawQuery, url.HasQuery = split(rest, '?')
         .          .    144:
         .          .    145:   return &url, nil
         .          .    146:}
```

非 PGO 构建中，`mdurl.Parse`被认为太大而没有资格进行内联。然而，因为 PGO 配置文件表明对此函数的调用很热，所以编译器确实内联了它们。可以从配置文件中的“(inline)”注释中看到这一点：

```bash
> go tool pprof -top cpu.nopgo.pprof | grep mdurl.Parse

     0.08s  0.29% 64.65%      0.79s  2.86%  gitlab.com/golang-commonmark/mdurl.Parse

> go tool pprof -top cpu.withpgo.pprof | grep mdurl.Parse

     0.12s  0.45% 61.89%      0.78s  2.95%  gitlab.com/golang-commonmark/mdurl.Parse (inline)
```

#### 去虚拟化

除了在上面的示例中看到的 inling 之外，PGO 还可以驱动接口调用的条件去虚拟化。

在讨论 PGO 驱动的去虚拟化之前，先退后一步，从总体上定义“去虚拟化”。假设代码如下所示：

```
f, _ := os.Open("foo.txt")
var r io.Reader = f
r.Read(b)
```

这里我们调用了`io.Reader`接口方法`Read`。由于接口可以有多个实现，因此编译器会生成间接函数调用，这意味着它会在运行时从接口值中的类型查找要调用的正确方法。与直接调用相比，间接调用具有较小的额外运行时成本，但更重要的是它们排除了一些编译器优化。例如，编译器无法对间接调用执行转义分析，因为它不知道具体的方法实现。

但在上面的例子中，确实知道具体的方法实现。它一定是`os.(*File).Read`，因为`*os.File`它是唯一可以分配给 r 的类型。在这种情况下，编译器将执行去虚拟化，用`io.Reader.Read`直接调用替换为间接调用`os.(*File).Read`，从而允许其他优化。

PGO 驱动的去虚拟化将此概念扩展到具体类型不是静态已知的情况，但分析可以显示，例如，大多数时间`io.Reader.Read`调用目标。`os.(*File).Read`在这种情况下，PGO 可以替换`r.Read(b)`为：

```go
if f, ok := r.(*os.File); ok {
    f.Read(b)
} else {
    r.Read(b)
}
```

也就是说，为最有可能出现的具体类型添加运行时检查，如果是这样，则使用具体调用，否则回退到标准间接调用。这里的优点是公共路径（使用`*os.File`）可以内联并应用额外的优化，但仍然保留后备路径，因为配置文件并不能保证始终如此。

