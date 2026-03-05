先执行 `/commit` 完成所有本地提交，然后推送到远程。

## 额外步骤（commit 完成后）

1. **推送前检查远程**：
   - 运行 `git fetch origin`
   - 运行 `git rev-list HEAD..origin/$(git branch --show-current) --count`
   - 若远程领先（count > 0），提示用户先 `git pull --rebase` 或 `git merge` 同步，再手动 push
   - 若远程无更新（count = 0），执行 `git push`

2. 最后运行 `git status` 确认工作区干净。

## 使用场景

- 完成功能开发，准备推送
- 需要智能拆分多个 commit 并一次性推送
- 直接推送到当前分支（不创建 PR）
