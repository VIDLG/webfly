# WebFly 🚀

[English](README.md) | 简体中文

**WebFly** 是一个强大的基于 Flutter 的 Web 应用启动器和运行时环境，具有原生设备能力。与传统的 Web 容器（如 Expo Go 或 WebF Go）不同，WebFly 提供了与原生设备功能的深度集成，同时保持了 Web 开发的灵活性。

## 🌟 为什么选择 WebFly？

### 内置原生能力

WebFly 不仅仅是一个 Web 浏览器 - 它是一个功能完整的原生运行时，集成了设备 API：

- **🔵 蓝牙低功耗（BLE）** - 通过 `webf_bluetooth` 直接访问 BLE 设备
- **💾 SQLite 数据库** - 使用 `webf_sqflite` 进行本地数据库存储
- **🔗 原生分享** - 通过 `webf_share` 集成系统分享功能
- **📱 原生 UI 组件** - 无缝的 Flutter-Web 混合界面
- **🎯 二维码扫描** - 内置移动扫描器，快速启动应用

### 对比 Expo Go / WebF Go

| 功能特性 | WebFly | Expo Go / WebF Go |
|---------|--------|-------------------|
| **原生 API** | ✅ 预集成（BLE、SQLite、分享） | ❌ 仅限基础 API |
| **自定义原生代码** | ✅ 完全可定制 | ❌ 需要 eject |
| **离线数据库** | ✅ 内置 SQLite | ⚠️ 存储受限 |
| **设备集成** | ✅ 深度原生集成 | ⚠️ 仅基础功能 |
| **开发调试** | ✅ 热重载 + 原生调试 | ✅ 仅热重载 |
| **应用分发** | ✅ 独立 APK/IPA | ⚠️ 需要宿主应用 |

## 🎯 核心特性

### 1. **混合路由系统**
- Web 路由与 Flutter 页面之间无缝导航
- 共享 WebF 控制器以提升性能
- 路由焦点管理和生命周期处理

### 2. **智能 URL 历史**
- 最近访问的 URL 快速访问
- 右滑删除手势
- 编辑模式支持批量操作
- 跨会话持久化历史记录

### 3. **二维码启动器**
- 扫描二维码即时加载应用
- 支持 URL 和路径参数
- 非常适合演示和测试

### 4. **开发者工具**
- WebF 检查器覆盖层用于调试
- JavaScript 控制台集成
- 网络请求监控
- 可配置的设置面板

### 5. **资源 HTTP 服务器**
- 为打包资源提供内置本地服务器
- 开发期间支持热重载
- 高效的资源交付

## 🚀 快速开始

### 前置要求

- Flutter 3.38.7 或更高版本
- Dart SDK ^3.10.7
- Android SDK（用于 Android 构建）

### 安装步骤

1. **克隆仓库**
   ```bash
   git clone https://github.com/your-org/webfly.git
   cd webfly
   ```

2. **安装 Flutter 依赖**
   ```bash
   cd flutter
   flutter pub get
   ```

3. **安装 Web 依赖**（用于示例用例）
   ```bash
   pnpm install
   ```

4. **运行应用**
   ```bash
   # 从根目录
   pnpm flutter

   # 或从 flutter 目录
   flutter run
   ```

## 📱 使用方法

### 启动 Web 应用

**方法 1：手动输入 URL**
- 输入 bundle URL（例如：`http://example.com/bundle.js`）
- 可选择在高级选项中指定自定义路径
- 点击"启动"开始运行

**方法 2：扫描二维码**
- 点击二维码图标
- 扫描包含 bundle URL 的二维码
- 应用自动启动

**方法 3：历史记录**
- 点击任意最近的 URL 填充输入框
- 点击箭头按钮直接启动
- 向左滑动删除条目

### 在 Web 应用中使用原生 API

```javascript
// 蓝牙 LE 扫描
if (window.webf?.bluetooth) {
  const devices = await window.webf.bluetooth.scan();
  // 连接并与 BLE 设备交互
}

// SQLite 数据库
if (window.webf?.sqflite) {
  const db = await window.webf.sqflite.openDatabase('mydb.db');
  await db.execute('CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, name TEXT)');
}

// 原生分享
if (window.webf?.share) {
  await window.webf.share.share({
    title: '看看这个！',
    text: '具有原生功能的超棒 Web 应用',
    url: 'https://example.com'
  });
}
```

## 🛠️ 开发指南

### 项目结构

```
webfly/
├── flutter/                 # Flutter 应用
│   ├── lib/
│   │   ├── pages/          # 应用页面
│   │   │   └── launcher/   # 启动器页面及组件
│   │   ├── services/       # 业务逻辑
│   │   ├── widgets/        # 可复用组件
│   │   └── router/         # 导航配置
│   ├── assets/             # 图片、Logo
│   └── pubspec.yaml        # Flutter 依赖
│
├── src/                    # Web 应用开发
│   └── pages/              # 示例 Web 页面
│
└── contrib/                # WebF 贡献
    └── webf/               # WebF 引擎源码
```

### 从源码构建

**Android APK**
```bash
cd flutter
flutter build apk --release
```

**Android App Bundle**
```bash
flutter build appbundle --release
```

### 自定义开发

**添加自定义原生插件：**
1. 将插件依赖添加到 `flutter/pubspec.yaml`
2. 在 `services/` 中与 WebF bridge 集成
3. 将 API 暴露到 JavaScript 上下文

**修改 UI 主题：**
- 编辑 `flutter/lib/main.dart` 修改应用全局主题
- 在 `pages/launcher/widgets/` 中自定义启动器组件

## ⚙️ 配置说明

### 应用设置

通过启动器中的设置按钮（⚙️）访问：

- **WebF 检查器**：启用/禁用开发者覆盖层
- **缓存控制器**：在导航之间保持 WebF 控制器活跃

### Bundle 服务器

在开发时，内置 HTTP 服务器从以下位置提供资源：
- 端口：自动分配（查看控制台日志）
- 基础 URL：`http://localhost:{port}/`
- 资源路径：`flutter/assets/use_cases/`

## 📦 依赖项

### 核心依赖
- `webf: ^0.24.6` - Web 渲染引擎
- `hooks_riverpod: ^3.2.0` - 状态管理
- `go_router: ^17.0.1` - 导航

### 原生能力
- `webf_bluetooth: ^1.0.0` - BLE 支持
- `webf_sqflite: ^1.0.1` - SQLite 数据库
- `webf_share: ^1.1.0` - 原生分享
- `mobile_scanner: ^7.1.4` - 二维码扫描

### 工具库
- `shared_preferences: ^2.5.4` - 本地存储
- `shelf: ^1.4.2` - HTTP 服务器

## 🤝 贡献指南

欢迎贡献！请随时提交 Pull Request。

## 📄 许可证

[在此添加您的许可证]

## 🙏 致谢

基于 [WebF](https://github.com/openwebf/webf) 构建 - 高性能的 Flutter Web 渲染引擎。

---

**用 ❤️ 为需要原生能力和 Web 灵活性的开发者打造**
