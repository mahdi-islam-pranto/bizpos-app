import 'dart:convert';
import 'dart:typed_data';

import 'package:bizpos_app/core/network/api_client.dart';
import 'package:bizpos_app/core/session/session_controller.dart';
import 'package:bizpos_app/core/session/session_state.dart';
import 'package:bizpos_app/core/session/token_store.dart';
import 'package:bizpos_app/core/theme/app_theme.dart';
import 'package:bizpos_app/core/theme/theme_variant.dart';
import 'package:bizpos_app/features/auth/login_screen.dart';
import 'package:bizpos_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The login form against the real session controller.
void main() {
  /// Signing in reads the device name off a platform channel before the
  /// request goes; that needs real time, which `pumpAndSettle` does not pass.
  Future<void> signIn(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();
  }

  setUp(() => SharedPreferences.setMockInitialValues(const {}));

  testWidgets('a wrong password does not lock the form against the right one', (
    tester,
  ) async {
    final backend = _LoginBackend();
    final container = ProviderContainer(
      overrides: [
        tokenStoreProvider.overrideWithValue(_MemoryTokenStore()),
        apiClientProvider.overrideWith((ref) {
          final client = ApiClient.create(
            baseUrl: 'http://bizpos.test/api/v1',
            readToken: () => null,
            onUnauthenticated: () async {},
          );
          client.dio.httpClientAdapter = backend;
          return client;
        }),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.of(ThemeVariant.daylight),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: const [
            AppL10n.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'owner@rahman.test');
    await tester.enterText(fields.at(1), 'wrong');
    await signIn(tester);

    expect(backend.logins, 1);
    // Shown at once, under the field it is about.
    expect(find.text('These credentials do not match.'), findsOneWidget);

    // The right password goes to the server — the old answer does not stop it.
    await tester.enterText(fields.at(1), 'bizpos123');
    await tester.pump();
    // Typing sets the old answer aside.
    expect(find.text('These credentials do not match.'), findsNothing);
    await signIn(tester);

    expect(backend.logins, 2);
    expect(
      container.read(sessionControllerProvider).value,
      isA<SessionActive>(),
    );
  });

  testWidgets('pressing Sign in again without editing still asks the server', (
    tester,
  ) async {
    final backend = _LoginBackend()..acceptAfter = 3;
    final container = ProviderContainer(
      overrides: [
        tokenStoreProvider.overrideWithValue(_MemoryTokenStore()),
        apiClientProvider.overrideWith((ref) {
          final client = ApiClient.create(
            baseUrl: 'http://bizpos.test/api/v1',
            readToken: () => null,
            onUnauthenticated: () async {},
          );
          client.dio.httpClientAdapter = backend;
          return client;
        }),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.of(ThemeVariant.daylight),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: const [
            AppL10n.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'owner@rahman.test');
    await tester.enterText(fields.at(1), 'bizpos123');
    for (var i = 0; i < 3; i++) {
      await signIn(tester);
    }

    expect(backend.logins, 3);
    expect(
      container.read(sessionControllerProvider).value,
      isA<SessionActive>(),
    );
  });
}

class _MemoryTokenStore extends TokenStore {
  String? _token;
  DateTime? _expires;

  @override
  Future<String?> read() async => _token;

  @override
  Future<DateTime?> readExpiry() async => _expires;

  @override
  Future<void> write(String token, {DateTime? expiresAt}) async {
    _token = token;
    _expires = expiresAt;
  }

  @override
  Future<void> clear() async {
    _token = null;
    _expires = null;
  }
}

/// Refuses the password until [acceptAfter] attempts, like a 422 from
/// Laravel's own validation.
class _LoginBackend implements HttpClientAdapter {
  int logins = 0;
  int acceptAfter = 2;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final key = '${options.method} ${options.uri.path}';
    var status = 200;
    Object body = {'data': <String, dynamic>{}};

    if (key == 'POST /api/v1/auth/login') {
      logins++;
      final password = (options.data as Map)['password'];
      if (logins < acceptAfter || password == 'wrong') {
        status = 422;
        body = {
          'error': {
            'message': 'These credentials do not match.',
            'code': 'validation',
            'fields': {
              'email': ['These credentials do not match.'],
            },
          },
        };
      } else {
        body = {
          'data': {
            'token': '1|abc',
            'expiresAt': '2027-01-01T00:00:00+06:00',
            'user': {'id': 2, 'name': 'Owner'},
          },
        };
      }
    } else if (key == 'GET /api/v1/me') {
      body = {
        'data': {
          'user': {'id': 2, 'name': 'Owner', 'email': 'owner@rahman.test'},
          'store': {'id': 1, 'name': 'Rahman Pharmacy', 'currency': 'BDT'},
          'branch': {'id': 1, 'name': 'Main', 'code': 'MAIN'},
          'stores': [
            {'id': 1, 'name': 'Rahman Pharmacy'},
          ],
          'branches': [],
          'role': {'id': 2, 'name': 'store_owner', 'label': 'Store Owner'},
          'permissions': ['pos.sale.create'],
          'impersonating': false,
        },
      };
    }

    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
