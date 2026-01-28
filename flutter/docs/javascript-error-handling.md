# JavaScript 错误栈在 Dart 中的显示

## 问题

当 JavaScript 代码执行出错时，错误信息无法在 Dart 侧显示出来，导致调试困难。

## 根本原因

WebF 的 JavaScript 引擎 **已经捕获了完整的 JavaScript 错误栈**（包括错误类型、消息和堆栈跟踪），但需要在 Dart 侧通过 `WebFController` 的 `onJSError` 回调来接收这些错误信息。

如果没有设置 `onJSError` 回调，JavaScript 错误会被静默忽略，不会显示在 Dart 控制台中。

## 技术细节

### C++ 侧（WebF Bridge）

在 `contrib/webf/bridge/core/executing_context.cc` 的 `ReportError` 函数中：

```cpp
void ExecutingContext::ReportError(JSValueConst error, char** rust_errmsg, uint32_t* rust_errmsg_length) {
  JSContext* ctx = script_state_.ctx();
  if (!JS_IsError(ctx, error))
    return;

  // 获取错误类型、消息和堆栈
  JSValue message_value = JS_GetPropertyStr(ctx, error, "message");
  JSValue error_type_value = JS_GetPropertyStr(ctx, error, "name");
  const char* title = JS_ToCString(ctx, message_value);
  const char* type = JS_ToCString(ctx, error_type_value);

  // 获取完整的堆栈跟踪
  const char* stack = nullptr;
  JSValue stack_value = JS_GetPropertyStr(ctx, error, "stack");
  if (!JS_IsUndefined(stack_value)) {
    stack = JS_ToCString(ctx, stack_value);
  }

  // 将错误类型、消息和堆栈拼接成完整的错误字符串
  if (stack != nullptr) {
    snprintf(message, message_length, "%s: %s\n%s", type, title, stack);
  } else {
    snprintf(message, message_length, "%s: %s", type, title);
  }

  // 将错误报告给 Dart 侧
  dart_error_report_handler_(this, message);

  // ... 清理代码
}
```

### Dart 侧（from_native.dart）

错误通过 FFI 桥接传递到 Dart：

```dart
typedef NativeJSError = Void Function(Double contextId, Pointer<Utf8>);

void _onJSError(double contextId, Pointer<Utf8> charStr) {
  WebFController? controller = WebFController.getControllerOfJSContextId(contextId);
  JSErrorHandler? handler = controller?.onJSError;
  if (handler != null) {
    String msg = charStr.toDartString();
    handler(msg);  // 调用用户设置的回调
  }
  malloc.free(charStr);
}
```

## 解决方案

在创建 `WebFController` 时设置 `onJSError` 回调：

```dart
WebFController(
  routeObserver: kWebfRouteObserver,
  onJSError: (String errorMessage) {
    // errorMessage 包含完整的错误类型、消息和堆栈跟踪
    debugPrint('\n${'=' * 80}');
    debugPrint('❌ JavaScript Error');
    debugPrint('${'=' * 80}');
    debugPrint(errorMessage);
    debugPrint('${'=' * 80}\n');

    // 也可以使用 logger
    appLogger.e('[WebF] JavaScript Error', error: errorMessage);
  },
)
```

## 实施位置

已在 `flutter/lib/widgets/webf_view.dart` 的 `injectWebfBundleAsync` 函数中添加：

```dart
final controller = await WebFControllerManager.instance.addWithPrerendering(
  name: controllerName,
  createController: () => WebFController(
    routeObserver: kWebfRouteObserver,
    onJSError: (String errorMessage) {
      debugPrint('\n${'=' * 80}');
      debugPrint('❌ JavaScript Error in: $controllerName');
      debugPrint('${'=' * 80}');
      debugPrint(errorMessage);
      debugPrint('${'=' * 80}\n');

      appLogger.e('[WebFView] JavaScript Error', error: errorMessage);
    },
  ),
  bundle: WebFBundle.fromUrl(url),
  // ...
);
```

## 测试

创建了测试页面 `use_cases/src/pages/ErrorTestPage.tsx`，可以通过以下方式测试：

1. 访问路由 `/error-test`
2. 点击不同的按钮触发各种类型的 JavaScript 错误
3. 在 Dart/Flutter 控制台中查看完整的错误堆栈

测试场景包括：
- 简单错误（已捕获）
- 未捕获错误
- 嵌套函数调用中的错误
- TypeError
- ReferenceError
- 未处理的 Promise rejection

## 错误消息格式

完整的错误消息格式为：

```
错误类型: 错误消息
  at 函数名 (文件:行:列)
  at 函数名 (文件:行:列)
  at 函数名 (文件:行:列)
  ...
```

例如：
```
Error: This is an UNCAUGHT error - should appear in Dart console with stack trace
  at throwUncaughtError (http://127.0.0.1:5174/src/pages/ErrorTestPage.tsx:23:13)
  at <anonymous> (http://127.0.0.1:5174/src/pages/ErrorTestPage.tsx:22:5)
```

## 其他错误处理选项

除了 `onJSError`，WebFController 还提供：

1. **onJSLog**: 捕获 console.log/warn/error 输出
   ```dart
   onJSLog: (int level, String message) {
     debugPrint('JS Console [$level]: $message');
   }
   ```

2. **onLoadError**: 捕获资源加载错误
   ```dart
   onLoadError: (FlutterError error, StackTrace stackTrace) {
     debugPrint('Load Error: $error');
   }
   ```

3. **LoadingState.onScriptError**: 监听脚本加载和执行错误
   ```dart
   controller.view?.document?.loadingState?.onScriptError((event) {
     debugPrint('Script Error: ${event.parameters}');
   });
   ```

## 注意事项

1. **Promise rejections**: 未捕获的 Promise rejection 可能不会触发 `onJSError`，取决于 JavaScript 环境配置
2. **错误消息长度**: 非常大的堆栈跟踪可能会被截断，但通常足够用于调试
3. **生产环境**: 在生产环境中可以将错误上报到日志服务或崩溃分析平台
4. **性能**: `onJSError` 回调在主线程执行，不应进行耗时操作

## 相关文件

- `flutter/lib/widgets/webf_view.dart` - 添加了 onJSError 回调
- `use_cases/src/pages/ErrorTestPage.tsx` - 错误测试页面
- `contrib/webf/bridge/core/executing_context.cc` - C++ 错误处理
- `contrib/webf/webf/lib/src/bridge/from_native.dart` - Dart FFI 桥接
- `contrib/webf/webf/lib/src/launcher/controller.dart` - WebFController 定义
