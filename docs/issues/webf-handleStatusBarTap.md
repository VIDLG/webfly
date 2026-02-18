# WebFViewController missing handleStatusBarTap after Flutter 3.41.1

## Repository

https://github.com/openwebf/webf

## Environment

- Flutter: 3.41.1 (Dart 3.11.0)
- webf: 0.24.12
- Platform: Android

## Description

After upgrading to Flutter 3.41.1, `webf 0.24.12` fails to compile because `WebFViewController` is missing the `handleStatusBarTap` method required by `WidgetsBindingObserver`.

Flutter 3.41.1 added `handleStatusBarTap()` to `WidgetsBindingObserver`. Since `WebFViewController` uses `implements WidgetsBindingObserver` (not `extends` or `with`), Dart requires all interface members to be explicitly implemented.

## Error

```
webf-0.24.12/lib/src/launcher/view_controller.dart:41:7:
Error: The non-abstract class 'WebFViewController' is missing implementations for these members:
 - WidgetsBindingObserver.handleStatusBarTap
Try to either
 - provide an implementation,
 - inherit an implementation from a superclass or mixin,
 - mark the class as abstract, or
 - provide a 'noSuchMethod' implementation.

class WebFViewController with Diagnosticable implements WidgetsBindingObserver {
      ^^^^^^^^^^^^^^^^^^

flutter/lib/src/widgets/binding.dart:169:8:
Context: 'WidgetsBindingObserver.handleStatusBarTap' is defined here.
  void handleStatusBarTap() {}
       ^^^^^^^^^^^^^^^^^^
```

## Suggested Fix

Add the missing override in `lib/src/launcher/view_controller.dart`, next to the other `WidgetsBindingObserver` stubs (around line 1374):

```dart
@override
void handleStatusBarTap() {}
```

## Affected File

`lib/src/launcher/view_controller.dart:41` — `class WebFViewController with Diagnosticable implements WidgetsBindingObserver`
