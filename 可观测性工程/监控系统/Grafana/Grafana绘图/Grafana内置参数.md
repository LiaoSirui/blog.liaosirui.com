## 内置变量

- `$__dashboard`

当前 dashboard 的名称

- `__from__to`

时间范围的毫秒值

可自定义格式，比如 `{__from: date :YYYY-MM-DD HH:mm:ss} {__from: date :seconds}`

- `$__interval`

查询的时间间隔，包含单位，比如：30s，2m

- `$__interval_ms`

查询的时间间隔，毫秒值

- `$__range`

查询的时间区间大小，包含单位，比如：2d

- `__range_s__range_ms`

查询的时间区间大小，分别是秒数和毫秒数

- `$__timeFilter`

返回当前选择的时间范围表达式，比如：`time > now () -7d`，常用于数据库作为 datasource 的时候