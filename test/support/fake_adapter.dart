import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// A Dio adapter that answers from a script and records what was sent.
///
/// The whole interceptor chain runs, so these tests cover the real thing:
/// header attachment, the method override, and the error mapping — in order.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter({
    this.statusCode = 200,
    Object? body,
    this.contentType = 'application/json',
    this.rawBody,
  }) : body = body ?? const {'data': {}};

  int statusCode;
  Object? body;
  String contentType;

  /// Set this to answer with something that is not JSON — an HTML error page,
  /// for instance.
  String? rawBody;

  /// Every request that reached the wire, in order.
  final List<RequestOptions> sent = [];

  RequestOptions get lastRequest => sent.last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    sent.add(options);
    return ResponseBody.fromString(
      rawBody ?? jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [contentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
