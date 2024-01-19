HDF5 是一种流行的开源文件格式，用于存储和组织大规模数据，它的优点是组织良好、压缩高效

pytables 是 pandas 读取和写入 HDF5 文件格式所需的库，所以在保存或读取 HDF5 格式的数据时，需要先安装这个库

```bash
pip install pytables
```

将数据保存为 HDF5 文件：

```python
# 设置文件保存的路径和文件名
file_path = './600000.h5'

# 将数据表格 df 保存为 HDF5 文件
df.to_hdf(file_path, key='df', mode='w')
```

`df.to_hdf()` 函数用于将表格 df 保存为 HDF5 文件，参数 file_path 为保存的文件路径和文件名；`key='df'` 将 HDF5 文件中 DataFrame 的键值设置为 `df`， `mode='w'` 为写入模式；代码运行后到指定文件夹就能看到保存好的文件

从 HDF5 文件读取数据：

```python
# 导入 pandas
import pandas as pd

# 从指定文件位置 file_path 导入表格数据
df = pd.read_hdf(file_path)
# 输出数据查看
print(df)
```

`pd.read_hdf()` 函数用于读取 HDF5 文件，参数 file_path 为指定的文件路径和文件名