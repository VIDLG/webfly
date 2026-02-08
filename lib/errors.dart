import 'package:anyhow/anyhow.dart';
import 'utils/app_logger.dart';

/// Lightweight error classification.
///
/// This is intended to stay small and stable. We attach it to `anyhow` errors
/// as context (alongside a Map of structured fields) rather than introducing a
/// large hierarchy of custom error classes.
enum ErrorKind { webfController, routeResolution }

/// Creates a Result error for WebF controller initialization failures.
///
/// Supports two usage patterns:
/// 1. From exception: `webfControllerError<T>(cause: e, controllerName: ..., url: ...)`
/// 2. Direct creation: `webfControllerError<T>(message: '...', controllerName: ..., url: ...)`
Result<T> webfControllerError<T>({
  String? message,
  required String controllerName,
  required String url,
  Object? cause,
  StackTrace? stackTrace,
}) {
  final Object rootCause = cause ?? message ?? 'WebF controller error';

  // Log error at creation point
  appLogger.e(
    '[WebFControllerError] Failed to initialize WebF controller',
    error: rootCause,
    stackTrace: stackTrace,
  );

  final contextMap = <String, Object?>{
    'controllerName': controllerName,
    'url': url,
    ...? (message != null ? {'message': message} : null),
  };

  return Err<T>(Error(rootCause))
      .context('Failed to initialize WebF controller')
      .context(ErrorKind.webfController)
      .context(contextMap);
}

/// Creates a Result error for hybrid route resolution failures.
///
/// Supports two usage patterns:
/// 1. From exception: `routeResolutionError<T>(cause: e, routePath: ..., controllerName: ...)`
/// 2. Direct creation: `routeResolutionError<T>(message: '...', routePath: ..., controllerName: ...)`
Result<T> routeResolutionError<T>({
  String? message,
  required String routePath,
  required String controllerName,
  Object? cause,
  StackTrace? stackTrace,
}) {
  final Object rootCause = cause ?? message ?? 'Route resolution error';

  // Log error at creation point
  appLogger.e(
    '[RouteResolutionError] Failed to resolve route',
    error: rootCause,
    stackTrace: stackTrace,
  );

  final contextMap = <String, Object?>{
    'routePath': routePath,
    'controllerName': controllerName,
    ...? (message != null ? {'message': message} : null),
  };

  return Err<T>(Error(rootCause))
      .context('Failed to resolve route')
      .context(ErrorKind.routeResolution)
      .context(contextMap);
}
