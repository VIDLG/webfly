import 'dart:async' show TimeoutException;

import 'package:anyhow/anyhow.dart';
import 'package:catcher_2/catcher_2.dart';
import 'utils/app_logger.dart';

/// Application error types and error handling utilities
/// 
/// This module provides error types and conversion utilities that work with
/// anyhow's Result type for functional error handling.

/// Base class for application-specific errors
/// 
/// These errors can be wrapped in anyhow.Error for use with Result types.
abstract class AppError implements Exception {
  const AppError(
    this.message, [
    this.originalError,
    this.stackTrace,
  ]);

  final String message;
  final Object? originalError;
  final StackTrace? stackTrace;

  @override
  String toString() => message;
}

/// Network-related errors (e.g., HTTP errors, connection failures)
class NetworkError extends AppError {
  const NetworkError(
    super.message,
    super.originalError,
    super.stackTrace, {
    this.requestUrl,
  });

  final String? requestUrl;

  @override
  String toString() {
    if (requestUrl != null) {
      return '$message\nRequest URL: $requestUrl';
    }
    return message;
  }
}

/// Timeout errors
class TimeoutError extends AppError {
  const TimeoutError(
    super.message,
    super.originalError,
    super.stackTrace,
    this.timeout,
  );

  final Duration timeout;

  @override
  String toString() => '$message (timeout: ${timeout.inSeconds}s)';
}

/// WebF controller-related errors
class WebFControllerError extends AppError {
  const WebFControllerError(
    super.message,
    super.originalError,
    super.stackTrace, {
    this.controllerName,
    this.url,
  });

  final String? controllerName;
  final String? url;

  @override
  String toString() {
    final parts = <String>[message];
    if (controllerName != null) parts.add('Controller: $controllerName');
    if (url != null) parts.add('URL: $url');
    return parts.join('\n');
  }
}

/// Route resolution errors
class RouteResolutionError extends AppError {
  const RouteResolutionError(
    super.message,
    super.originalError,
    super.stackTrace, {
    this.routePath,
    this.controllerName,
  });

  final String? routePath;
  final String? controllerName;

  @override
  String toString() {
    final parts = <String>[message];
    if (routePath != null) parts.add('Route Path: $routePath');
    if (controllerName != null) parts.add('Controller: $controllerName');
    return parts.join('\n');
  }
}

/// Bluetooth-related errors
class BluetoothError extends AppError {
  const BluetoothError(
    super.message,
    super.originalError,
    super.stackTrace, {
    this.operation,
    this.deviceId,
  });

  final String? operation;
  final String? deviceId;

  @override
  String toString() {
    final parts = <String>[message];
    if (operation != null) parts.add('Operation: $operation');
    if (deviceId != null) parts.add('Device ID: $deviceId');
    return parts.join('\n');
  }
}

/// Bluetooth adapter state errors (e.g., adapter is off, unauthorized)
class BluetoothAdapterError extends BluetoothError {
  const BluetoothAdapterError(
    super.message,
    super.originalError,
    super.stackTrace, {
    super.operation,
    this.adapterState,
  });

  final String? adapterState;

  @override
  String toString() {
    final parts = <String>[message];
    if (operation != null) parts.add('Operation: $operation');
    if (adapterState != null) parts.add('Adapter State: $adapterState');
    return parts.join('\n');
  }
}

/// Bluetooth device connection errors
class BluetoothConnectionError extends BluetoothError {
  const BluetoothConnectionError(
    super.message,
    super.originalError,
    super.stackTrace, {
    super.deviceId,
    this.connectionState,
  });

  final String? connectionState;

  @override
  String toString() {
    final parts = <String>[message];
    if (deviceId != null) parts.add('Device ID: $deviceId');
    if (connectionState != null) parts.add('Connection State: $connectionState');
    return parts.join('\n');
  }
}

/// Bluetooth GATT operation errors (read/write characteristics, etc.)
class BluetoothGattError extends BluetoothError {
  const BluetoothGattError(
    super.message,
    super.originalError,
    super.stackTrace, {
    super.deviceId,
    this.serviceUuid,
    this.characteristicUuid,
  });

  final String? serviceUuid;
  final String? characteristicUuid;

  @override
  String toString() {
    final parts = <String>[message];
    if (deviceId != null) parts.add('Device ID: $deviceId');
    if (serviceUuid != null) parts.add('Service UUID: $serviceUuid');
    if (characteristicUuid != null) parts.add('Characteristic UUID: $characteristicUuid');
    return parts.join('\n');
  }
}

/// Converts a generic exception to an AppError
AppError convertToAppError(
  Object error, [
  StackTrace? stackTrace,
]) {
  if (error is AppError) {
    return error;
  }

  if (error is TimeoutException) {
    // ignore: avoid_dynamic_calls
    final dynamic timeoutError = error;
    final duration = timeoutError.duration as Duration?;
    return TimeoutError(
      'Operation timed out',
      error,
      stackTrace,
      duration ?? const Duration(seconds: 0),
    );
  }

  // Try to extract network error info (e.g., DioException)
  // ignore: avoid_dynamic_calls
  final dynamic dynamicError = error;
  try {
    // ignore: avoid_dynamic_calls
    final response = dynamicError?.response;
    // ignore: avoid_dynamic_calls
    final requestOptions = dynamicError?.requestOptions;
    
    if (response != null || requestOptions != null) {
      // ignore: avoid_dynamic_calls
      final uri = requestOptions?.uri?.toString();
      
      return NetworkError(
        'Network request failed',
        error,
        stackTrace,
        requestUrl: uri,
      );
    }
  } catch (_) {
    // Not a network error, continue
  }

  // Default: wrap as generic error message
  return _GenericAppError(
    error.toString(),
    error,
    stackTrace,
  );
}

/// Converts an exception to anyhow.Error with AppError context
Error toAnyhowError(
  Object error, [
  StackTrace? stackTrace,
]) {
  final appError = convertToAppError(error, stackTrace);
  return Error(appError);
}

/// Creates a Result error from WebFControllerError with context
/// 
/// Supports two usage patterns:
/// 1. From exception: `webfControllerError<T>(error: e, controllerName: ..., url: ...)`
/// 2. Direct creation: `webfControllerError<T>(message: '...', controllerName: ..., url: ...)`
Result<T> webfControllerError<T>({
  Object? error,
  String? message,
  required String controllerName,
  required String url,
  Object? originalError,
  StackTrace? stackTrace,
}) {
  final WebFControllerError webfError;
  
  if (error != null) {
    // Convert from exception
    final appError = convertToAppError(error, stackTrace);
    webfError = WebFControllerError(
      appError.message,
      appError.originalError ?? error,
      appError.stackTrace ?? stackTrace,
      controllerName: controllerName,
      url: url,
    );
  } else {
    // Direct creation
    webfError = WebFControllerError(
      message ?? 'WebF controller error',
      originalError,
      stackTrace,
      controllerName: controllerName,
      url: url,
    );
  }
  
  // Log error at creation point
  appLogger.e(
    '[WebFControllerError] Failed to inject WebF bundle',
    error: webfError.toString(),
    stackTrace: webfError.stackTrace,
  );
  
  return Err<T>(Error(webfError))
    .context("Failed to inject WebF bundle")
    .context("Controller: $controllerName")
    .context("URL: $url");
}

/// Creates a Result error from RouteResolutionError with context
/// 
/// Supports two usage patterns:
/// 1. From exception: `routeResolutionError<T>(error: e, routePath: ..., controllerName: ...)`
/// 2. Direct creation: `routeResolutionError<T>(message: '...', routePath: ..., controllerName: ...)`
Result<T> routeResolutionError<T>({
  Object? error,
  String? message,
  required String routePath,
  required String controllerName,
  Object? originalError,
  StackTrace? stackTrace,
}) {
  final RouteResolutionError routeError;
  
  if (error != null) {
    // Convert from exception
    final appError = convertToAppError(error, stackTrace);
    routeError = RouteResolutionError(
      appError.message,
      appError.originalError ?? error,
      appError.stackTrace ?? stackTrace,
      routePath: routePath,
      controllerName: controllerName,
    );
  } else {
    // Direct creation
    routeError = RouteResolutionError(
      message ?? 'Route resolution error',
      originalError,
      stackTrace,
      routePath: routePath,
      controllerName: controllerName,
    );
  }
  
  // Log error at creation point
  appLogger.e(
    '[RouteResolutionError] Failed to resolve route',
    error: routeError.toString(),
    stackTrace: routeError.stackTrace,
  );
  
  return Err<T>(Error(routeError))
    .context("Failed to resolve route")
    .context("Route Path: $routePath")
    .context("Controller: $controllerName");
}

/// Extracts AppError from anyhow.Error if possible
AppError? extractAppError(Error anyhowError) {
  final rootCause = anyhowError.rootCause();
  final appErrorResult = rootCause.downcast<AppError>();
  return appErrorResult.match(
    ok: (appError) => appError,
    err: (_) => null,
  );
}

/// Reports an anyhow.Error to Catcher2 for monitoring
/// 
/// This function safely extracts the root cause and reports it to Catcher2.
/// Use this when you want to report handled errors (Result.err) to monitoring systems.
void reportErrorToCatcher(Error anyhowError) {
  try {
    final rootCause = anyhowError.rootCause();
    final originalError = rootCause.downcastUnchecked();
    Catcher2.reportCheckedError(originalError, anyhowError.stacktrace());
  } catch (_) {
    // If downcast fails, report the anyhow error itself
    Catcher2.reportCheckedError(anyhowError, anyhowError.stacktrace());
  }
}


/// Generic application error wrapper
class _GenericAppError extends AppError {
  const _GenericAppError(
    super.message,
    super.originalError,
    super.stackTrace,
  );
}
