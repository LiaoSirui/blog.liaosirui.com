官方文档：<https://github.com/tortoise/aerich>

安装 aerich

```bash
pip install aerich
```

创建 `models.py`, 构建数据模型

```python
from tortoise import Model, fields

class User(Model):
    """ 用户基础信息 """
    name = fields.CharField(max_length=24, description="姓名")
    id_no = fields.CharField(max_length=24, description="身份证号")
```

创建配置 `db.py` 文件，配置 `TORTOISE_ORM`

```python
TORTOISE_ORM = {
    "connections": {"default": "mysql://root:password@localhost/basename"},
    "apps": {
        "models": {
            # models对应上面创建的models.py
            "models": ["aerich.models", "models"], 
            "default_connection": "default",
        },
    },
}
```

生成初始化数据配置， `db.TORTOISE_ORM` 是上面配置 TORTOISE_ORM 的路径

```bash
aerich init -t db.TORTOISE_ORM
```

生成后会生成一个`aerich.ini`文件和一个`migrations`文件夹

```bash
aerich init-db
```

修改数据模型后生成迁移文件

```bash
aerich migrate
# 在后面加 --name=xxx, 可以指定文件名
```

执行迁移

```bash
aerich upgrade
```

回退到上一个版本

```bash
aerich downgrade
```

