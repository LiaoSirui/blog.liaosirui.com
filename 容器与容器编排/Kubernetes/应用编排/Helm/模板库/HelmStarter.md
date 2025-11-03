`helm create` 命令采用可选 `--starter` 选项，可以指定 "起始chart"。

起始 chart 只是普通的 chart，位于 `$HELM_HOME/starters`。作为 chart 开发人员，可以创作专门设计用作起始的chart。

记住这些chart时应考虑以下因素：

- Chart.yaml 将被生成器覆盖。
- 用户将期望修改这样 的chart 内容，因此文档应该指出用户如何做到这一点。
- 所有匹配项将被替换为指定的 chart 名称，以便起始 chart 可用作模板。
- 目前添加 chart 的唯一方法是手动将其复制到 `$HELM_HOME/starters`。在 chart 的文档中，你需要解释该过程。

