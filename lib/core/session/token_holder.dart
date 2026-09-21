/// Holds the current token in memory so [AuthInterceptor] can read it without
/// awaiting the keystore on every request.
///
/// It exists to break a circle: the API client needs the token, and the thing
/// that owns the token needs the API client. The session controller writes here;
/// the interceptor only reads.
class TokenHolder {
  String? _token;

  String? get token => _token;

  void set(String? token) => _token = token;

  void clear() => _token = null;

  bool get hasToken => _token != null && _token!.isNotEmpty;
}
