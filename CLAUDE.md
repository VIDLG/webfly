# CLAUDE.md

本文件为 Claude Code (claude.ai/code) 在此仓库中工作时提供指引。

## 项目概述

WebFly 是基于 Flutter 的混合运行时，通过 [WebF](https://github.com/openwebf/webf) 在原生外壳中渲染 React Web 应用。Flutter 宿主提供原生能力（BLE、权限、SQLite、分享），通过模块调用桥接层暴露给 Web 层。

## Monorepo 结构

- **`lib/`** — Flutter/Dart 宿主应用（启动器、路由、Asset HTTP Server、WebF 模块注册）
- **`webfly_packages/`** — 功能包，每个包含 Dart + TypeScript 双端代码：
  - `webfly_bridge/` — 通信格式 + `createModuleInvoker` / `WebfModuleEventBus`
  - `webfly_ble/` — BLE 模块（封装 `flutter_blue_plus`）
  - `webfly_permission/` — 权限模块（封装 `permission_handler`）
  - `webfly_theme/` — 主题模块
- **`frontend/`** — React + Vite Web 应用（在 WebF 中运行的 UI）
- **`contrib/webf_usecases/`** — 示例用例应用（React 和 Vue）
- **`flutter_tools/`** — 基于 Rust 的构建/发布工具，通过 `just` 调用
- **`platforms/`** — 平台模板（Android manifest、签名配置）

## Android 目录说明

`android/` 目录由 `flutter_tools/flutter_gen_platforms` 工具生成：从 `app.pkl` 读取配置 → `flutter create` 生成基础目录 → 从 `platforms/android/` 复制并替换模板变量。修改 `android/` 时应优先改 `platforms/android/` 和 `app.pkl`。目前仅考虑 Android 平台。

## 构建与开发命令

优先使用 `justfile` 中定义的命令，`just --list` 查看所有可用命令。

### 根目录（需要 `just` 任务运行器）

```sh
just update              # 安装工具 + flutter pub get + hooks
just codegen             # Dart build_runner（root + webfly_ble）
just android             # 在 Android 设备上运行（debug），长驻进程，日志输出到 logs/
just android release     # Release 模式运行，长驻进程，日志输出到 logs/
just build-apk           # Release APK（含混淆）
just test                # Flutter 测试
just test-frontend       # 前端 vitest
just test-all            # 全部测试
just format              # dart format lib test
just format-check        # CI 格式检查门禁
just analyze             # flutter analyze（别名 `just lint`）
just ci                  # 完整 CI 流水线
```

### 前端（`frontend/`）

```sh
pnpm dev                 # Vite 开发服务器（自动端口 5173 起，打印二维码）
pnpm build               # tsc -b && vite build
pnpm lint                # ESLint
pnpm test                # Vitest
pnpm check:webf-css      # WebF CSS 约束检查
```

## 架构

```
Flutter 宿主  ──WebF Runtime──▶  React App (Vite bundle)
     │                               │
     │  webf.invokeModuleAsync()     │  @webfly/ble, @webfly/permission
     │◀──────────────────────────────│  (TS 类型封装, neverthrow Result)
     │
     ├─ Asset HTTP Server (shelf, 自动端口)
     ├─ GoRouter (原生页面 + WebF 视图)
     └─ WebF Modules 在 lib/main.dart 中注册
```

- **原生 → Web**：模块在 Dart 中定义（`WebF.defineModule`），TS 端通过 `webf.invokeModuleAsync(moduleName, method, ...args)` 调用
- **事件总线**：`WebfModuleEventBus` 用于订阅（如 BLE 扫描结果流式传输）
- **路由**：GoRouter（Flutter 端）管理原生/WebF 页面；React Router 管理 Web 应用内部路由。路由焦点追踪确保正确的 WebF 控制器处于活跃状态
- **状态管理**：Dart 端用 `signals_flutter`；Web 端用 `zustand` + `@tanstack/react-query`

## 关键约定

### TypeScript / 前端

- **严格 TypeScript** — `strict: true`、`noUnusedLocals`、`noUnusedParameters`、`verbatimModuleSyntax`
- **路径别名** — `@webfly/ble`、`@webfly/permission`、`@webfly/theme` 解析到 `../webfly_packages/*/lib/`
- **错误处理** — `neverthrow` Result 类型，ESLint 强制执行（`must-use-result: error`）
- **React Compiler** 通过 `babel-plugin-react-compiler` 启用

### WebF CSS 约束

WebF 仅支持 CSS 子集，项目在构建时强制检查：
- Tailwind **preflight 已禁用**（会注入不支持的属性）
- **Opacity 插件已禁用**（`textOpacity`、`backgroundOpacity`、`borderOpacity` 等）
- **Dark mode**：必须使用 `media` 策略（非 `class`）
- 运行 `just webf-check-css` 验证 CSS 属性是否符合 WebF 白名单

### Dart / Flutter

- **状态管理**：`signals` / `signals_flutter`（非 Provider/Bloc）
- **日志**：`talker`（全局实例）
- **代码生成**：`build_runner` — 修改带注解的类后需运行 `just codegen`（尤其是 `webfly_ble`）

## Git 操作

提交前先运行 `just format` 格式化代码。Commit message 遵循 Conventional Commits 规范：

```
<type>(<scope>): <description>

[optional body]
```

常用 type：`feat`、`fix`、`docs`、`refactor`、`style`、`test`、`chore`。message 应包含新增文件、功能修改等关键信息。

涉及 `git tag`、`git push`、`git checkout` 等改变工作目录的关键命令时，需先确认后再执行。

## Release 流程

当用户说"release"时，**必须使用 `just release [major|minor|patch]`**（默认 patch），不要手动执行 git tag / push 等操作。该命令会自动完成格式化、版本号递增、commit、打 tag 并推送。

执行 release 前：

1. 检查 submodule（`flutter_tools`、`contrib/webf_usecases`、`webfly_packages`）是否有未提交改动，有则先在各 submodule 中 commit & push
2. 更新主仓库对 submodule 的引用（`git add <submodule_path>`）
3. 检查自上次 release 以来的所有变更（`git log <last-tag>..HEAD`），判断 README（EN + CN）是否需要同步更新（新功能、命令变更、配置变更等），需要则更新并 commit
4. 主仓库如有其他变更，先 commit
5. 执行 `just release`、`just release minor` 或 `just release major`

## LED 特效系统

特效位于 `frontend/public/effects/{effectId}/`，包含：
- `meta.json` — 名称、描述
- `ui.json` — JSON-render 规格（参数 UI）+ 可选 `bridge`/`speed` 配置
- `effect.ts` — 特效逻辑（运行时通过 Babel `typescript` + `transform-modules-commonjs` 编译）

运行时代码（`effect-runtime.ts`）提供 `createBaseMachine`、`makeBlank`、`toRgb`、`hsvToRgb`。特效导出 `createEffect` 函数，返回 `EffectMachine`。

`EffectRenderer` 编译并运行特效；`DeviceCanvasView` 在 canvas 上以 50ms 轮询渲染设备 LED 布局。

<!-- webf-agents:init start -->
## WebF Claude Code Skills

Source: `@openwebf/claude-code-skills@1.0.3`

### Skills
- `webf-api-compatibility` — Check Web API and CSS feature compatibility in WebF - determine what JavaScript APIs, DOM methods, CSS properties, and layout modes are supported. Use when planning features, debugging why APIs don't work, or finding alternatives for unsupported features like IndexedDB, WebGL, float layout, or CSS Grid. (`.claude/skills/webf-api-compatibility/SKILL.md`)
- `webf-async-rendering` — Understand and work with WebF's async rendering model - handle onscreen/offscreen events and element measurements correctly. Use when getBoundingClientRect returns zeros, computed styles are incorrect, measurements fail, or elements don't layout as expected. (`.claude/skills/webf-async-rendering/SKILL.md`)
- `webf-native-plugin-dev` — Develop custom WebF native plugins based on Flutter packages. Create reusable plugins that wrap Flutter/platform capabilities as JavaScript APIs. Use when building plugins for native features like camera, payments, sensors, file access, or wrapping existing Flutter packages. (`.claude/skills/webf-native-plugin-dev/SKILL.md`)
- `webf-native-ui` — Setup and use WebF's Cupertino UI library to build native iOS-style UIs with pre-built components instead of crafting everything with HTML/CSS. Use when building iOS apps, adding native UI components, or improving UI performance. (`.claude/skills/webf-native-ui/SKILL.md`)
- `webf-routing-setup` — Setup hybrid routing with native screen transitions in WebF - configure navigation using WebF routing instead of SPA routing. Use when setting up navigation, implementing multi-screen apps, or when react-router-dom/vue-router doesn't work as expected. (`.claude/skills/webf-routing-setup/SKILL.md`)

### References
- `webf-api-compatibility`: `.claude/skills/webf-api-compatibility/alternatives.md`, `.claude/skills/webf-api-compatibility/reference.md`
- `webf-async-rendering`: `.claude/skills/webf-async-rendering/examples.md`
- `webf-native-ui`: `.claude/skills/webf-native-ui/reference.md`
- `webf-routing-setup`: `.claude/skills/webf-routing-setup/cross-platform.md`, `.claude/skills/webf-routing-setup/examples.md`
<!-- webf-agents:init end -->
