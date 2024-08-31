CSV(Comma Separated Values) 是一个非常普遍和有用的简单数据格式，用于存储表格数据

将数据保存为CSV文件：

```python
# 设置文件保存的路径和文件名
file_path = './600000.csv'

# 将数据表格 df 保存为 CSV 文件
df.to_csv(file_path, encoding='utf-8')  
```

`df.to_csv()` 函数用于将表格 df 保存为 CSV 文件，参数 file_path 为保存的文件路径和文件名，`encoding='utf-8'` 为指定写入文件的编码，不然会出现中文乱码；代码运行后到指定文件夹就能看到保存好的文件

从 CSV 文件读取数据：

```python
# 导入 pandas
import pandas as pd  

# 从指定文件位置 file_path 导入表格数据
df = pd.read_csv(file_path, encoding='utf-8')
# 输出数据查看
print(df)
```

`pd.read_csv()` 函数用于读取 CSV 文件，参数 file_path 为指定的文件路径和文件名，`encoding='utf-8'` 为指定文件编码，与保存时的编码一致，不然会出错