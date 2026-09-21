import 'package:dio/dio.dart';

import '../api_paths.dart';

/// Attaches `Accept` to everything, and the bearer token to everything except
/// `auth/login` and `public/permissions`.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._readToken);

  /// Reads the current token, or null when signed out. Synchronous on purpose:
  /// the session controller holds the token in memory after boot, so no request
  /// pays for a keystore read.
  final String? Function() _readToken;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Accept'] = 'application/json';

    final isAnonymous = ApiPaths.anonymous.any(options.path.endsWith);
    if (!isAnonymous) {
      final token = _readToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }
}
