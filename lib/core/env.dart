/// Build-time configuration.
///
/// Override the API host without touching code:
/// `flutter run --dart-define=BIZPOS_BASE_URL=https://shop.example.com/api/v1`
class Env {
  const Env._();

  static const String baseUrl = String.fromEnvironment(
    'BIZPOS_BASE_URL',
    defaultValue: 'https://biz.softwhile.com/api/v1',
  );

  /// `10.0.2.2` is how the Android emulator reaches the host machine's
  /// `127.0.0.1`. On a physical phone pass the LAN address instead.
  static bool get isLocal =>
      baseUrl.contains('127.0.0.1') ||
      baseUrl.contains('10.0.2.2') ||
      baseUrl.contains('localhost');
}
