## 框架简介

Tortoise ORM 是一个易于使用的 asyncioORM （对象关系映射器）

安装

```bash
pip install tortoise-orm

# 安装数据库驱动
pip install tortoise-orm[asyncpg]
pip install tortoise-orm[aiomysql]
pip install tortoise-orm[asyncmy]
```

## 框架使用

### 数据库连接

- SQLite

通常采用以下形式`sqlite://DB_FILE`

```python
"sqlite:///data/db.sqlite3"
```

- MySQL

```python
"mysql://user:password@host:3306/somedb"
```

- PostgreSQL

```python
# 异步
"asyncpg://postgres:pass@db.host:5432/somedb"

# 同步
"psycopg://postgres:pass@db.host:5432/somedb"
```

### 创建数据库

```python
from tortoise import Tortoise, run_async

async def init():
    # Here we create a SQLite DB using file "db.sqlite3"
    #  also specify the app name of "models"
    #  which contain models from "app.models"
    await Tortoise.init(
        db_url='sqlite://db.sqlite3',
        modules={'models': ['models']}
    )
    # Generate the schema
    await Tortoise.generate_schemas()  # safe：仅在表不存在时创建表

run_async(init())  # 会自动进入上下文处理，在运行完成时，自动关闭数据库连接
```

### 创建模型

```python
from tortoise.models import Model
from tortoise.manager import Manager

class Team(Model):
    id = fields.IntField(pk=True)
    name = fields.TextField()

    class Meta:
        abstract = False
        table = "team"
        table_description = ""
        unique_together = ()
        indexes = ()
        ordering = []
        manager = Manager

```

- abstract：设置为 True 表明这是一个抽象类，不会生成数据表
- table：设置表名，不设置默认已类名作为数据表名
- table_description：设置此项可为为当前模型创建的表生成注释消息
- unique_together : 指定 unique_together 为列集设置复合唯一索引，其为元组的元组
- indexes：指定 indexes 为列集设置复合非唯一索引，它应该是元组的元组
- ordering：指定 ordering 为给定模型设置默认排序。`.order_by(...)` 它应该可以迭代以与接收相同的方式格式化的字符串
- manager：指定 manager 覆盖默认管理器。它应该是实例 `tortoise.manager.Manager` 或子类

### 字段

官方文档：<https://tortoise-orm.readthedocs.io/en/latest/fields.html>

（1）数据字段

```python
Field（source_field = None , generated = False , pk = False , null = False , default = None , unique = False , index = False , description = None , model = None , validators = None , ** kwargs)
```

- `source_field (Optional[str])`: 如果 DB 列名称需要是特定的而不是从字段名称中生成，则提供 source_field 名称
- `generated (bool)`: 该字段是否由数据库生成
- `pk (bool)`: 该字段是否为主键
- `null (bool)`: 主键是否可以为空
- `default (Optional[Any]`)：该字段的默认值
- `unique (bool)` ：该字段的值是否唯一
- `index (bool)`：设置该字段是否为索引
- `description (Optional[str])` ：字段描述，也将出现在`Tortoise.desc> ribe_model()`生成的 DDL 中并作为 DB 注释出现
- `validators (Optional[List[Union[Validator, Callable]]])` ：此字段的验证器

（2）关系字段

```python
ForeignKeyField( model_name , related_name = None , on_delete = 'CASCADE' , db_constraint = True , ** kwargs )

OneToOneField( model_name , related_name = None , on_delete = 'CASCADE' , db_constraint = True , ** kwargs )
```

- `model_name`：关联模型的名称 `{app}.{models}`
- `related_name`：相关模型上的属性名称，用于反向解析外键
- `on_delete`：
- `field.CASCADE`：表示如果相关模型被删除，该模型应该被级联删除
- `field.RESTRICT`：表示只要有外键指向，相关模型删除就会受到限
- `field.SET_NULL`：将字段重置为 NULL，以防相关模型被删除。仅当字段已设置时才能`null=True`设置
- `field.SET_DEFAULT`：将字段重置为default值，以防相关模型被删除。只能设置是字段有一个default 集合
- `to_field`：建立外键关系的相关模型上的属性名。如果未设置，则使用 pk
- `db_constraint`： 控制是否应在数据库中为此外键创建约束。默认值为 True，将此设置为 False 可能对数据完整性非常不利

```python
ManyToManyField(model_name, through=None, forward_key=None, backward_key='', related_name='', on_delete='CASCADE', db_constraint=True, **kwargs)
```

- `through`：通过中间表进行连接
- `forward_key`： 直通表上的正向查找键。默认值通常是安全的
- `backward_key`： 通表上的向后查找键。默认值通常是安全的

### 查询

模型本身有几种方法可以启动查询：

- `filter(*args, **kwargs)`：使用给定的过滤器创建 QuerySet
- `exclude(*args, **kwargs)`：使用给定的排除过滤器创建 QuerySet
- `all()`：创建不带过滤器的查询集
- `first()`：创建仅限于一个对象的查询集并返回实例而不是列表
- `annotate()`： 使用额外的函数/聚合对结果进行再过滤

其中`filter`可以指定的对象：

- `in`：检查字段的值是否在传递列表中
- `not_in`: 检查字段的值是不在传递列表中
- `gte`：大于或等于传递的值
- `gt`：大于传递值
- `lte`：低于或等于传递的值
- `lt`：低于通过值
- `range`：介于和给定两个值之间
- `isnull`：字段为空
- `not_isnull`：字段不为空
- `contains`：字段包含指定的子字符串
- `icontains`：不区分大小写contains
- `startswith`：如果字段以值开头
- `istartswith`：不区分大小写startswith
- `endswith`：如果字段以值结尾
- `iendswith`：不区分大小写endswith
- `iexact`：不区分大小写等于
- `search`：全文搜索

### Q 对象

```python
Q( * args , join_type = 'AND' , ** kwargs )
```

- `join_type`：连接类型，`OR\AND`
- `args ( Q)` ：Q要包装的内部表达式
- `kwargs ( Any)` ：此 Q 对象应封装的过滤语句