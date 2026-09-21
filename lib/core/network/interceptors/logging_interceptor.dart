import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'method_override_interceptor.dart';

/// Debug-only request log. Never logs the Authorization header.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      final override =
          options.headers[MethodOverrideInterceptor.header] as String?;
      final verb = override == null
          ? options.method
          : '${options.method} as $override';
      developer.log('-> $verb ${options.uri}', name: 'api');
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (kDebugMode) {
      developer.log(
        '<- ${response.statusCode} ${response.requestOptions.uri.path}',
        name: 'api',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      developer.log(
        '<- ${err.response?.statusCode ?? err.type.name} '
        '${err.requestOptions.uri.path}: ${err.error}',
        name: 'api',
      );
    }
    handler.next(err);
  }
}
