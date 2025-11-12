import 'package:grpc/grpc.dart';

/// Exception thrown by ProxyCore operations.
///
/// Handles both gRPC-specific errors and general exceptions,
/// providing consistent error messaging and stack trace support.
class ProxyCoreException implements Exception {
  /// The original error that caused this exception
  final Object error;

  /// Optional stack trace from where the error occurred
  final StackTrace? stackTrace;

  /// Creates a new ProxyCoreException
  ///
  /// [error] is the original error (required)
  /// [context] is an optional message providing more details about the error context
  /// [stackTrace] is an optional stack trace from where the error occurred
  const ProxyCoreException(
    this.error, {
    this.stackTrace,
  });

  /// Creates a ProxyCoreException with a simple message
  ///
  /// Useful when you only need to throw with a string message
  factory ProxyCoreException.message(String message) {
    return ProxyCoreException(message);
  }

  /// The formatted error message
  String get message {
    final errorMessage = _extractErrorMessage();
    return errorMessage;
  }

  /// Extracts the appropriate error message based on error type
  String _extractErrorMessage() {
    if (error is GrpcError) {
      final grpcError = error as GrpcError;
      return _formatGrpcError(grpcError);
    }

    if (error is String) {
      return error as String;
    }

    return error.toString();
  }

  /// Formats a gRPC error with its code and message
  String _formatGrpcError(GrpcError error) {
    final code = error.code.toString().replaceAll('StatusCode.', '');
    return 'Code ($code): ${error.message}';
  }

  /// The error code if it's a gRPC error, null otherwise
  int? get grpcErrorCode {
    if (error is GrpcError) {
      return (error as GrpcError).code;
    }
    return null;
  }

  /// Whether this is a gRPC error
  bool get isGrpcError => error is GrpcError;

  @override
  String toString() {
    final baseMessage = message;
    if (stackTrace != null) {
      return '$baseMessage\n$stackTrace';
    }
    return baseMessage;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProxyCoreException &&
        other.error.toString() == error.toString();
  }

  @override
  int get hashCode => Object.hash(error, stackTrace);
}
