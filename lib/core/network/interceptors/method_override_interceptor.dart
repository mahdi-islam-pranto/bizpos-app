import 'package:dio/dio.dart';

/// Sends `PUT`, `PATCH` and `DELETE` as a `POST` carrying the real verb in
/// `X-HTTP-Method-Override`.
///
/// The live host runs LiteSpeed, which refuses those verbs with its own HTML 403
/// page before the request reaches Laravel. Laravel reads the override header
/// before routing, so this behaves identically everywhere. It also *works
/// locally without the override*, which is exactly why it belongs here and not
/// at each call site: forgetting it is a deployment-day bug, not one you would
/// hit while developing.
///
/// Repositories keep calling `client.patch(...)` with the verb the API docs
/// name, and nothing below this line ever sees the substitution.
class MethodOverrideInterceptor extends Interceptor {
  static const String header = 'X-HTTP-Method-Override';
  static const Set<String> overridable = {'PUT', 'PATCH', 'DELETE'};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final method = options.method.toUpperCase();
    if (overridable.contains(method)) {
      options.headers[header] = method;
      options.method = 'POST';
    }
    handler.next(options);
  }
}
