systemd系统中包含了timer计时器组件，timer可以完全替代cron+at，它具有以下特性：

- 可精确到微妙级别，其支持的时间单位包括：
  - us(微秒)、ms(毫秒)、s(秒)、m(分)、h(时)、d(日)、w(周)
  - 类似cron定义时间的方式(某年某月某日某时某分某秒以及时间段)
- 可对定时任务做资源限制
- 可替代cron和at工具，且支持比cron更加灵活丰富的定时规则
- 不会重复执行定时任务
  - 如果触发定时任务时发现上次触发的任务还未执行完，那么本次触发的任务不会执行
  - 而且systemd启动服务的操作具有幂等性，如果服务正在运行，启动操作将不做任何事，所以，甚至可以疯狂到每秒或每几秒启动一次服务，免去判断进程是否存在的过程
- 集成到journal日志，方便调试任务，方便查看任务调度情况

## 参考文档

- <https://www.ruanyifeng.com/blog/2018/03/systemd-timer.html>

- <https://systemd-book.junmajinlong.com/systemd_timer.html>