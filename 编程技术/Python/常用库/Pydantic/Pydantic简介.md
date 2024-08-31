使用 pydantic 为 Python 代码做类型标注和限制

```python
from pydantic import BaseModel


class ModelTypeError(Exception):
    pass


class ModelAttrError(Exception):
    pass


class MyBaseModel(BaseModel):
    """
    带类型和只读属性拦截
        a: int = Field(read_only=True)
    """

    def __setattr__(self, key, value):
        fields = self.__fields__
        field = fields.get(key) or dict()
        extra = field.field_info.extra

        if extra.get("read_only"):
            raise ModelTypeError("Read only field:{}".format(key))
        if field.type_ != type(value):
            raise ModelAttrError("Field type error:{}".format(key))
        super.__setattr__(self, key, value)


```

测试代码

```python
class A(MyBaseModel):
    a: int = Field(read_only=True)
    b: int = Field(read_only=False)


a = A(a=45, b=34)
a.a = 3
print(a.a)

a.b = "3"
print(a.b)

a.b = 88
print(a.b)

print(a.json())
```

