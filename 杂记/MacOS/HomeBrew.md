
## 官网

<https://brew.sh/>

## 使用

### 安装

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 查看帮助信息

```bash
brew help
```

### 查看版本

```bash
brew -v
```

### 更新 Homebrew

```bash
brew update
```

### 安装软件包

```bash
brew install [包名]

# 安装git
brew install git

# 安装git-lfs
brew install git-lfs

# 安装wget
brew install wget

# 安装openssl
brew install openssl
```

### 查询可更新的包

```bash
brew outdated
```

### 更新包 (formula)

```bash
# 更新所有
brew upgrade

# 更新指定包
brew upgrade [包名]
```

### 清理旧版本

```bash
# 清理所有包的旧版本
brew cleanup 

# 清理指定包的旧版本
brew cleanup [包名]

# 查看可清理的旧版本包，不执行实际操作
brew cleanup -n
```

### 锁定不想更新的包

```bash
# 锁定某个包
brew pin $FORMULA

# 取消锁定
brew unpin $FORMULA
```

### 卸载安装包

```bash
brew uninstall [包名]

# 例：卸载git
brew uninstall git
```

### 查看包信息

```bash
brew info [包名]
```

### 查看安装列表

```bash
brew list
```

### 查询可用包

```bash
brew search [包名]

# 查询 go 包
brew search go

# 列出版本
brew versions go
```

### 卸载Homebrew

```bash
cd `brew --prefix`
rm -rf Cellar
brew prune
rm `git ls-files`
rm -r Library/Homebrew Library/Aliases Library/Formula Library/Contributions
rm -rf .git
rm -rf ~/Library/Caches/Homebrew
```
