import 'api_exception.dart';

/// Every success looks like `{"data": ..., "meta": ...}`. `meta` shows up only
/// on some lists and carries pagination plus the `may*` flags that tell the app
/// which buttons to show.
class Envelope<T> {
  const Envelope({required this.data, required this.meta});

  final T data;
  final Meta meta;
}

/// The `meta` object, with tri-state flag reads.
class Meta {
  const Meta(this._raw);

  const Meta.empty() : _raw = const {};

  final Map<String, dynamic> _raw;

  bool get isEmpty => _raw.isEmpty;

  /// A `may*` flag.
  ///
  /// **Absent is not the same as false.** Absent means this endpoint does not
  /// say anything about the action, so the permission alone decides. False means
  /// the server explicitly denied it. Treating absent as false hides working
  /// buttons, so callers evaluate `permission && (flag ?? true)`.
  bool? flag(String name) {
    final value = _raw[name];
    return value is bool ? value : null;
  }

  int? intValue(String name) {
    final value = _raw[name];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }

  num? numValue(String name) {
    final value = _raw[name];
    return value is num ? value : null;
  }

  Map<String, dynamic>? objectValue(String name) {
    final value = _raw[name];
    return value is Map<String, dynamic> ? value : null;
  }

  List<Map<String, dynamic>> listValue(String name) {
    final value = _raw[name];
    if (value is! List) return const [];
    return value.whereType<Map<String, dynamic>>().toList();
  }

  Map<String, dynamic> get raw => Map.unmodifiable(_raw);
}

/// Reads the `data` member of a response body, or throws [ServerException] if
/// the body is not the shape the API documents.
Object? readData(Object? body) {
  if (body is Map<String, dynamic> && body.containsKey('data')) {
    return body['data'];
  }
  throw const ServerException('The server sent an unexpected response.');
}

Meta readMeta(Object? body) {
  if (body is Map<String, dynamic>) {
    final meta = body['meta'];
    if (meta is Map<String, dynamic>) return Meta(meta);
  }
  return const Meta.empty();
}

/// Casts a `data` array into models, skipping anything that is not an object.
List<T> mapList<T>(Object? data, T Function(Map<String, dynamic>) parse) {
  if (data is! List) return const [];
  return data.whereType<Map<String, dynamic>>().map(parse).toList();
}

/// Casts a `data` object into a model.
Map<String, dynamic> asObject(Object? data) {
  if (data is Map<String, dynamic>) return data;
  throw const ServerException('The server sent an unexpected response.');
}
