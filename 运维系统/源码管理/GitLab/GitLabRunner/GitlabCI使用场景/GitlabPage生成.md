`Gitlab` 会自动将 `public` 目录下的文件进行发布成 `Gitlab Page`。下面放一个最简单的例子，整个仓库的目录结构如下所示，有一个 `.gitlab-ci.yml` 的配置文件，将 `html` 文件放在 `source` 文件夹里面：

`public` 文件夹中必须有 `index.html` 文件。这里`index.html`可以随意写一下就可以

主要来看一下 `.gitlab-ci.yml` 的配置文件，里面有 `mkdir public` 来创建 public 文件夹。

