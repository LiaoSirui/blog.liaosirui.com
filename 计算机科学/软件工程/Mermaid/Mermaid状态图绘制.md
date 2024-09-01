语法解释：`[*]` 表示开始或者结束，如果在箭头右边则表示结束

```plain
stateDiagram
    [*] --> s1
    s1 --> [*]
```

```mermaid
stateDiagram
    [*] --> s1
    s1 --> [*]
```