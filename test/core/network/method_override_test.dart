import 'package:bizpos_app/core/network/api_client.dart';
import 'package:bizpos_app/core/network/interceptors/method_override_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_adapter.dart';

/// The single most consequential rule in the API: `PUT`, `PATCH` and `DELETE`
/// must leave the device as a `POST` carrying the real verb in a header, or the
/// production web server refuses them with an HTML 403 before Laravel sees the
/// request. It works locally either way, so only a test keeps it honest.
void main() {
  late FakeAdapter adapter;
  late ApiClient client;

  setUp(() {
    adapter = FakeAdapter();
    client = ApiClient.create(
      baseUrl: 'https://example.test/api/v1',
      readToken: () => 'tok',
      onUnauthenticated: () async {},
    );
    client.dio.httpClientAdapter = adapter;
  });

  group('verbs that must be overridden', () {
    for (final verb in MethodOverrideInterceptor.overridable) {
      test('$verb goes out as POST carrying $verb in the header', () async {
        switch (verb) {
          case 'PATCH':
            await client.patch<void>('/products/42/prices', parse: parseNothing);
          case 'DELETE':
            await client.delete<void>('/expenses/7', parse: parseNothing);
          case 'PUT':
            await client.dio.put<void>('/anything');
        }

        final request = adapter.lastRequest;
        expect(request.method, 'POST');
        expect(request.headers[MethodOverrideInterceptor.header], verb);
      });
    }
  });

  group('verbs that must not be touched', () {
    test('GET stays a GET with no override header', () async {
      await client.get<void>('/me', parse: parseNothing);

      expect(adapter.lastRequest.method, 'GET');
      expect(
        adapter.lastRequest.headers
            .containsKey(MethodOverrideInterceptor.header),
        isFalse,
      );
    });

    test('POST stays a POST with no override header', () async {
      await client.post<void>('/pos/checkout', parse: parseNothing);

      expect(adapter.lastRequest.method, 'POST');
      expect(
        adapter.lastRequest.headers
            .containsKey(MethodOverrideInterceptor.header),
        isFalse,
      );
    });
  });

  group('the bearer token', () {
    test('is attached to an ordinary call', () async {
      await client.get<void>('/me', parse: parseNothing);
      expect(adapter.lastRequest.headers['Authorization'], 'Bearer tok');
    });

    test('is left off /auth/login', () async {
      await client.post<void>('/auth/login', parse: parseNothing);
      expect(adapter.lastRequest.headers.containsKey('Authorization'), isFalse);
    });

    test('is left off /public/permissions', () async {
      await client.get<void>('/public/permissions', parse: parseNothing);
      expect(adapter.lastRequest.headers.containsKey('Authorization'), isFalse);
    });

    test('Accept is always json', () async {
      await client.get<void>('/me', parse: parseNothing);
      expect(adapter.lastRequest.headers['Accept'], 'application/json');
    });
  });
}
