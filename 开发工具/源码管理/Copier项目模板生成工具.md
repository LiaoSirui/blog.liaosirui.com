## Copier

Copier 是一个开源的项目模板生成工具，旨在帮助开发者快速创建和管理项目模板。与传统的模板工具不同，Copier 采用了一种增强的方式，允许用户在生成项目时进行更复杂的配置和定制。其核心是基于 Jinja2 模板引擎，支持动态内容生成和变量替换

主要特点

- 版本控制：Copier 可以处理模板的版本管理，用户可以选择特定版本的模板进行生成
- 双向同步：生成的项目可以与原始模板保持同步，支持项目的更新和管理
- 交互式输入：Copier 支持用户在生成项目时通过命令行交互输入变量
- 多种文件类型支持：不仅支持文本文件，还可以处理二进制文件，如图像和其他资源

Copier 的工作流程包括以下几个步骤：

1. 选择模板：用户指定 Copier 模板的路径，可以是本地目录，也可以是远程 Git 仓库
2. 输入参数：在生成项目时，Copier 会提示用户输入一些参数（如项目名称、作者、版本等），这些参数将用于生成项目文件
3. 生成项目：根据模板和用户输入的参数，Copier 会创建一个新项目目录，复制模板中的文件并用用户提供的值替换占位符
4. 双向同步：如果模板发生变化，用户可以选择将更改同步到已生成的项目中

官方：

- Github 仓库：<https://github.com/copier-org/copier>
- 文档：<https://copier.readthedocs.io/en/stable/>

安装

```bash
pipx install copier
# uv tool install copier 
```

## 快速入门

要使用 Copier 创建模板，首先需要定义模板目录结构，并配置一个 `copier.yml` 文件用于模板的配置。下面是一个简单的项目模板结构示例：

```bash
my-template
├── copier.yml
├── main.py.jinja
└── README.md.jinja

0 directories, 3 files
```

`copier.yml` 是模板的配置文件，用于定义项目变量和配置项：

```yaml
# copier.yml 文件

project_name:
  type: str
  help: "请输入项目名称"

author_name:
  type: str
  help: "请输入作者名称"

```

在模板文件中，可以使用 Jinja2 语法动态生成内容，例如 `README.md.jinja` 文件：

```jinja2
# {{ project_name }}

作者: {{ author_name }}

这是一个由 Copier 生成的项目。

```

`main.py.jinja` 文件可以包含一些简单的 Python 代码模板：

```jinja2
# main.py

def main():
    print("欢迎来到 {{ project_name }} 项目，由 {{ author_name }} 创建。")

if __name__ == "__main__":
    main()

```

创建好模板后，可以使用 Copier 生成一个基于该模板的新项目。在终端中运行以下命令，并根据提示输入项目相关信息：

```bash
copier copy ./my-template ./new-project
```

按提示填写信息

```bash
# uv tool run copier copy ./my-template ./new-project
🎤 请输入项目名称
   My New Project
🎤 请输入作者名称
   AlphaQuant

Copying from template version None
    create  README.md
    create  main.py

```

执行完成后，新项目 `new-project` 会包含根据模板生成的文件

其中，`README.md` 的内容将是：

```markdown
# My New Project

作者: AlphaQuant

这是一个由 Copier 生成的项目。

```

`main.py` 的内容将是：

```python
# main.py

def main():
    print("欢迎来到 My New Project 项目，由 AlphaQuant 创建。")

if __name__ == "__main__":
    main()

```

如果模板发生了更改，可以通过 Copier 更新已有项目。运行以下命令，Copier 会自动将模板中的新更改同步到现有项目中：

```bash
copier update ./new-project
```

Copier 会根据模板的更新情况智能合并变更，确保项目文件始终保持最新状态

## 最佳实践

- 保持模板简单：确保模板结构清晰简洁，避免不必要的复杂性
- 文档化：提供清晰的文档，说明如何使用和定制模板
- 使用合理的默认值：在 `copier.yaml` 中为变量提供合理的默认值，减少用户输入的负担
- 定期更新模板：根据用户反馈和需求定期更新模板，确保其现代性和适用性