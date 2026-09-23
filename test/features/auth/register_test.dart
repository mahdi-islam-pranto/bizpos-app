import 'package:bizpos_app/core/network/api_client.dart';
import 'package:bizpos_app/core/network/api_exception.dart';
import 'package:bizpos_app/core/session/auth_api.dart';
import 'package:bizpos_app/core/session/session_controller.dart';
import 'package:bizpos_app/core/session/session_state.dart';
import 'package:bizpos_app/core/session/signup_models.dart';
import 'package:bizpos_app/features/auth/register_screen.dart';
import 'package:bizpos_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_adapter.dart';

/// A shop signing itself up, `docs/MOBILE-API-NEW.md` section 2.
void main() {
  group('the calls', () {
    late FakeAdapter adapter;
    late AuthApi api;

    setUp(() {
      adapter = FakeAdapter();
      final client = ApiClient.create(
        baseUrl: 'https://example.test/api/v1',
        readToken: () => null,
        onUnauthenticated: () async {},
      );
      client.dio.httpClientAdapter = adapter;
      api = AuthApi(client);
    });

    test('register sends the form and reads a working token back', () async {
      adapter
        ..statusCode = 201
        ..body = {
          'data': {
            'token': '31|Xk2',
            'tokenType': 'Bearer',
            'expiresAt': '2026-12-22T18:25:46+00:00',
            'store': {
              'id': 42,
              'name': 'Rahman Pharmacy',
              'trialEndsAt': '2026-09-28T23:59:59+06:00',
              'trialDaysLeft': 5,
            },
            'user': {'id': 108, 'name': 'Abdul Rahman'},
            'branch': {'id': 61, 'name': 'Main Branch'},
          },
        };

      final result = await api.register(
        name: 'Rahman Pharmacy',
        storeTypeId: 1,
        ownerName: 'Abdul Rahman',
        email: 'rahman@shop.com',
        phone: '01711223344',
        password: 'secret1',
      );

      final sent = adapter.lastRequest;
      expect(sent.path, endsWith('/auth/register'));
      expect(sent.method, 'POST');
      // No token exists yet, and none may be sent.
      expect(sent.headers.containsKey('Authorization'), isFalse);
      final body = sent.data as Map<String, dynamic>;
      expect(body['storeTypeId'], 1);
      expect(body['ownerName'], 'Abdul Rahman');
      // Optional fields are left out rather than sent empty.
      expect(body.containsKey('address'), isFalse);

      expect(result.token, '31|Xk2');
      expect(result.trialDaysLeft, 5);
      expect(result.storeName, 'Rahman Pharmacy');
    });

    test('a known email is told to sign in, in both languages', () async {
      adapter
        ..statusCode = 409
        ..body = {
          'error': {
            'code': 'sign_in_to_add_store',
            'message': 'This email already has an account.',
            'messageBn': 'এই ইমেইলে অ্যাকাউন্ট আছে।',
            'on': 'email',
          },
        };

      Object? caught;
      try {
        await api.register(
          name: 'x',
          storeTypeId: 1,
          ownerName: 'x',
          email: 'owner@rahman.test',
          phone: '01711223344',
          password: 'secret1',
        );
      } catch (e) {
        caught = e;
      }

      expect(caught, isA<ConflictException>());
      final conflict = caught! as ConflictException;
      expect(conflict.code, 'sign_in_to_add_store');
      expect(conflict.on, 'email');
      expect(conflict.messageFor('bn'), 'এই ইমেইলে অ্যাকাউন্ট আছে।');
    });

    test('the store types need no token', () async {
      adapter.body = {
        'data': {
          'storeTypes': [
            {'id': 1, 'name': 'Pharmacy', 'slug': 'pharmacy'},
          ],
          'plans': [
            {'id': 1, 'name': 'Starter', 'price': '500.00', 'interval': 'monthly'},
          ],
          'trialDays': 5,
        },
      };

      final options = await api.signupOptions();
      expect(options.storeTypes.single.name, 'Pharmacy');
      expect(options.trialDays, 5);
      expect(adapter.lastRequest.headers.containsKey('Authorization'), isFalse);
    });

    test('the store list names a closed shop apart', () async {
      adapter.body = {
        'data': [
          {
            'id': 42,
            'name': 'Rahman Pharmacy',
            'storeType': 'Pharmacy',
            'isOwner': true,
            'isCurrent': true,
            'trialEndsAt': null,
            'trialDaysLeft': null,
          },
        ],
        'meta': {
          'locked': {'id': 39, 'name': 'Old Shop'},
        },
      };

      final list = await api.stores();
      expect(list.stores.single.isCurrent, isTrue);
      expect(list.lockedName, 'Old Shop');
    });
  });

  group('the screen', () {
    testWidgets('a known email offers signing in instead', (tester) async {
      final session = _RefusingSession(
        const ConflictException(
          'This email already has an account. Sign in, then add another store.',
          code: 'sign_in_to_add_store',
          on: 'email',
        ),
      );
      // Tall enough for the whole form, so taps land where they aim.
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionControllerProvider.overrideWith(() => session),
            signupOptionsProvider.overrideWith(
              (ref) async => const SignupOptions(
                storeTypes: [
                  StoreType(id: 1, name: 'Pharmacy', slug: 'pharmacy'),
                ],
                trialDays: 5,
              ),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppL10n.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppL10n.supportedLocales,
            home: RegisterScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Free for 5 days'), findsOneWidget);

      Future<void> type(String label, String value) => tester.enterText(
            find.widgetWithText(TextFormField, label),
            value,
          );
      await type('Shop name', 'Rahman Pharmacy');
      await type('Your name', 'Abdul Rahman');
      await type('Phone', '01711223344');
      await type('Email', 'owner@rahman.test');
      await type('Password', 'secret1');

      await tester.ensureVisible(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pharmacy').last);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Create shop'));
      await tester.tap(find.widgetWithText(FilledButton, 'Create shop'));
      await tester.pumpAndSettle();

      expect(session.calls, 1);
      expect(session.lastStoreTypeId, 1);
      expect(find.textContaining('already has an account'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Sign in'), findsOneWidget);
    });

    testWidgets('an incomplete form is not sent', (tester) async {
      final session = _RefusingSession(const NetworkException());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionControllerProvider.overrideWith(() => session),
            signupOptionsProvider.overrideWith(
              (ref) async => const SignupOptions(storeTypes: [], trialDays: 5),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppL10n.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppL10n.supportedLocales,
            home: RegisterScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Create shop'));
      await tester.tap(find.widgetWithText(FilledButton, 'Create shop'));
      await tester.pumpAndSettle();

      expect(session.calls, 0);
    });
  });
}

/// A session whose sign-up is refused with [error], counting the attempts.
class _RefusingSession extends SessionController {
  _RefusingSession(this.error);

  final Object error;
  int calls = 0;
  int? lastStoreTypeId;

  @override
  Future<SessionState> build() async => const SessionLoggedOut();

  @override
  Future<void> register({
    required String name,
    required int storeTypeId,
    required String ownerName,
    required String email,
    required String phone,
    required String password,
    String? address,
    String? branchName,
  }) async {
    calls++;
    lastStoreTypeId = storeTypeId;
    throw error;
  }
}
