# webfly-bridge-dev

Develop new WebFly native modules that bridge Flutter/Dart capabilities to the React/TypeScript frontend via the WebF runtime.

## When to Use

- Adding a new native capability (e.g., camera, sensors, file access)
- Wrapping an existing Flutter package for use in the web layer
- Creating a module with bidirectional method invocation + event streaming

## Module Architecture

```
Flutter Host (Dart)                    React App (TypeScript)
┌──────────────────┐                   ┌──────────────────┐
│ MyWebfModule     │   WebF Runtime    │ @webfly/my       │
│  invoke(method)  │◀─────────────────▶│  invoke<T>(m)    │
│  dispatchEvent() │──────────────────▶│  EventBus        │
└──────────────────┘                   └──────────────────┘
         │                                      │
    webfly_bridge                          webfly_bridge
    (webfOk/webfErr)                (createModuleInvoker/EventBus)
```

## Step-by-Step Guide

### 1. Create Package Directory

```
webfly_packages/webfly_<name>/
├── pubspec.yaml
├── lib/
│   ├── webfly_<name>.dart          # Dart barrel export
│   ├── webfly_<name>.ts            # TypeScript barrel export
│   └── src/
│       ├── <name>_module.dart      # WebF module class
│       ├── dto.dart                # DTOs (if using json_serializable)
│       └── dto.g.dart              # Generated
└── test/
```

### 2. Dart Module (extends WebFBaseModule)

```dart
import 'package:webf/webf.dart';
import 'package:webfly_bridge/webfly_bridge.dart';

class MyWebfModule extends WebFBaseModule {
  MyWebfModule(super.manager);

  @override
  String get name => 'My';  // Must match TS createModuleInvoker('My')

  @override
  Future<void> initialize() async {
    // Setup streams, subscriptions
  }

  @override
  Future<dynamic> invoke(String method, List<dynamic> arguments) async {
    switch (method) {
      case 'doSomething':
        return _doSomething(arguments);
      default:
        return webfErr('[My] Unknown method: $method');
    }
  }

  Future<Map<String, dynamic>> _doSomething(List<dynamic> args) async {
    try {
      final result = await someFlutterApi();
      return webfOk(result.toJson());
    } catch (e) {
      return webfErr('Failed: $e');
    }
  }

  // Emit events to TS
  void _emitSomething(dynamic payload) {
    dispatchEvent(
      event: CustomEvent('eventName', detail: payload),
    );
  }

  @override
  void dispose() {
    // Cancel subscriptions
  }
}
```

### 3. TypeScript Wrapper

```typescript
import {
  createModuleInvoker,
  WebfModuleEventBus,
  type Result,
} from '../../webfly_bridge/lib/webfly_bridge';

const invoke = createModuleInvoker('My');  // Must match Dart module name

// Method wrappers
export function doSomething(param: string): Promise<Result<MyResult, string>> {
  return invoke<MyResult>('doSomething', param);
}

// Event bus (if the module emits events)
export type MyEventType = 'eventName';
export interface MyEventPayloadMap {
  eventName: MyEventPayload;
}

export class MyEventBus extends WebfModuleEventBus<MyEventType, MyEventPayloadMap> {
  protected override get moduleName(): string {
    return 'My';
  }
}

export function addMyListener<K extends MyEventType>(
  eventType: K,
  handler: (data: MyEventPayloadMap[K]) => void,
): () => void {
  const bus = new MyEventBus();
  return bus.addListener(eventType, handler);
}
```

### 4. Register in main.dart

```dart
// lib/webf/webf.dart — add export
export 'package:webfly_my/webfly_my.dart' show MyWebfModule;

// lib/main.dart — add registration
WebF.defineModule((context) => MyWebfModule(context));
```

### 5. Add Path Alias (frontend)

In `frontend/tsconfig.json`:
```json
{
  "compilerOptions": {
    "paths": {
      "@webfly/my": ["../webfly_packages/webfly_my/lib/webfly_my.ts"]
    }
  }
}
```

In `frontend/vite.config.ts`:
```typescript
resolve: {
  alias: {
    '@webfly/my': path.resolve(__dirname, '../webfly_packages/webfly_my/lib/webfly_my.ts'),
  }
}
```

### 6. Code Generation (if using DTOs)

Add `json_annotation` + `json_serializable` + `build_runner` to the package's `pubspec.yaml`, then:

```bash
just generate  # Runs build_runner in root + webfly_ble
# For new packages, add to justfile generate recipe:
# cd webfly_packages/webfly_<name> && dart run build_runner build --delete-conflicting-outputs
```

## Wire Format

All method returns use the webfly_bridge wire format:

| Dart | Wire JSON | TypeScript |
|------|-----------|------------|
| `webfOk(value)` | `{ "type": "ok", "value": T }` | `Result.ok(T)` |
| `webfErr(msg)` | `{ "type": "err", "message": string }` | `Result.err(string)` |

## Checklist

- [ ] Dart module class extends `WebFBaseModule`
- [ ] Module `name` getter matches TS `createModuleInvoker()` argument
- [ ] All methods return `webfOk()` or `webfErr()`
- [ ] Events emitted via `dispatchEvent(CustomEvent(...))`
- [ ] TS wrapper uses `neverthrow` Result type
- [ ] Module registered in `lib/main.dart` via `WebF.defineModule()`
- [ ] Path alias added in `tsconfig.json` + `vite.config.ts`
- [ ] `just generate` recipe updated if using build_runner
