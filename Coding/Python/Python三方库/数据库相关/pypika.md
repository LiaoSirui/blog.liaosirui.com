## 简介

pypika：SQL 语句生成器

- <https://github.com/kayak/pypika>
- <https://pypika.readthedocs.io/en/latest/>

简单的 select：构建 select 语句的入口点是 pypika.Query，而查询数据的话必然要有两个关键信息：查询的表和指定的字段。

```python
from pypika import Query


# SELECT "id","name","age" FROM "t"
sql = Query.from_("t").select("id", "name", "age")

# 直接转成字符串即可
print(str(sql))

# 或者调用 get_sql 方法
print(sql.get_sql())

```

## 使用

### Table、Schema、Database

对于更复杂的查询，应该使用 pypika.Table

```python
from pypika import Query, Table

table = Table("t")
sql = Query.from_(table).select(table.id, table.name, table.age)

print(str(sql))
# SELECT "id","name","age" FROM "t"
```

指定别名

```python
from pypika import Query, Table

table = Table("t").as_("t1")
sql = Query.from_(table).select(table.id, table.name, table.age)

print(str(sql))
# SELECT "t1"."id","t1"."name","t1"."age" FROM "t" "t1"
```

对于 PostgreSQL 而言，它是具有 schema 的

```python
from pypika import Query, Table, Schema

sch = Schema("my_schema")
# 对 Schema 对象直接通过属性引用的方式即可指定表名，比如 sch.t 就表示从 my_schema 下寻找名称为 t 的表
sql = Query.from_(sch.t).select(sch.t.id, sch.t.name, sch.t.age)
# 也可以用反射的方式
sql = Query.from_(t := getattr(sch, "t")).select(t.id, t.name, t.age)
print(str(sql))
# SELECT "id","name","age" FROM "my_schema"."t"

# 或者更简单的做法
table = Table("t", schema="my_schema")
sql = Query.from_(table).select(table.id, table.name, table.age)
print(sql)
# SELECT "id","name","age" FROM "my_schema"."t"
```

指定 Database

```python
from pypika import Query, Database

db = Database("my_db")
# 从 my_db 这个数据库下寻找名字为 my_schema 的 schema，在 my_schema 下寻找名字为 t 的表
table = db.my_schema.t
sql = Query.from_(table).select(table.id)
print(sql)
# SELECT "id" FROM "my_db"."my_schema"."t"
```

补充一下：对于 Database 而言，进行属性查找会得到 Schema

```python
db = Database("my_db")
print(db.my_schema.__class__)  # <class 'pypika.queries.Schema'>
# 对于 Schema 而言，进行属性查找会得到 Table
print(db.my_schema.t.__class__)  # <class 'pypika.queries.Table'>
# 对于 Table 而言，进行属性查找会得到 Field
print(db.my_schema.t.id.__class__)  # <class 'pypika.terms.Field'>
```

### 排序

```python
from pypika import Query, Order

sql = Query.from_("t").select("id", "name").orderby("id", order=Order.desc)
print(sql)
# SELECT "id","name" FROM "t" ORDER BY "id" DESC

# 如果是多个字段的话
sql = Query.from_("t").select("id", "name").orderby("age", "id")
print(sql)
# SELECT "id","name" FROM "t" ORDER BY "age","id"

sql = (
    Query.from_("t")
    .select("id", "name")
    .orderby("age", "id", order=Order.desc)
)
print(sql)
# SELECT "id","name" FROM "t" ORDER BY "age" DESC,"id" DESC

# 如果是一个字段升序、一个字段降序怎么办？答案是调用两次 orderby 即可
sql = (
    Query.from_("t")
    .select("id", "name")
    .orderby("age", order=Order.desc)
    .orderby("id")
)
print(sql)
# SELECT "id","name" FROM "t" ORDER BY "age" DESC,"id"
```

### 四则运算

执行 select 查询的时候，字段是可以进行运算的。

```python
from pypika import Query, Field, Table, Database

table = Table("t")
print(
    Query.from_(table).select(table.id, table.age + 1)
)  # SELECT "id","age"+1 FROM "t"

# 我们看一下 table.id 是什么类型
print(table.id.__class__)  # <class 'pypika.terms.Field'>

# 所以我们也可以直接根据 Field 进行构建
print(
    Query.from_(table).select(
        Field("id"), Field("age") + 1, Field("first") + Field("last")
    )
)
# SELECT "id","age"+1,"first"+"last" FROM "t"
```

也可以进行更加复杂的运算，以及给字段起别名：

```python
from pypika import Query, Field, Table

table = Table("t")

sql = Query.from_(table).select(
    Field("id").as_("ID"),
    ((Field("count") + 2000) * Field("price")).as_("amount"),
)
# 字段起别名可以使用 as、也可以不使用
print(sql)
# SELECT "id" "ID",("count"+2000)*"price" "amount" FROM "t"
```

### where 语句

在获取数据的时候，很少会全部获取，绝大多数情况只会获取指定的数据，这个时候就需要使用 where 语句。

```python
from pypika import Query, Field, Table

girl = Table("girl")

# 注意：where 里面不可以写 "age > 18"
sql = Query.from_(girl).select("*").where(Field("age") >= 18)
print(sql)
# SELECT * FROM "girl" WHERE "age">=18

# 如果是多个 where 条件怎么办呢？答案是调用多次 where 即可
# 就像我们之前使用的 orderby 一样，其实除了 orderby 之外，像 select、where、groupby 都是可以多次调用的
sql = (
    Query.from_(girl)
    .select("id")
    .select(girl.name)
    .select(Field("age"))
    .where(Field("age") >= 18)
    .where(girl.age <= 30)
    .where(Field("length") < 165)
)
print(sql)
# SELECT "id","name","age" FROM "girl" WHERE "age">=18 AND "age"<=30 AND "length"<165
```

还有 in 和 between 也是支持的，还有其它的方法，比如：contains、isnull、notnull、notin、not_like 等等

```python
from pypika import Query, Field, Table, Database

girl = Table("girl")

sql = Query.from_(girl).select("*").where(Field("age").between(18, 30))
print(sql)
# SELECT * FROM "girl" WHERE "age" BETWEEN 18 AND 30

# between 还可以使用切片的形式，并且切片除了数字之外、时间也是可以的，因为数据库是支持对时间的 between 语法的
sql = (
    Query.from_(girl)
    .select("*")
    .where(Field("age")[18:30])
    .where(Field("length").isin([155, 156, 157]))
)
print(sql)
# SELECT * FROM "girl" WHERE "age" BETWEEN 18 AND 30 AND "length" IN (155,156,157)
```

还可以使用  `&`、`｜`、`^` 三个符号

- AND

```python
from pypika import Query, Field, Table

girl = Table("girl")

sql = (
    Query.from_(girl)
    .select("*")
    .where((Field("age") > 18) & Field("length") < 160)
)
print(sql)
# SELECT * FROM "girl" WHERE "age">18 AND "length"<160
```

- OR

```python
from pypika import Query, Field, Table

girl = Table("girl")

sql = (
    Query.from_(girl)
    .select("*")
    .where((Field("age") > 18) | Field("length") < 160)
)
print(sql)
# SELECT * FROM "girl" WHERE "age">18 OR "length"<160
```

- XOR

```python
from pypika import Query, Field, Table

girl = Table("girl")

sql = (
    Query.from_(girl)
    .select("*")
    .where((Field("age") > 18) ^ Field("length") < 160)
)
print(sql)
# SELECT * FROM "girl" WHERE "age">18 XOR "length"<160
```

对于 AND 和 OR，pypika 提供了专门的类来实现链式的 AND、OR 表达式

```python
from pypika import Query, Field, Table, Criterion

girl = Table("girl")

sql = (
    Query.from_(girl)
    .select("*")
    .where(
        Criterion.all(
            [
                Field("id") > 10,
                Field("age") > 18,
                Field("length").isin([155, 156, 157]),
            ]
        )
    )
)
print(sql)
# SELECT * FROM "girl" WHERE "id">10 AND "age">18 AND "length" IN (155,156,157)


sql = (
    Query.from_(girl)
    .select("*")
    .where(
        Criterion.any(
            [
                Field("id").between(10, 50),
                Field("age") > 18,
                Field("length").isin([155, 156, 157]),
            ]
        )
    )
)
print(sql)
# SELECT * FROM "girl" WHERE "id" BETWEEN 10 AND 50 OR "age">18 OR "length" IN (155,156,157)
```

### 分组和聚合

group by

```python
from pypika import Query, Field, Table, functions as fn

girl = Table("girl")

# fn 是一个模块，里面包含了很多的类，每个类对应一个聚合函数
# 但是注意：往类里面（比如下面的 fn.Count）传入字段的时候，不能直接传递字符串，需要传递一个 Field 对象
sql = (
    Query.from_(girl)
    .select("age", fn.Count(Field("id")))
    .where(Field("age")[18:30] & (Field("length") < 160))
    .groupby(Field("age"))
)
print(sql)
# SELECT "age",COUNT("id") FROM "girl" WHERE "age" BETWEEN 18 AND 30 AND "length"<160 GROUP BY "age"
```

可以看到拼接的 SQL 语句是正确的，如果传递的是  `fn.Count("id")` 的话，那么拼接之后得到的就是 `Count('id')`。pypika  给变成了单引号，显然这是不合法的，因为在数据库中单引号表示字符串。如果传递字符串，那么只能传递 ""，会得到  `Count()`，这是个特例。当然有人会说这是 PostgreSQL 的语法，MySQL  应该是反引号才对，没错，后面的话我们会说如何适配数据库。因为数据库的种类不同，语法也会稍有不同，而目前没有任何信息表明使用的到底是哪一种数据库。

除了 `fn.Count`  表示计算次数之外，还有很多其它的函数，比如：`fn.Sum` 表示计算总和；`fn.Avg`  表示计算平均值等等。除此之外还有很多其它的函数，比如取绝对值、对数、类型转换等等，在 SQL 里面有的都可以去里面找。

groupby 之后就可以接 having，HAVING 子句用于过滤分组结果或聚合计算结果（WHERE 子句用于在聚合计算之前过滤原始数据）

```python
from pypika import Query, Field, Table, functions as fn

girl = Table("girl")

sql = (
    Query.from_(girl)
    .select("age", fn.Count(Field("id")))
    .where(Field("age")[18:30] & (Field("length") < 160))
    .groupby(Field("age"))
    .having(fn.Count(Field("id")) > 30)
)
print(sql)
# SELECT "age",COUNT("id") FROM "girl" WHERE "age" BETWEEN 18 AND 30 AND "length"<160 GROUP BY "age" HAVING COUNT("id")>30
```

### 两表 join

多表 join 的话可以直接使用 Query.join 来实现， 并且后面需要跟 using 或 on 字句。

```python
from pypika import Query, Table


table1 = Table("t1")
table2 = Table("t2")

sql = (
    Query.from_(table1)
    .select(table2.age, table1.name)
    .left_join(table2)
    .using("id")
)
print(sql)
# SELECT "t2"."age","t1"."name" FROM "t1" LEFT JOIN "t2" USING ("id")

# 此时查询字段的时候就不能只写字段名，因为涉及到了两张表
# 假设指定的是 "age"，那么结果默认是 "t1"."age"，但不一定就是要 t1 里面的 age
# 假设指定的是 Field("age")，那么结果得到的就是 "age"，如果两张表里面都要 age 字段，那么数据库是无法区分到底选择哪张表里的 age 字段的
# 可能有人觉得 Field("t2.age") 不就行了，答案是不行的，原因跟之前说的一样，该结果得到的是 "t2.age"，而结果应该是 "t2"."age"

# 所以需要通过 table2.age 的方式，但是这样也隐藏一个问题，其实这个问题在之前就应该说的
# 通过 "Table对象.字段" 的方式可以筛选指定的字段，但是 Table对象有没有自己的方法呢？
print(table1.as_)
# <bound method builder.<locals>._copy of Table('t1')>

# 显然 as_ 就是一个方法，用于起别名，之前用过
# 但是问题来了，如果数据库表中就有一个字段叫做 as_ 该咋办
sql = Query.from_(table1).select(table2.as_).left_join(table2).using("id")
print(sql)
# SELECT <bound method builder.<locals>._copy of Table('t2')> FROM "t1" LEFT JOIN "t2" USING ("id")

# 看到结果不是想要的，所以还有最后一个做法
sql = (
    Query.from_(table1)
    .select(table2.field("age"))
    .left_join(table2)
    .using("id")
)
print(sql)
# SELECT "t2"."age" FROM "t1" LEFT JOIN "t2" USING ("id")
```

选择字段的方式还是很多的，总结一下：

| 方式                  | 缺点                                         |
| --------------------- | -------------------------------------------- |
| `"字段"`              | 不能是多表 join                              |
| `Field("字段")`       | 不能是多表 join                              |
| `table.字段`          | 可以多表 join，但是不能和 Table 内部方法重名 |
| `table.field("字段")` | 没有限制，终极选择                           |

join 的几种方式

- `left_join`
- `right_join`
- `inner_join`
- `outer_join`
- `cross_join`
- `hash_join`

使用 on 进行连接

当两张表要连接的字段的名字相同、并且是等值连接，那么可以使用 using。但是这种情况还是不多的，最常见的情况是：两个名字不同的字段进行等值连接，比如一张表的 uid 等于另一张表的 tid 等等。

```python
from pypika import Query, Table


table1 = Table("t1")
table2 = Table("t2")

sql = (
    Query.from_(table1)
    .select(table2.age, table1.name)
    .left_join(table2)
    .on(table1.field("uid") == table2.field("tid"))
)
print(sql)
# SELECT "t2"."age","t1"."name" FROM "t1" LEFT JOIN "t2" ON "t1"."uid"="t2"."tid"
```

当然可以在 join 之前使用 where，先把不必要的数据过滤掉。

```python
from pypika import Query, Table


table1 = Table("t1")
table2 = Table("t2")

sql = (
    Query.from_(table1)
    .select(table2.age, table1.name)
    .left_join(table2)
    .using("id")
    .where(table1.age > 18)
)
print(sql)
# SELECT "t2"."age","t1"."name" FROM "t1" LEFT JOIN "t2" USING ("id") WHERE "t1"."age">18
```

### 嵌套子查询

```python
from pypika import Query, Table, functions as fn


table1 = Table("t1")
table2 = Table("t2")

sub_query = (
    Query.from_(table1)
    .select(fn.Avg(table2.age).as_("avg"))
    .left_join(table2)
    .using("id")
    .where(table1.age > 18)
)
print(sub_query)
# SELECT AVG("t2"."age") "avg" FROM "t1" LEFT JOIN "t2" USING ("id") WHERE "t1"."age">18

# 子查询完全可以当成一张表来操作
sql = (
    Query.from_(table1)
    .select("age", "name")
    .where(table1.field("age") > Query.from_(sub_query).select("avg"))
)
print(sql)
"""
SELECT "age", "name"
FROM "t1"
WHERE "age" > (
            SELECT "sq0"."avg"
            FROM (
                SELECT AVG("t2"."age") "avg"
                FROM "t1"
                LEFT JOIN "t2" USING ("id")
                WHERE "t1"."age" > 18
            ) "sq0"
        )
"""
```

### 集合运算

两个结果集之间是可以合并的，比如 union 和 union all，至于 union distinct 它是 union 的同义词，所以 pypika 没有设置专门的函数。union 虽然可以用来合并多个结果集，但前提是它们要有相同的列。

```python
from pypika import Query, Table

table1 = Table("t1")
table2 = Table("t2")

sql1 = Query.from_(table1).select("name", "age", "salary")
sql2 = Query.from_(table2).select("name", "age", "salary")

print(sql1.union(sql2))
# (SELECT "name","age","salary" FROM "t1") UNION (SELECT "name","age","salary" FROM "t2")
print(sql2.union(sql1))
# (SELECT "name","age","salary" FROM "t2") UNION (SELECT "name","age","salary" FROM "t1")

# union 可以使用 + 代替
print(str(sql1 + sql2) == str(sql1.union(sql2)))  # True
print(str(sql2 + sql1) == str(sql2.union(sql1)))  # True

# union_all 可以使用 * 代替
print(sql1.union_all(sql2))
# (SELECT "name","age","salary" FROM "t1") UNION ALL (SELECT "name","age","salary" FROM "t2")
print(sql2.union_all(sql1))
# (SELECT "name","age","salary" FROM "t2") UNION ALL (SELECT "name","age","salary" FROM "t1")
print(str(sql1 * sql2) == str(sql1.union_all(sql2)))  # True
print(str(sql2 * sql1) == str(sql2.union_all(sql1)))  # True
```

此外还有交集、差集、对称差集

```python
from pypika import Query, Table

table1 = Table("t1")
table2 = Table("t2")

sql1 = Query.from_(table1).select("name", "age", "salary")
sql2 = Query.from_(table2).select("name", "age", "salary")

# 交集，没有提供专门的操作符
print(sql1.intersect(sql2))
# (SELECT "name","age","salary" FROM "t1") INTERSECT (SELECT "name","age","salary" FROM "t2")

# 差集，可以使用减号替代
print(sql1.minus(sql2))
# (SELECT "name","age","salary" FROM "t1") MINUS (SELECT "name","age","salary" FROM "t2")

# 对称差集，没有提供专门的操作符
print(sql1.except_of(sql2))
# (SELECT "name","age","salary" FROM "t1") EXCEPT (SELECT "name","age","salary" FROM "t2")
```

### Date, Time, and Intervals

```python
from pypika import Query, Table, functions as fn, Interval

fruits = Table("fruits")

sql = (
    Query.from_(fruits)
    .select(fruits.id, fruits.name)
    .where(fruits.harvest_date + Interval(months=1) < fn.Now())
)
print(sql)
# SELECT "id","name" FROM "fruits" WHERE "harvest_date"+INTERVAL '1 MONTH'<NOW()
```

### 多值比较

SQL 有一个非常有用的特性，假设一张表中有 year、month  这两个字段，然后我想找出 year、month 组合起来之后大于 2020 年 7 月的记录。比如：year = 2021、month = 2  这条记录就是合法的，因为 year 是大于 2020 的；year = 2020、month = 8 也是合法的。

数据库提供了多值比较：

```sql
select * from t where (year, month) > (2020, 7)
```

这样会先比较 year，如果满足 year > 2020、直接成立，year < 2020、直接不成立，后面就不用比了；如果 year = 2020，那么再比较 month。

```python
from pypika import Query, Table, Tuple

table = Table("t")

sql = (
    Query.from_(table)
    .select(table.salary)
    .where(Tuple(table.year, table.month) >= (2020, 7))
)
print(sql)
# SELECT "salary" FROM "t" WHERE ("year","month")>=(2020,7)
```

对于 in 字句也是同样的道理：

```python
from pypika import Query, Table, Tuple

table = Table("t")

sql = (
    Query.from_(table)
    .select(table.salary)
    .where(
        Tuple(table.year, table.month).isin([(2020, 7), (2020, 8), (2020, 9)])
    )
)
print(sql)
# SELECT "salary" FROM "t" WHERE ("year","month") IN ((2020,7),(2020,8),(2020,9))
```

### 字符串函数

字符串操作也是非常常用的，下面来看一下：

```python
from pypika import Query, Table

table = Table("t")

sql = (
    Query.from_(table)
    .select("name", "age", "salary")
    .where(
        table.field("name").like("古明地%")
        & table.field("place").ilike("ja%")  # ilike 不区分大小写
    )
)
print(sql)
# SELECT "name","age","salary" FROM "t" WHERE "name" LIKE '古明地%' AND "place" ILIKE 'ja%'
```

正则也是可以的：

```python
from pypika import Query, Table

table = Table("t")

sql = (
    Query.from_(table)
    .select("name", "age", "salary")
    .where(table.field("xxx").regex(r"^[abc][a-zA-Z]+&"))
)
print(sql)
# SELECT "name","age","salary" FROM "t" WHERE "xxx" REGEX '^[abc][a-zA-Z]+&'
```

还有字符串之间的 concat、大小写转换等等：

```python
from pypika import Query, Table, functions as fn

table = Table("t")

sql = Query.from_(table).select(
    fn.Concat(table.field("name"), "-", table.field("age")),
    fn.Upper(table.field("name")),
    fn.Lower(table.field("name")),
    fn.Length(table.field("name")),
)
print(sql)
# SELECT CONCAT("name",'-',"age"),UPPER("name"),LOWER("name"),LENGTH("name") FROM "t"
```

### 自定义函数

尽管 pypika 的 fn 模块支持大部分的 SQL 函数，但还是有少部分没有覆盖到，这个时候自定义函数的实现

```python
from pypika import Table, Query, CustomFunction

table = Table("t")
# 自定义实现数据库的 LENGTH 函数，该函数可以接收一个参数来查看长度
my_length = CustomFunction("LENGTH", ["col"])
# 自定义实现数据库的 POWER 函数，该函数可以接收两个参数来计算幂
my_power = CustomFunction("POWER", ["col1", "col2"])

sql = Query.from_(table).select(my_length(table.field("name")))
print(sql)
# SELECT LENGTH("name") FROM "t"

sql = Query.from_(table).select(
    my_power(table.field("num"), table.field("base"))
)
print(sql)
# SELECT POWER("num","base") FROM "t"

sql = Query.from_(table).select(my_power(table.field("num"), 3))
print(sql)
# SELECT POWER("num",3) FROM "t"
```

### case when

```python
from pypika import Table, Query, Case

table = Table("t")

sql = Query.from_(table).select(
    table.name,
    Case()
    .when(table.age < 18, "未成年")
    .when(table.age < 30, "成年")
    .when(table.age < 50, "中年")
    .else_("老年")
    .as_("age"),
)
print(sql)
"""
SELECT "name",
    CASE WHEN "age"<18 THEN '未成年'
        WHEN "age"<30 THEN '成年'
        WHEN "age"<50 THEN '中年'
        ELSE '老年'
    END "age"
FROM "t"
"""
```

### with 语句

```python
from pypika import Table, Query, AliasedQuery

table = Table("t")

sub_query = Query.from_(table).select("*")
sql = Query.with_(sub_query, "alias").from_(AliasedQuery("alias")).select("*")
print(sql)
# WITH alias AS (SELECT * FROM "t") SELECT * FROM alias
```

### distinct

相对结果集进行去重的

```python
from pypika import Query, Table

table = Table("t")
print(
    # 只需要在 select 之前调用一次 distinct 即可
    Query.from_(table)
    .distinct()
    .select(table.id, table.age)
)
# SELECT DISTINCT "id","age" FROM "t"
```

### limit 与 offset

```python
from pypika import Table, Query, functions as fn, Order

table = Table("t")
sql = (
    Query.from_(table)
    .select(fn.Count("id").as_("count"), "age", "length")
    .where(table.field("age") > 18)
    .groupby("age", "length")
    .having(fn.Count("id") > 10)
    .orderby("count", order=Order.desc)
    .orderby("age", order=Order.asc)
    .limit(10)
    .offset(5)
)
print(sql)
"""
SELECT COUNT('id') "count", "age", "length"
FROM "t"
WHERE "age" > 18
GROUP BY "age", "length"
HAVING COUNT('id') > 10
ORDER BY "count" DESC, "age" ASC
LIMIT 10 OFFSET 5
"""
```

## 插入数据

简单的插入数据

```python
from pypika import Table, Query

table = Table("t")
# 查询是 Query.from_，插入数据是 Query.into
sql = Query.into(table).insert(1, "xxx", 16, "yyy")
print(sql)
# INSERT INTO "t" VALUES (1,'xxx',16,'yyy')
```

需要注意的地方，比如：None 值的处理

```python
from pypika import Table, Query

table = Table("t")

sql = Query.into(table).insert(1, "xxx", None, "yyy")
# 自动换成了 NULL，如果是自己手动拼接的话，那么还需要额外处理一下
# 而 pypika 内部已经做了，如果不把 None 换成 NULL，交给数据库执行是会报错的
print(sql)
# INSERT INTO "t" VALUES (1,'xxx',NULL,'yyy')

# 假设第二个字段在数据库中是一个 json
sql = Query.into(table).insert(
    1, {"name": "xxx", "age": 16, "where": None}
)
print(sql)
# INSERT INTO "t" VALUES (1,{'name': 'xxx', 'age': 16, 'where': None})
# 我们看到这不是我们期望的结果，应该手动将值先变成 json 才行

import json

sql = Query.into(table).insert(
    1,
    json.dumps(
        {"name": "xxx", "age": 16, "where": None}, ensure_ascii=False
    ),
)
print(sql)
# INSERT INTO "t" VALUES (1,'{"name": "xxx", "age": 16, "where": null}')
# 以上就没有问题了
```

插入多条数据

```python
from pypika import Table, Query

table = Table("t")

sql = (
    Query.into(table)
    .insert(1, "xxx", 16, "yyy")
    .insert(2, "xxx", 15, "yyy")
)
print(sql)
# INSERT INTO "t" VALUES (1,'xxx',16,'yyy'),(2,'xxx',15,'yyy')

# 或者
sql = Query.into(table).insert(
    (1, "xxx", 16, "yyy"), (2, "xxx", 15, "yyy")
)
print(sql)
# INSERT INTO "t" VALUES (1,'xxx',16,'yyy'),(2,'xxx',15,'yyy')
```

指定字段插入

```python
from pypika import Table, Query, Field

table = Table("t")

sql = (
    Query.into(table)
    .columns("id", table.field("name"), table.age, Field("place"))
    .insert(1, "xxx", 16, "yyy")
)
print(str(sql))
# INSERT INTO "t" ("id","name","age","place") VALUES (1,'xxx',16,'yyy')
```

将一张表的部分记录插入到另一张表中

```python
from pypika import Table, Query, Field

table1 = Table("t1")
table2 = Table("t2")

sql = (
    Query.into(table1)
    .columns("id", "name", "age")
    .from_(table2)
    .select("id", "name", "age")
    .where(Field("age") > 18)
)
print(sql)
# INSERT INTO "t1" ("id","name","age") SELECT "id","name","age" FROM "t2" WHERE "age">18
```

将两个表 join 之后的数据插入到新表中也是可以的：

```python
from pypika import Table, Query, Field

table1 = Table("t1")
table2 = Table("t2")
table3 = Table("t3")

sql = (
    Query.into(table1)
    .columns("id", "name", "age")
    .from_(table2)
    .left_join(table3)
    .on(table2.id == table3.id)
    .select(table2.id, table2.name, table3.age)
)
print(sql)
"""
INSERT INTO "t1" ("id","name","age") 
SELECT "t2"."id","t2"."name","t3"."age" FROM "t2" LEFT JOIN "t3" ON "t2"."id"="t3"."id"
"""
```

## 更新数据

简单的更新数据

```python
from pypika import Table, Query

table = Table("t")

# 更新是 update
sql = Query.update(table).set(table.name, "xxx")
print(sql)
# UPDATE "t" SET "name"='xxx'

sql = Query.update(table).set(table.name, "xxx").where(table.id == 1)
print(sql)
# UPDATE "t" SET "name"='xxx' WHERE "id"=1

sql = Query.update(table).set(table.name, "xxx").set(table.age, 16)
print(sql)
# UPDATE "t" SET "name"='xxx',"age"=16
```

用另一张表的数据更新当前也是一种比较常见的操作，比如 t1 有 id、name 两个字段，t2 有 id、name 两个字段。如果 t1 的 id 在 t2 中存在，那么就用 t2 的 name 更新掉 t1 的 name。

```python
from pypika import Table, Query

table1 = Table("t1")
table2 = Table("t2")

sql = (
    Query.update(table1)
    .join(table2)
    .on(table1.uid == table2.tid)
    .set(table1.name, table2.name)
    .where(table1.uid > 10)
)
print(sql)
# UPDATE "t1" JOIN "t2" ON "t1"."uid"="t2"."tid" SET "name"="t2"."name" WHERE "t1"."uid">10
```

最后，更新字段还有另一种方式：

```python
from pypika import Table

table1 = Table("t1")
table2 = Table("t2")

# Query.update(table1) 也可以写成 table1.update()，其它不变
sql = (
    table1.update()
    .join(table2)
    .on(table1.uid == table2.tid)
    .set(table1.name, table2.name)
    .where(table1.uid > 10)
)
# 可以看到打印的结果是一样的
print(sql)
# UPDATE "t1" JOIN "t2" ON "t1"."uid"="t2"."tid" SET "name"="t2"."name" WHERE "t1"."uid">10
```

## 占位符

相当于先构建好相应的 SQL 语句，然后驱动在执行的时候会对数据进行替换

```python
from pypika import Table, Query, Parameter

table = Table("t")
sql = (
    Query.into(table)
    .columns("id", "name", "age")
    .insert(Parameter(":1"), Parameter(":2"), Parameter(":3"))
)
print(sql)
# INSERT INTO "t" ("id","name","age") VALUES (:1,:2,:3)

# 看到 VALUES 后面只是相应的占位符，具体的值是多少需要驱动执行的时候传递
# 但是问题来了，不同的驱动的占位符是不同的。有的是 %s，有的是 $1、$2、$3 这种
# 所以需要根据驱动调整占位符，但是 SQLAlchemy 提供了一种通用的方式
from sqlalchemy import text, create_engine

sql = (
    Query.into(table)
    .columns("id", "name", "age")
    .insert(Parameter(":id"), Parameter(":name"), Parameter(":age"))
)
# 传递到 text 中
sql = text(str(sql))
print(sql)  # INSERT INTO "t" ("id","name","age") VALUES (:id,:name,:age)
engine = create_engine("")
engine.execute(sql, id=123, name="xxx", age=16)
```

## 其他用法

### 数据库适配

不同数据库的 SQL  语法会有略微不同，最大的一个不同就是包裹字段所用的符号，MySQL 用的是反引号、PostgreSQL 用的是双引号。而 pypika  不知道要适配什么数据库，所以默认用的是双引号，如果想适配 MySQL 的话，那么应该告诉 pypika 要适配 MySQL。

```python
from pypika import Table, MySQLQuery, PostgreSQLQuery

table = Table("t")
print(
    MySQLQuery.from_(table).select(table.id, table.age)
)
# SELECT `id`,`age` FROM `t`

print(
    PostgreSQLQuery.from_(table).select(table.id, table.age)
)
# SELECT "id","age" FROM "t"
```

看到此时就实现了数据库的适配，除了 MySQL 和 PostgreSQL 之外，pypika 还可以适配其它的数据库：

- MSSQLQuery: 微软的 SqlServer
- OracleQuery: 甲骨文的 Oracle
- VerticaQuery: 列式数据库 Vertica

### 窗口函数

详见：<https://pypika.readthedocs.io/en/latest/3_advanced.html#window-frames>

```python
from pypika import Table, Query, analytics as an

table = Table("t")
sql = Query.from_(table).select(
    an.Sum("amount").over("month").as_("amount_sum"),
    an.Avg("amount").over("month").as_("amount_avg"),
)
print(sql)
"""
SELECT SUM('amount') OVER (PARTITION BY month) "amount_sum",
        AVG('amount') OVER (PARTITION BY month) "amount_avg"
FROM "t"
"""
```

