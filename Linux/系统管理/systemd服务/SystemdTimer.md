## Systemd Timer

systemd 系统中包含了 timer 计时器组件，timer 可以完全替代 cron+at，它具有以下特性：

- 可精确到微妙级别，其支持的时间单位包括：
  - us (微秒)、ms (毫秒)、s (秒)、m (分)、h (时)、d (日)、w (周)
  - 类似 cron 定义时间的方式 (某年某月某日某时某分某秒以及时间段)
- 可对定时任务做资源限制
- 可替代 cron 和 at 工具，且支持比 cron 更加灵活丰富的定时规则
- 不会重复执行定时任务
  - 如果触发定时任务时发现上次触发的任务还未执行完，那么本次触发的任务不会执行
  - 而且 systemd 启动服务的操作具有幂等性，如果服务正在运行，启动操作将不做任何事，所以，甚至可以疯狂到每秒或每几秒启动一次服务，免去判断进程是否存在的过程
- 集成到 journal 日志，方便调试任务，方便查看任务调度情况

与 cron 作业类似，systemd 定时器可以在特定的时间间隔触发事件（shell   脚本和程序），例如每天一次或在一个月中的特定某一天（或许只有在周一生效），或在从上午 8 点到下午 6 点的工作时间内每隔 15   分钟一次。定时器也可以做到 cron   作业无法做到的一些事情。举个例子，定时器可以在特定事件发生后的一段时间后触发一段脚本或者程序去执行，例如开机、启动、上个任务完成，甚至于定时器调用的上个服务单元的完成的时刻

## 操作系统维护的计时器

任意一个基于 systemd 的发行版时，作为系统维护过程的一部分，它会在 Linux  宿主机的后台中创建多个定时器。这些定时器会触发事件来执行必要的日常维护任务，比如更新系统数据库、清理临时目录、轮换日志文件，以及更多其他事件

通过执行 `systemctl status '*timer'` 命令来展示主机上的所有定时器。星号的作用与文件通配相同，所以这个命令会列出所有的 systemd 定时器单元

```bash
● systemd-tmpfiles-clean.timer - Daily Cleanup of Temporary Directories
     Loaded: loaded (/usr/lib/systemd/system/systemd-tmpfiles-clean.timer; static)
     Active: active (waiting) since Thu 2025-07-31 07:44:35 CST; 2 months 11 days ago
      Until: Thu 2025-07-31 07:44:35 CST; 2 months 11 days ago
    Trigger: Sun 2025-10-12 08:48:23 CST; 23h left
   Triggers: ● systemd-tmpfiles-clean.service
       Docs: man:tmpfiles.d(5)
             man:systemd-tmpfiles(8)

Jul 31 07:44:35 aq-svc1-server systemd[1]: Started Daily Cleanup of Temporary Directories.

● logrotate.timer - Daily rotation of log files
     Loaded: loaded (/usr/lib/systemd/system/logrotate.timer; enabled; preset: enabled)
     Active: active (waiting) since Thu 2025-07-31 07:44:35 CST; 2 months 11 days ago
      Until: Thu 2025-07-31 07:44:35 CST; 2 months 11 days ago
    Trigger: Sun 2025-10-12 00:00:00 CST; 14h left
   Triggers: ● logrotate.service
       Docs: man:logrotate(8)
             man:logrotate.conf(5)

Jul 31 07:44:35 aq-svc1-server systemd[1]: Started Daily rotation of log files.
```

每个定时器至少有六行相关信息：

- 定时器的第一行有定时器名字和定时器目的的简短介绍
- 第二行展示了定时器的状态，是否已加载，定时器单元文件的完整路径以及预设信息。
- 第三行指明了其活动状态，包括该定时器激活的日期和时间。
- 第四行包括了该定时器下次被触发的日期和时间和距离触发的大概时间。
- 第五行展示了被定时器触发的事件或服务名称。
- 部分（不是全部）systemd 单元文件有相关文档的指引。虚拟机上输出中有三个定时器有文档指引。这是一个很好（但非必要）的信息。
- 最后一行是计时器最近触发的服务实例的日志条目。

观察定时任务的执行时间点

```bash
> systemctl list-timers --no-pager

NEXT                        LEFT          LAST                        PASSED  UNIT                         ACTIVATES                     
Sat 2025-10-11 14:30:16 CST 4h 39min left Fri 2025-10-10 14:30:16 CST 19h ago systemd-tmpfiles-clean.timer systemd-tmpfiles-clean.service
Sun 2025-10-12 00:00:00 CST 14h left      Sat 2025-10-11 00:01:01 CST 9h ago  logrotate.timer              logrotate.service

2 timers listed.
Pass --all to see loaded but inactive timers, too.
```

其中：

- `NEXT`表示下一次要触发定时任务的时间点
- `LEFT`表示现在距离下次执行任务还剩多长时间(已经确定了下一次执行的时间点)，或者显示最近一次执行任务已经过去了多长时间(还不确定下一次执行的时间点)，稍后解释了AccuracySec和RandomizedDelaySec就知道为什么会有这两种表示方式
- `LAST`表示上次触发定时任务的时间点
- `PASSED`表示距离上一次执行任务已经过去多久
- `UNIT`表示是哪个定时器
- `ACTIVATES`表示该定时器所触发的任务

## 创建一个定时器

想定时监控空余内存。在 `/etc/systemd/system` 目录下创建如下的 `myMonitor.server` 单元文件。它不需要是可执行文件：

```ini
# This service unit is for testing timer units
# By David Both
# Licensed under GPL V2
#

[Unit]
Description=Logs system statistics to the systemd journal
Wants=myMonitor.timer

[Service]
Type=oneshot
ExecStart=/usr/bin/free

[Install]
WantedBy=multi-user.target
```

默认情况下，systemd 服务单元执行程序的标准输出（`STDOUT`）会被发送到系统日志中，它保留了记录供现在或者之后（直到某个时间点）查看。（

专门查看你的服务单元的日志，而且只针对今天。`-S` 选项，即 `--since` 的缩写，允许你指定 `journalctl` 工具搜索条目的时间段。

```bash
journalctl -S today -u myMonitor.service
```

由服务触发的任务可以是单个程序、一组程序或者是一个脚本语言写的脚本。通过在 `myMonitor.service` 单元文件里的 `[Service]` 块末尾中添加如下行可以为服务添加另一个任务：

```bash
ExecStart=/usr/bin/lsblk
```

在 `/etc/systemd/system` 目录下创建 `myMonitor.timer` 定时器单元文件，添加如下代码：

```ini
 This timer unit is for testing
# By David Both
# Licensed under GPL V2
#

[Unit]
Description=Logs some system statistics to the systemd journal
Requires=myMonitor.service

[Timer]
Unit=myMonitor.service
OnCalendar=*-*-* *:*:00

[Install]
WantedBy=timers.target
```

在 `myMonitor.timer` 文件中的 `OnCalendar` 时间格式，`*-*-* *:*:00`，应该会每分钟触发一次定时器去执行 `myMonitor.service` 单元。

## 定时器精度

定时器并不是精确在每分钟的 `:00` 秒执行的，甚至每次执行的时间间隔都不是刚好一分钟。这是特意的设计，但是有必要的话可以改变这种行为。

这样设计的初衷是为了防止多个服务在完全相同的时刻被触发。举个例子，可以用例如 Weekly，Daily 等时间格式。这些快捷写法都被定义为在某一天的 `00:00:00` 执行。当多个定时器都这样定义的话，有很大可能它们会同时执行。

systemd 定时器被故意设计成在规定时间附近随机波动的时间点触发，以避免同一时间触发。它们在一个时间窗口内半随机触发，时间窗口开始于预设的触发时间，结束于预设时间后一分钟。根据 `systemd.timer` 的手册页，这个触发时间相对于其他已经定义的定时器单元保持在稳定的位置。你可以在日志条目中看到，定时器在启动后立即触发，然后在每分钟后的 46 或 47 秒触发。

大部分情况下，这种概率抖动的定时器是没事的。当调度类似执行备份的任务，只需要它们在下班时间运行，这样是没问题的。系统管理员可以选择确定的开始时间来确保不和其他任务冲突，例如  01:05:00 这样典型的 cron 作业时间，但是有很大范围的时间值可以满足这一点。在开始时间上的一个分钟级别的随机往往是无关紧要的。

然而，对某些任务来说，精确的触发时间是个硬性要求。对于这类任务，可以向单元文件的 `Timer` 块中添加如下声明来指定更高的触发时间跨度精确度（精确到微秒以内）：

```ini
ccuracySec=1us
```

时间跨度可用于指定所需的精度，以及定义重复事件或一次性事件的时间跨度。它能识别以下单位：

- `usec`，`us`，`µs`
- `msec`，`ms`
- `seconds`，`second`，`sec`，`s`
- `minutes`，`minute`，`min`，`m`
- `hours`，`hour`，`hr`，`h`
- `days`，`day`，`d`
- `weeks`，`week`，`w`
- `months`，`month`，`M`（定义为 30.44 天）
- `years`，`year`，`y`（定义为 365.25 天）

所有 `/usr/lib/systemd/system` 中的定时器都指定了一个更宽松的时间精度，因为精准时间没那么重要。

但是，触发定时任务的时间点并不表示这是执行任务的时间点。触发了定时任务，还需要根据 RandomizedDelaySec 的值来决定何时执行定时任务。

RandomizedDelaySec指定触发定时任务后还需延迟一个指定范围内的随机时长才执行任务。该指令默认值为0，表示触发后立即执行任务。

使用RandomizedDelaySec，主要是为了在一个时间范围内分散大量被同时触发的定时任务，从而避免这些定时任务集中在同一时间点执行而CPU争抢。

可见，`AccuracySec`和`RandomizedDelaySec`的目的是相反的：

- 前者让指定范围内的定时器集中在同一个时间点一次性触发它们的定时任务
- 后者让触发的、将要被执行的任务均匀分散在一个时间段范围内

通常进行如下的设置

```bash
AccuracySec = 1ms        # 定时器到点就触发定时任务
RandomizedDelaySec = 0   # 定时任务一触发就立刻执行任务
```

## 定时器类型

systemd 定时器还有一些在 cron 中找不到的功能，cron 只在确定的、重复的、具体的日期和时间触发。systemd   定时器可以被配置成根据其他 systemd   单元状态发生改变时触发。

举个例子，定时器可以配置成在系统开机、启动后，或是某个确定的服务单元激活之后的一段时间被触发。这些被称为单调计时器。“单调”指的是一个持续增长的计数器或序列。这些定时器不是持久的，因为它们在每次启动后都会重置。

| 定时器               | 单调性 | 定义                                                         |
| -------------------- | ------ | ------------------------------------------------------------ |
| `OnActiveSec=`       | X      | 定义了一个与定时器被激活的那一刻相关的定时器。               |
| `OnBootSec=`         | X      | 定义了一个与机器启动时间相关的计时器。                       |
| `OnStartupSec=`      | X      | 定义了一个与服务管理器首次启动相关的计时器。对于系统定时器来说，这个定时器与 `OnBootSec=` 类似，因为系统服务管理器在机器启动后很短的时间后就会启动。当以在每个用户服务管理器中运行的单元进行配置时，它尤其有用，因为用户的服务管理器通常在首次登录后启动，而不是机器启动后。 |
| `OnUnitActiveSec=`   | X      | 定义了一个与将要激活的定时器上次激活时间相关的定时器。       |
| `OnUnitInactiveSec=` | X      | 定义了一个与将要激活的定时器上次停用时间相关的定时器。       |
| `OnCalendar=`        | -      | 定义了一个有日期事件表达式语法的实时（即时钟）定时器。除此以外，它的语义和 `OnActiveSec=` 类似。 |

单调计时器可使用同样的简写名作为它们的时间跨度，即之前提到的 `AccuracySec` 表达式，但是 systemd 将这些名字统一转换成了秒。

举个例子，比如想规定某个定时器在系统启动后五天触发一次事件；它可能看起来像 `OnBootSec=5d`。如果机器启动于 `2020-06-15 09:45:27`，这个定时器会在 `2020-06-20 09:45:27` 或在这之后的一分钟内触发。

## 日历时间格式

与 crontab 中的格式相比，systemd 及其计时器使用的时间和日历格式风格不同。它比 crontab 更为灵活，而且可以使用类似 `at` 命令的方式允许模糊的日期和时间。它还应该足够熟悉使其易于理解。

systemd 定时器使用 `OnCalendar=` 的基础格式是 `DOW YYYY-MM-DD HH:MM:SS`。DOW（星期几）是选填的，其他字段可以用一个星号（`*`）来匹配此位置的任意值。所有的日历时间格式会被转换成标准格式。如果时间没有指定，它会被设置为 `00:00:00`。如果日期没有指定但是时间指定了，那么下次匹配的时间可能是今天或者明天，取决于当前的时间。月份和星期可以使用名称或数字。每个单元都可以使用逗号分隔的列表。单元范围可以在开始值和结束值之间用 `..` 指定。

指定日期有一些有趣的选项，波浪号（`~`）可以指定月份的最后一天或者最后一天之前的某几天。`/` 可以用来指定星期几作为修饰符。

| 日期事件格式               | 描述                                                         |
| -------------------------- | ------------------------------------------------------------ |
| `DOW YYYY-MM-DD HH:MM:SS`  | -                                                            |
| `*-*-* 00:15:30`           | 每年每月每天的 0 点 15 分 30 秒                              |
| `Weekly`                   | 每个周一的 00:00:00                                          |
| `Mon *-*-* 00:00:00`       | 同上                                                         |
| `Mon`                      | 同上                                                         |
| `Wed 2020-*-*`             | 2020 年每个周三的 00:00:00                                   |
| `Mon..Fri 2021-*-*`        | 2021 年的每个工作日（周一到周五）的 00:00:00                 |
| `2022-6,7,8-1,15 01:15:00` | 2022 年 6、7、8 月的 1 到 15 号的 01:15:00                   |
| `Mon *-05~03`              | 每年五月份的下个周一同时也是月末的倒数第三天                 |
| `Mon..Fri *-08~04`         | 任何年份 8 月末的倒数第四天，同时也须是工作日                |
| `*-05~03/2`                | 五月末的倒数第三天，然后 2 天后再来一次。每年重复一次。注意这个表达式使用了波浪号（`~`）。 |
| `*-05-03/2`                | 五月的第三天，然后每两天重复一次直到 5 月底。注意这个表达式使用了破折号（`-`）。 |

systemd 提供了一个绝佳的工具用于检测和测试定时器中日历时间事件的格式。`systemd-analyze calendar` 工具解析一个时间事件格式，提供标准格式和其他有趣的信息，例如下次“经过”（即匹配）的日期和时间，以及距离下次触发之前大概时间。

```bash
# 测试仅在工作日休盘后进行
# 列出来接下来 10 个执行时间
> systemd-analyze calendar --iterations=10 'Mon..Fri *-*-* 15:00:00'

Normalized form: Mon..Fri *-*-* 15:00:00
    Next elapse: Mon 2025-10-13 15:00:00 CST
       (in UTC): Mon 2025-10-13 07:00:00 UTC
       From now: 2 days left
       Iter. #2: Tue 2025-10-14 15:00:00 CST
       (in UTC): Tue 2025-10-14 07:00:00 UTC
       From now: 3 days left
       Iter. #3: Wed 2025-10-15 15:00:00 CST
       (in UTC): Wed 2025-10-15 07:00:00 UTC
       From now: 4 days left
       Iter. #4: Thu 2025-10-16 15:00:00 CST
       (in UTC): Thu 2025-10-16 07:00:00 UTC
       From now: 5 days left
       Iter. #5: Fri 2025-10-17 15:00:00 CST
       (in UTC): Fri 2025-10-17 07:00:00 UTC
       From now: 6 days left
       Iter. #6: Mon 2025-10-20 15:00:00 CST
       (in UTC): Mon 2025-10-20 07:00:00 UTC
       From now: 1 week 2 days left
       Iter. #7: Tue 2025-10-21 15:00:00 CST
       (in UTC): Tue 2025-10-21 07:00:00 UTC
       From now: 1 week 3 days left
       Iter. #8: Wed 2025-10-22 15:00:00 CST
       (in UTC): Wed 2025-10-22 07:00:00 UTC
       From now: 1 week 4 days left
       Iter. #9: Thu 2025-10-23 15:00:00 CST
       (in UTC): Thu 2025-10-23 07:00:00 UTC
       From now: 1 week 5 days left
      Iter. #10: Fri 2025-10-24 15:00:00 CST
       (in UTC): Fri 2025-10-24 07:00:00 UTC
       From now: 1 week 6 days left
```

## 参考文档

- <https://systemd-book.junmajinlong.com/systemd_timer.html>
