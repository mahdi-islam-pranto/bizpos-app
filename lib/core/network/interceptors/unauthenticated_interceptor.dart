import 'package:dio/dio.dart';

import '../api_exception.dart';

/// Fans every 401 into a single global sign-out.
///
/// A dashboard fires four to six calls in parallel, so a revoked token produces
/// four to six simultaneous 401s. Without the latch below, each one would wipe
/// the token and push the login route, and the user would watch the app
/// navigate several times.
///
/// The latch is **not** released when the sign-out finishes — once the token is
/// gone, later 401s from calls that were already in flight say nothing new.
/// [reset] is called on the next successful sign-in, which is the only moment a
/// 401 becomes meaningful again.
class UnauthenticatedInterceptor extends Interceptor {
  UnauthenticatedInterceptor(this._onUnauthenticated);

  final Future<void> Function() _onUnauthenticated;

  bool _signedOut = false;

  void reset() => _signedOut = false;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.error is UnauthenticatedException && !_signedOut) {
      _signedOut = true;
      _onUnauthenticated();
    }
    handler.next(err);
  }
}
