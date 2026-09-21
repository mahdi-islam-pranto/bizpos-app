import 'package:dio/dio.dart';

import 'api_exception.dart';
import 'envelope.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/method_override_interceptor.dart';
import 'interceptors/unauthenticated_interceptor.dart';

/// The one way the app talks to bizPOS.
///
/// Call sites use the verb the API docs name — `patch`, `delete` — and the
/// interceptor chain deals with the fact that those travel as a `POST`. Every
/// failure arrives as an [ApiException]; a status code never escapes this file.
///
/// **Never retry a POST.** The API has no idempotency key, so a retried
/// `POST /pos/checkout` is a second sale. Retries, if ever added, are opt-in and
/// GET-only.
class ApiClient {
  ApiClient(this._dio, [this._authLatch]);

  factory ApiClient.create({
    required String baseUrl,
    required String? Function() readToken,
    required Future<void> Function() onUnauthenticated,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        contentType: Headers.jsonContentType,
        // We map every non-2xx ourselves, including the HTML 403 that never
        // reached Laravel, so Dio must hand them all over rather than throwing
        // before the error interceptor sees the body.
        validateStatus: (status) => status != null && status < 300,
        responseType: ResponseType.json,
      ),
    );

    final authLatch = UnauthenticatedInterceptor(onUnauthenticated);

    dio.interceptors.addAll([
      AuthInterceptor(readToken),
      MethodOverrideInterceptor(),
      LoggingInterceptor(),
      ErrorInterceptor(),
      authLatch,
    ]);

    return ApiClient(dio, authLatch);
  }

  final Dio _dio;
  final UnauthenticatedInterceptor? _authLatch;

  Dio get dio => _dio;

  /// Lets a 401 sign the app out again. Called after a successful sign-in: the
  /// latch that swallowed the previous burst must not swallow a real one later.
  void allowSignOutAgain() => _authLatch?.reset();

  Future<Envelope<T>> get<T>(
    String path, {
    required T Function(Object? data) parse,
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) =>
      _send(path, 'GET', parse: parse, query: query, cancelToken: cancelToken);

  Future<Envelope<T>> post<T>(
    String path, {
    required T Function(Object? data) parse,
    Object? body,
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) =>
      _send(
        path,
        'POST',
        parse: parse,
        body: body,
        query: query,
        cancelToken: cancelToken,
      );

  /// Written as a PATCH because that is what the API documents. It leaves the
  /// device as a POST carrying `X-HTTP-Method-Override: PATCH`.
  Future<Envelope<T>> patch<T>(
    String path, {
    required T Function(Object? data) parse,
    Object? body,
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) =>
      _send(
        path,
        'PATCH',
        parse: parse,
        body: body,
        query: query,
        cancelToken: cancelToken,
      );

  /// See [patch] — this travels as a POST too.
  Future<Envelope<T>> delete<T>(
    String path, {
    required T Function(Object? data) parse,
    Object? body,
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) =>
      _send(
        path,
        'DELETE',
        parse: parse,
        body: body,
        query: query,
        cancelToken: cancelToken,
      );

  Future<Envelope<T>> _send<T>(
    String path,
    String method, {
    required T Function(Object? data) parse,
    Object? body,
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.request<dynamic>(
        path,
        data: body,
        queryParameters: _clean(query),
        cancelToken: cancelToken,
        options: Options(method: method),
      );
      return Envelope(
        data: parse(readData(response.data)),
        meta: readMeta(response.data),
      );
    } on DioException catch (e) {
      final mapped = e.error;
      if (mapped is ApiException) throw mapped;
      throw const ServerException();
    }
  }

  /// Drops null and empty query values so `?q=` never goes out empty.
  static Map<String, dynamic>? _clean(Map<String, dynamic>? query) {
    if (query == null) return null;
    final cleaned = <String, dynamic>{};
    query.forEach((key, value) {
      if (value == null) return;
      if (value is String && value.isEmpty) return;
      cleaned[key] = value;
    });
    return cleaned.isEmpty ? null : cleaned;
  }
}

/// `parse` helpers, so call sites read as one line.
T Function(Object?) parseObject<T>(T Function(Map<String, dynamic>) fromJson) =>
    (data) => fromJson(asObject(data));

List<T> Function(Object?) parseListOf<T>(
  T Function(Map<String, dynamic>) fromJson,
) =>
    (data) => mapList(data, fromJson);

/// For endpoints whose `data` is only `{"ok": true}` or similar.
void parseNothing(Object? _) {}
