添加为项目子模块

```bash
git submodule add --force https://github.com/lxc/lxcfs.git lib/lxcfs

git submodule update --init  
```

将子模块切换到最新的分支

```bash
cd lib/lxcfs

git checkout lxcfs-5.0.2
```

添加 dockerfile 文件

```bash
mkdir -p docker/build

touch docker/build/Dockerfile
```

Dockerfile 内容如下

```dockerfile
```

