## 兼容性矩阵

官方文档地址：<https://www.elastic.co/cn/support/matrix#matrix_compatibility>

可查询适合的版本

## 配置调整？？

```json
# 日期格式
MM-DD@HH:mm:ss.SSS

# 默认列
message

# 时间筛选速选范围
[
  {
    "from": "now-15m",
    "to": "now",
    "display": "最近 15 分钟"
  },
  {
    "from": "now-30m",
    "to": "now",
    "display": "最近 30 分钟"
  },
  {
    "from": "now-1h",
    "to": "now",
    "display": "最近 1 小时"
  },
  {
    "from": "now-3h",
    "to": "now",
    "display": "最近 3 小时"
  },
  {
    "from": "now-5h",
    "to": "now",
    "display": "最近 5 小时"
  },
  {
    "from": "now-9h",
    "to": "now",
    "display": "最近 9 小时"
  },
  {
    "from": "now-24h",
    "to": "now",
    "display": "最近 24 小时"
  },
    {
    "from": "now/d",
    "to": "now/d",
    "display": "今日"
  },
  {
    "from": "now-3d",
    "to": "now",
    "display": "最近 3 天"
  },
  {
    "from": "now/w",
    "to": "now/w",
    "display": "本周"
  }
]
```