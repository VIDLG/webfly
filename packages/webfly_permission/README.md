# webfly_permission

WebF native module for permission_handler (Dart + TS). Depends on **permission_handler** and **webf**.

## Usage

Add to your app (with permission_handler and webf):

```yaml
dependencies:
  permission_handler: ^12.0.1
  webfly_permission:
    path: ../packages/webfly_permission
  webf: ^0.24.11
```

**Dart:** register the module:

```dart
import 'package:webfly_permission/webfly_permission.dart' show PermissionHandlerWebfModule;

WebF.defineModule((context) => PermissionHandlerWebfModule(context));
```

**TypeScript:** alias `@native/webf/permission` (or your path) to `packages/webfly_permission/lib/webfly_permission`, then:

```ts
import { checkStatus, request, openAppSettings, isWebfError } from '@native/webf/permission';
```

## License

Same as the parent project.
