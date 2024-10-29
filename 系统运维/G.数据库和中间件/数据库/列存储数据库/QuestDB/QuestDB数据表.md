QuestDB 没有 database 数据库独立实例，默认为 qdb，因此只需要建数据表即可

为了实现行情数据的灵活分区存储，可以采用”时间+标的“的方式进行数据分区

- 逐笔委托（ORDER）

```sql
CREATE TABLE IF NOT EXISTS order_book (
    order_ts TIMESTAMP,    -- 委托时间
    ask_price DOUBLE,      -- 委卖价
    ask_vol INT,           -- 委卖量
    bid_price DOUBLE,      -- 委买价
    bid_vol INT,           -- 委买量
    symbol STRING          -- 股票代码
) timestamp(order_ts) PARTITION BY DAY WAL;
```

order_ts 为数据库引擎时序分区字段，此表需要基于 DAY (天) 时间分区，必需要有 timestamp 字段以进行数据写入时自动表分区

- 逐笔成交（TRADE）

transaction_book



- 'amount'                #成交总额
- 'volume'                #成交总量

- 委托数据和成交数据合在一起，称为TAQ（Trades and Quotes）行情

