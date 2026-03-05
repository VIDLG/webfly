分析当前 git 变更并创建 commit（不推送到远程）。

## 步骤

1. 并行运行以下命令了解当前状态：
   - `git status`
   - `git diff HEAD`（已暂存 + 未暂存）
   - `git log --oneline -5`（参考已有 commit 风格）

2. 分析变更，决定拆分策略：
   - 所有变更属于同一个逻辑单元 → **一个 commit**
   - 变更明显跨越多个独立关注点 → **拆分为多个 commit**，逐组暂存并提交

   优先少拆。只有在变更真正不相关时才拆（例如 bug 修复混入了新功能）。

3. **检查 README 是否需要同步更新**（README.md + README.zh-CN.md）：
   - 读取两份 README，对照本次变更判断是否涉及以下区域：
     - 新增/移除功能或模块
     - 命令变更（justfile recipe、pnpm script）
     - 配置项变更（.env 变量、app settings）
     - 依赖变更（新增/升级/移除 package）
     - 项目结构变更（目录新增/重命名）
   - 若需要更新：修改对应段落，保持中英文 README 内容同步，更新完后将 README 文件一起纳入本次 commit
   - 若无需更新：跳过

4. 对每个 commit：
   - 用 `git add <具体文件>` 只暂存相关文件，不用 `git add -A` 或 `git add .`
   - 撰写简洁的 commit message（祈使句，72 字符以内，说明"为什么"而非"做了什么"）
   - commit body 附加 `Co-Authored-By: Claude <model> <noreply@anthropic.com>`（根据当前实际模型填写，如 Opus 4.6、Sonnet 4.6、Haiku 4.5）
   - 用 HEREDOC 传入 message

5. 最后运行 `git status` 确认工作区干净。

> **注意**：README 更新应合并到产生该变更的 commit 中，不要单独拆出 `docs:` commit。

## 约束

- 禁止 `git add -A` 或 `git add .`，必须指定具体文件
- 禁止 `--no-verify`
- 禁止 amend 已有 commit
- 禁止 force push
- 若 pre-commit hook 失败，修复问题后用新 commit 重试

## 使用场景

- 日常开发提交（本地 commit）
- 需要智能拆分多个 commit
- 想先 review 再 push
