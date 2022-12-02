```bash
If I go to look to see what release it was in, I normally do:
        $ git describe --contains 0136db586c028f71e7cc21cc183064ff0d5919
        v3.6-rc1~59^2~56^2~76

However, it really showed up first in the 3.5-rc1 kernel release, as can
be seen by doing the following:
        $ git tag --contains 0136db586c028f71e7cc21cc183064ff0d5919
```

指定日期、关键字、作者

- 如两天前的提交历史：`git log --since=2.days`
- 如指定作者为 "BeginMan" 的所有提交: `git log --author=BeginMan`
- 如指定关键字为 "init" 的所有提交：`git log --grep=init`
- 如指定提交者为 "Jack" 的所有提交：`git log --committer=Jack`
- 注意作者与提交者的关系：作者是程序的修改者，提交者是代码提交人。
