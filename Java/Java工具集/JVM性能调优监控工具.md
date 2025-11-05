## jps

jps（Java Virtual Machine Process Status Tool）是 JDK 提供的一个可以列出正在运行的 Java 虚拟机的进程信息的命令行工具，它可以显示 Java 虚拟机进程的执行主类（Main Class，main () 函数所在的类）名称、本地虚拟机唯一 ID（LVMID，Local Virtual Machine Identifier）等信息。另外，jps 命令只能显示它有访问权限的 Java 进程的信息

```bash
jps -lv
```

## jstack

jstack 是 JVM 自带的 Java 堆栈跟踪工具，它用于打印出给定的 java 进程 ID、core file、远程调试服务的 Java 堆栈信息。jstack 命令用于生成虚拟机当前时刻的线程快照

系统崩溃了？如果 java 程序崩溃生成 core 文件，jstack 工具可以用来获得 core 文件的 java stack 和 native stack 的信息，从而可以轻松地知道 java 程序是如何崩溃和在程序何处发生问题。

系统 hung 住了？jstack 工具还可以附属到正在运行的 java 程序中，看到当时运行的 java 程序的 java stack 和 native stack 的信息，如果现在运行的 java 程序呈现 hung 的状态，jstack 是非常有用的。

```bash
jstack [ option ] pid # 打印某个进程的堆栈信息
jstack [ option ] executable core 
```

## jstat

jstat 利用 JVM 内建的指令对 Java 应用程序的资源和性能进行实时的命令行的监控，包括了对进程的 classloader，compiler，gc 情况；

特别的，一个极强的监视内存的工具，可以用来监视 VM 内存内的各种堆和非堆的大小及其内存使用量，以及加载类的数量

## jmap

jmap 命令是 JDK 提供的一个命令行工具，用于生成 Java 虚拟机的堆转储快照（dump 文件），也被称为 heapdump 或 dump 文件。这个命令不仅可以获取 dump 文件，还可以查询 finalize 执行队列、Java 堆和永久代的详细信息，如空间使用率、当时使用的是哪种垃圾收集器等

```bash
jmap [options] pid
```

可以将 JVM 的 heap 内容输出到文件中，生成堆转储快照，这对于分析内存使用情况和定位内存泄漏问题非常有用

```bash
jmap -dump:format=b,file=path PID

# 示例
# jmap -dump:format=b,file=/usr/msg/20240203_heapdump.hprof 10016
```

`jmap -heap pid` 显示 Java 堆的如下信息：

- 被指定的垃圾回收算法的信息，包括垃圾回收算法的名称和垃圾回收算法的详细信息。
- 堆的配置信息，可能是由命令行选项指定，或者由 Java 虚拟机根据服务器配置选择的。
- 堆的内存空间使用信息，包括分代情况，每个代的总容量、已使用内存、可使用内存。如果某一代被继续细分 (例如，年轻代)，则包含细分的空间的内存使用信息。

代码演示，通过以下步骤演示使用 jmap 分析代码执行过程中的堆内存

```java
package alpha_quant.tech.jvm.heap;

/**
 * 演示堆内存
 */
public class MainClass {
    public static void main(String[] args) throws InterruptedException {
        System.out.println("1...");
        Thread.sleep(30000);
        byte[] array = new byte[1024 * 1024 * 10]; // 10 Mb
        System.out.println("2...");
        Thread.sleep(20000);
        array = null;
        System.gc();
        System.out.println("3...");
        Thread.sleep(1000000L);
    }
}
```

运行程序

```bash
javac MainClass.java -d .
java alpha_quant.tech.jvm.heap.MainClass
```

打印堆信息如下，注意命令已经更改为 `jhsdb jmap --heap --pid 1560800`

```bash
> jhsdb jmap --heap --pid 1560800

# ...

Heap Usage:
G1 Heap:
   regions  = 1990
   capacity = 8346664960 (7960.0MB)
   used     = 16699392 (15.92578125MB)
   free     = 8329965568 (7944.07421875MB)
   0.2000726287688442% used
G1 Young Generation:
Eden Space:
   regions  = 0
   capacity = 29360128 (28.0MB)
   used     = 0 (0.0MB)
   free     = 29360128 (28.0MB)
   0.0% used
Survivor Space:
   regions  = 0
   capacity = 0 (0.0MB)
   used     = 0 (0.0MB)
   free     = 0 (0.0MB)
   0.0% used
G1 Old Generation:
   regions  = 5
   capacity = 503316480 (480.0MB)
   used     = 16699392 (15.92578125MB)
   free     = 486617088 (464.07421875MB)
   3.31787109375% used
```

## jconsole

Jconsole 是 jdk 自带的一套 java 虚拟机执行状况监视器，它能够用来监控虚拟机的内存，线程，cpu 使用情况以及相关的 java 进程相关的 MBean。jconsole 跟 jmap 不一样，jconsole 可以一直监控内存等情况，而 jmap 只是打印出当前时刻的堆内存情况

## jvisualvm

jvisualvm 是 JDK 自带的 JAVA 性能分析工具