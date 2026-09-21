import 'package:dio/dio.dart';

import '../api_exception.dart';
import 'method_override_interceptor.dart';

/// Turns every failure into an [ApiException], so no screen ever inspects a
/// status code. The mapping follows the error table in `docs/MOBILE-API.md`
/// section 1.
///
/// The exception travels as [DioException.error]; [ApiClient] unwraps it.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // `next`, not `reject`: rejecting ends the chain here, and the interceptor
    // that turns a 401 into a global sign-out sits after this one. Dio throws
    // once the last error interceptor has had its turn either way.
    handler.next(err.copyWith(error: _map(err)));
  }

  ApiException _map(DioException err) {
    switch (err.type) {
      case DioExceptionType.cancel:
        return const CancelledException();
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.connectionError:
        return const NetworkException();
      case DioExceptionType.badCertificate:
        return const NetworkException('The connection is not trusted.');
      case DioExceptionType.unknown:
        if (err.response == null) return const NetworkException();
      case DioExceptionType.badResponse:
        break;
    }

    final response = err.response;
    if (response == null) return const ServerException();

    final status = response.statusCode ?? 0;

    // A 403 whose body is HTML never reached bizPOS: the web server refused the
    // verb because the override header was missing. Diagnose it loudly rather
    // than letting it look like a permission problem.
    if (status == 403 && _looksLikeHtml(response)) {
      final options = response.requestOptions;
      final attempted =
          options.headers[MethodOverrideInterceptor.header] as String? ??
              options.method;
      return MethodOverrideException(attempted, options.path);
    }

    final error = _errorObject(response.data);
    final code = error?['code'] as String?;
    final message = error?['message'] as String?;

    switch (status) {
      case 401:
        return UnauthenticatedException(message ?? 'Your session has ended.');
      case 403:
        return ForbiddenException(
          message ?? 'You are not allowed to do that.',
          permission: error?['permission'] as String?,
        );
      case 404:
        return NotFoundException(message ?? 'Not available in this store.');
      case 400:
        return NoStoreException(message ?? 'You have no active store.');
      case 409:
        return ConflictException(
          message ?? 'That already exists.',
          match: error?['match'] as Map<String, dynamic>?,
          alreadyInStore: _asInt(error?['alreadyInStore']),
        );
      case 422:
        if (code == 'validation') {
          return ValidationException(
            message ?? 'Please check the form.',
            _readFields(error?['fields']),
          );
        }
        // Any other 422 is a business rule. `message` already says why.
        return BusinessRuleException(
          message ?? 'That is not allowed right now.',
          code ?? 'unprocessable',
        );
      case 429:
        return RateLimitedException(
          message ?? 'Too many tries. Wait a moment.',
          retryAfter: _retryAfter(response),
        );
    }

    if (status >= 500) return ServerException(message ?? 'The server had a problem.');
    return ServerException(message ?? 'Something went wrong.');
  }

  static bool _looksLikeHtml(Response<dynamic> response) {
    final contentType =
        response.headers.value(Headers.contentTypeHeader)?.toLowerCase();
    if (contentType != null && contentType.contains('text/html')) return true;

    final data = response.data;
    return data is String && data.trimLeft().startsWith('<');
  }

  static Map<String, dynamic>? _errorObject(Object? body) {
    if (body is Map<String, dynamic>) {
      final error = body['error'];
      if (error is Map<String, dynamic>) return error;
    }
    return null;
  }

  /// `error.fields` maps each field to a list of messages.
  static Map<String, List<String>> _readFields(Object? raw) {
    if (raw is! Map) return const {};
    final result = <String, List<String>>{};
    raw.forEach((key, value) {
      if (key is! String) return;
      if (value is List) {
        result[key] = value.map((m) => m.toString()).toList();
      } else if (value != null) {
        result[key] = [value.toString()];
      }
    });
    return result;
  }

  static Duration? _retryAfter(Response<dynamic> response) {
    final header = response.headers.value('retry-after');
    final seconds = header == null ? null : int.tryParse(header);
    return seconds == null ? null : Duration(seconds: seconds);
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
