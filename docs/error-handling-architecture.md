# Error Handling Architecture

## Overview

This project uses a combination of **anyhow** (functional error handling) and **catcher** (global error catching) for comprehensive error management.

## Why Both?

### anyhow - Business Logic Error Handling
- **Purpose**: Handle errors in business logic with explicit `Result<T>` types
- **Scope**: Known errors that we can handle gracefully
- **Benefits**: 
  - Type-safe error handling
  - Automatic error context chaining
  - Functional composition of error-prone operations

### catcher - Global Error Catching
- **Purpose**: Catch unhandled exceptions and framework errors
- **Scope**: Unknown errors, Flutter framework errors, async errors
- **Benefits**:
  - Automatic error reporting (Sentry, HTTP, etc.)
  - User-friendly error dialogs
  - Production error monitoring

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Application Code                      │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
        ┌─────────────────────────────────┐
        │   Business Logic (anyhow)        │
        │   Result<T> types                │
        └─────────────────────────────────┘
                          │
        ┌─────────────────┴─────────────────┐
        │                                     │
        ▼                                     ▼
┌──────────────┐                    ┌──────────────┐
│   Success    │                    │    Error     │
│   Ok(value)  │                    │  Err(error)  │
└──────────────┘                    └──────────────┘
        │                                     │
        │                                     ▼
        │                            ┌─────────────────┐
        │                            │ ErrorConverter  │
        │                            │ (to AppError)   │
        │                            └─────────────────┘
        │                                     │
        │                                     ▼
        │                            ┌─────────────────┐
        │                            │   Logging       │
        │                            │   UI Display    │
        │                            └─────────────────┘
        │                                     │
        │                                     ▼
        │                            ┌─────────────────┐
        │                            │    Catcher      │
        │                            │ (Error Report)  │
        │                            └─────────────────┘
        │
        ▼
┌──────────────┐
│   Success    │
│   Continue   │
└──────────────┘
```

## Usage Examples

### Business Logic with anyhow

```dart
// lib/widgets/webf_view.dart
Future<Result<WebFController>> injectWebfBundleAsync({
  required String controllerName,
  required String url,
}) async {
  try {
    final controller = await WebFControllerManager.instance.addWithPrerendering(...);
    return Ok(controller);
  } catch (e, stackTrace) {
    final error = ErrorConverter.toWebFControllerError(e, controllerName, url, stackTrace);
    return Err(error);
  }
}

// Usage
final result = await injectWebfBundleAsync(name: "home", url: "...");
result.match(
  (controller) => useController(controller),
  (error) {
    appLogger.e('Failed', error: error.toString());
    Catcher.reportCheckedError(error.rootCause().downcastUnchecked(), error.stacktrace());
    showError(error.toString());
  },
);
```

### Global Error Catching with catcher

```dart
// lib/main.dart
void main() {
  CatcherOptions debugOptions = CatcherOptions(
    DialogReportMode(),
    [ConsoleHandler()],
  );

  CatcherOptions releaseOptions = CatcherOptions(
    SilentReportMode(),
    [
      SentryHandler(sentryClient),
      HttpHandler(HttpRequestType.post, Uri.parse('https://...')),
    ],
  );

  Catcher(
    rootWidget: MyApp(),
    debugConfig: debugOptions,
    releaseConfig: releaseOptions,
  );
}
```

## Error Flow

1. **Business Logic**: Use `Result<T>` for explicit error handling
2. **Error Conversion**: Convert exceptions to `anyhow.Error` with context
3. **Error Handling**: Match on Result to handle success/error cases
4. **Error Reporting**: Report errors to Catcher for global tracking
5. **Global Catch**: Catcher catches any unhandled exceptions

## Key Points

- **anyhow** handles errors we know about (explicit errors)
- **catcher** handles errors we don't know about (implicit errors)
- Both work together: anyhow for control flow, catcher for monitoring
- Errors are converted to `AppError` types for structured logging and UI display
