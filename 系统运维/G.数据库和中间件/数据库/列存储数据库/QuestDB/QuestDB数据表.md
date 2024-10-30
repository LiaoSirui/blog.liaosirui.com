QuestDB 没有 database 数据库独立实例，默认为 qdb，因此只需要建数据表即可

为了实现行情数据的灵活分区存储，可以采用”时间+标的“的方式进行数据分区，QuestDB 只支持时间分区（RoadMap 中预计在 2025Q1 支持）

- 逐笔委托（ORDER）

股票逐笔委托数据记录的最小时间间隔为 0.01 秒，每个 0.01 秒内有可能有多笔委托，Level-2 行情数据对 0.01 秒内的委托时点进行模糊处理，不进行区分。 股票逐笔委托数据的单日数据量由于交易活跃度不同，不同标的之间会有很大差异

```sql
CREATE TABLE IF NOT EXISTS order_book (
    security_id SYMBOL,       -- 证券代码
    transact_time TIMESTAMP,  -- 委托时间
    price DOUBLE,             -- 委托价格
    balance INT,              -- 委托数量
    order_bs_flag BOOLEAN     -- 买卖方向: true - 买; false - 卖
) timestamp(transact_time) PARTITION BY DAY WAL;

```

transact_time 为数据库引擎时序分区字段，此表需要基于 DAY (天) 时间分区，必需要有 timestamp 字段以进行数据写入时自动表分区

- 逐笔成交（TRADE）

股票逐笔成交数据记录了股票交易的每一笔成交信息。每笔成交包含价格、成交量、成交金额、成交时间等信息。单日数据量与不同标的的交易活跃度有关

```sql
CREATE TABLE IF NOT EXISTS trade_book (
    security_id SYMBOL,       -- 证券代码
    trade_bs_flag BOOLEAN,    -- 成交类别: true - 成交; false - 撤销
    trade_time TIMESTAMP,     -- 委托时间
    trade_price DOUBLE,       -- 委托价格
    trade_qty INT,            -- 成交数量
    trade_amount DOUBLE,      -- 成交金额
    buy_no STRING,            -- 买方委托编号
    sell_no STRING            -- 卖方委托编号
) timestamp(trade_time) PARTITION BY DAY WAL;

```

实现利⽤⻓度为 300tt、步进为 1tt 的滑动窗⼝ win300, win300 存储每 1tt 内所有委托⾦额的 sum, 随后实时计算 win300 中未被撤单的委托⾦额的 std 值, 并同时计算 win300 内⼤于 0 的委托⾦额的 std 值

计算每 10ms 内所有委托金额的总和：

