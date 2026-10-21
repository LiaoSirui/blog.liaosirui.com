## Python 测试数据生成库

Faker 是一个 Python软件包，可以成伪造数据。 无论是需要导入数据库，创建美观的 XML 文档，填充数据进行压力测试

- <https://github.com/joke2k/faker>
- <https://faker.readthedocs.io/>

## 基础用法

```python
from faker import Faker
fake = Faker('zh-CN') # 生成中文资料，默认为英文

fake.name() # 姓名
# '唐兵'

fake.user_agent() # 用户代理
# 'Mozilla/5.0 (compatible; MSIE 5.0; Windows NT 4.0; Trident/5.1)'
```



