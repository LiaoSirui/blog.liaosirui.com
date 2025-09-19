## 简介

pypika：SQL 语句生成器

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

