# Agents

## Android 目录说明

`android/` 目录由 `flutter_tools/flutter_gen_platforms` 工具生成：

1. 从 `app.pkl` 读取配置
2. 运行 `flutter create` 生成基础 `android/` 目录
3. 从 `platforms/android/` 复制文件到 `android/`，并进行模板变量替换

修改 `android/` 目录时，应优先修改 `platforms/android/` 和 `app.pkl`，以确保修改在重新生成后依然有效。

目前仅考虑 Android 平台，暂不处理 web/windows 等其他平台。

## 命令执行

运行项目命令时，优先使用 `justfile` 中定义的命令。可以用 `just --list` 查看所有可用命令。

## Git 操作

提交代码前应先运行 `just format` 格式化代码。

涉及 `git tag`、`git push`、`git checkout` 等改变工作目录的关键命令时，需先确认后再执行。

使用 `just release` 发布时，只需确认一次即可，无需逐条确认其中的 git 操作。

## Release 流程

项目包含 submodule：`flutter_tools`、`contrib/webf_usecases`、`webfly_packages`。

执行 release 时，需按以下顺序提交：
1. 先检查 submodule 是否有未提交的改动，如有则先在各 submodule 中 commit & push
2. 更新主仓库对 submodule 的引用（`git add <submodule_path>`）
3. 主仓库如有其他变更，需先 commit
4. 执行 `just release`
