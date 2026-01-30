# WebF-Flutter 主题双向同步

## 概述

本文档说明如何实现 WebF 和 Flutter 之间的双向主题同步，确保用户在任一端改变主题时，另一端也能自动更新。

## 问题

根据 [WebF 官方文档](https://openwebf.com/en/docs/add-webf-to-flutter/advanced-topics/theming)，WebF 支持：

1. **Flutter → WebF**：通过 `darkModeOverride` 属性同步主题
2. **系统主题自动同步**：WebF 自动检测系统主题变化

但是，当用户在 **WebF 侧**（如 SettingsPage）改变主题时，需要同步回 Flutter，否则：
- Flutter 侧的主题状态不会更新
- 重新打开应用时，主题可能不一致
- Launcher 页面的主题设置和 WebF 页面不一致

## 解决方案

实现双向同步机制，使用**混合方案**结合两种通信方式：

### Flutter → WebF（使用 darkModeOverride + CustomEvent）

**双重机制确保可靠性：**

1. **darkModeOverride**：官方推荐方式，更新 `prefers-color-scheme` media query
2. **CustomEvent**：标准 Web API，事件驱动，React 友好

```dart
void syncThemeToWebF(WebFController controller, ThemeMode themeMode) {
  // 1. 使用 darkModeOverride（官方推荐）
  switch (themeMode) {
    case ThemeMode.light:
      controller.darkModeOverride = false;
      break;
    case ThemeMode.dark:
      controller.darkModeOverride = true;
      break;
    case ThemeMode.system:
      controller.darkModeOverride = null; // 自动同步系统主题
      break;
  }
  
  // 2. 同时 dispatch CustomEvent（标准 Web API）
  view.evaluateJavaScript('''
    window.dispatchEvent(new CustomEvent('flutter-theme-changed', {
      detail: { theme: '$themeString' },
      bubbles: true
    }));
  ''');
}
```

**为什么使用 CustomEvent？**
- ✅ 标准 Web API（[MDN CustomEvent](https://developer.mozilla.org/en-US/docs/Web/API/CustomEvent)）
- ✅ 事件驱动，符合 React 响应式模式
- ✅ 可以传递数据（detail 属性）
- ✅ 无需轮询，实时响应

### WebF → Flutter（使用 Native Module）

使用 WebF Native Module API，让 JavaScript 直接调用 Flutter 方法：

1. **Flutter 侧**：创建 `ThemeModule` 继承 `WebFBaseModule`，实现 `invoke` 方法
2. **WebF 侧**：使用 `webf.invokeModule('Theme', 'setTheme', ['light'])` 直接调用

**为什么使用 Native Module？**
- ✅ 直接方法调用，无需轮询
- ✅ 官方推荐的 JavaScript → Flutter 通信方式
- ✅ 类型安全，性能更好
- ✅ 支持异步操作和返回值

## 实现细节

### Flutter 侧（ThemeModule）

创建 Native Module，实现 `invoke` 方法：

```dart
class ThemeModule extends WebFBaseModule {
  ThemeModule(super.manager);

  @override
  String get name => 'Theme';

  @override
  dynamic invoke(String method, List<dynamic> arguments) {
    switch (method) {
      case 'setTheme':
        if (arguments.isEmpty) return Future.value(false);
        final theme = arguments[0] as String;
        return _setTheme(theme);
      default:
        return Future.value(false);
    }
  }

  Future<bool> _setTheme(String theme) async {
    ThemeMode newThemeMode;
    switch (theme.toLowerCase()) {
      case 'light':
        newThemeMode = ThemeMode.light;
        break;
      case 'dark':
        newThemeMode = ThemeMode.dark;
        break;
      case 'system':
        newThemeMode = ThemeMode.system;
        break;
      default:
        return false;
    }

    if (themeModeSignal.value != newThemeMode) {
      themeModeSignal.value = newThemeMode;
      return true;
    }
    return true;
  }
}
```

在 `main.dart` 中注册模块：

```dart
WebF.defineModule((context) => ThemeModule(context));
```

### WebF 侧（ThemeContext.tsx）

**监听 Flutter 主题变化（CustomEvent）：**

```typescript
// Listen to Flutter theme changes via CustomEvent (Flutter → JavaScript)
useEffect(() => {
  if (typeof window === 'undefined') return

  const handleFlutterThemeChange = (event: CustomEvent) => {
    const newTheme = event.detail?.theme as ThemePreference | undefined
    if (newTheme && ['light', 'dark', 'system'].includes(newTheme)) {
      setThemePreferenceState(newTheme)
    }
  }

  window.addEventListener('flutter-theme-changed', handleFlutterThemeChange as EventListener)
  return () => {
    window.removeEventListener('flutter-theme-changed', handleFlutterThemeChange as EventListener)
  }
}, [])
```

**通知 Flutter 主题变化（Native Module）：**

```typescript
const setThemePreference = useCallback(async (preference: ThemePreference) => {
  setThemePreferenceState(preference)
  
  // Call Flutter ThemeModule.setTheme via WebF Native Module API
  // Native Module is the recommended way for JavaScript → Flutter communication
  if (typeof window !== 'undefined') {
    try {
      const webf = (window as any).webf
      if (webf && typeof webf.invokeModule === 'function') {
        await webf.invokeModule('Theme', 'setTheme', [preference])
      }
    } catch (e) {
      console.warn('[ThemeContext] Failed to sync theme to Flutter:', e)
    }
  }
}, [])
```

## 工作流程

### 用户在 Launcher 改变主题

1. 用户选择主题 → `themeModeSignal.value = ThemeMode.light`
2. Flutter 自动保存到 `SharedPreferences`
3. `_syncThemeToWebF` 设置 `controller.darkModeOverride = false`
4. WebF 更新 `prefers-color-scheme` media query
5. React `ThemeContext` 监听到变化，更新 UI

### 用户在 WebF SettingsPage 改变主题

1. 用户选择主题 → `setThemePreference('light')`
2. WebF 调用 `webf.invokeModule('Theme', 'setTheme', ['light'])`
3. Flutter `ThemeModule.invoke` 立即处理请求
4. Flutter 更新 `themeModeSignal.value = ThemeMode.light`
5. Flutter 自动保存到 `SharedPreferences`
6. `_syncThemeToWebF` 设置 `controller.darkModeOverride = false`
7. WebF 更新 `prefers-color-scheme` media query
8. React `ThemeContext` 监听到变化，更新 UI

## 性能考虑

- **直接方法调用**：使用 Native Module API，无需轮询，响应即时
- **异步处理**：`invokeModule` 返回 Promise，可以处理异步操作
- **错误处理**：JavaScript 侧可以 catch 错误，Flutter 侧记录日志

## 注意事项

1. **Native Module**：使用 WebF 官方推荐的 Native Module API，比轮询更高效
2. **即时响应**：主题变化立即同步，无延迟
3. **全局可用**：Native Module 在所有 WebF controller 中都可以使用
4. **类型安全**：Flutter 侧可以验证参数类型，JavaScript 侧可以处理返回值

## 相关文档

- [WebF 官方主题文档](https://openwebf.com/en/docs/add-webf-to-flutter/advanced-topics/theming)
- [WebF CSS Display 约束](./webf-css-display-constraints.md)
