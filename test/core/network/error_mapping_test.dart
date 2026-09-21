import 'package:bizpos_app/core/network/api_client.dart';
import 'package:bizpos_app/core/network/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_adapter.dart';

/// One case per row of the error table in `docs/MOBILE-API.md` section 1. If the
/// backend ever changes a shape, this is where it shows up — not in a screen.
void main() {
  late FakeAdapter adapter;
  late ApiClient client;
  int unauthenticatedCalls = 0;

  setUp(() {
    unauthenticatedCalls = 0;
    adapter = FakeAdapter();
    client = ApiClient.create(
      baseUrl: 'https://example.test/api/v1',
      readToken: () => 'tok',
      onUnauthenticated: () async => unauthenticatedCalls++,
    );
    client.dio.httpClientAdapter = adapter;
  });

  Future<Object?> callAndCatch() async {
    try {
      await client.get<void>('/anything', parse: parseNothing);
      return null;
    } catch (e) {
      return e;
    }
  }

  void answerWith(int status, Object body) {
    adapter
      ..statusCode = status
      ..body = body;
  }

  test('401 unauthenticated', () async {
    answerWith(401, {
      'error': {'message': 'Unauthenticated.', 'code': 'unauthenticated'},
    });

    final error = await callAndCatch();
    expect(error, isA<UnauthenticatedException>());
    expect((error! as ApiException).message, 'Unauthenticated.');
  });

  test('401 signs out once, not once per parallel call', () async {
    answerWith(401, {
      'error': {'message': 'Unauthenticated.', 'code': 'unauthenticated'},
    });

    // A dashboard fires several calls at once; a revoked token answers all of
    // them with a 401. The user should be signed out one time.
    await Future.wait([
      callAndCatch(),
      callAndCatch(),
      callAndCatch(),
      callAndCatch(),
      callAndCatch(),
    ]);

    expect(unauthenticatedCalls, 1);
  });

  test('a later 401 signs out again once a new session has started', () async {
    answerWith(401, {
      'error': {'message': 'Unauthenticated.', 'code': 'unauthenticated'},
    });

    await callAndCatch();
    expect(unauthenticatedCalls, 1);

    // Signing in resets the latch; otherwise the first revoked token would
    // leave the app unable to notice the next one.
    client.allowSignOutAgain();
    await callAndCatch();

    expect(unauthenticatedCalls, 2);
  });

  test('403 forbidden carries the permission it wanted', () async {
    answerWith(403, {
      'error': {
        'message': 'Missing permission: report.profit.view',
        'code': 'forbidden',
        'permission': 'report.profit.view',
      },
    });

    final error = await callAndCatch();
    expect(error, isA<ForbiddenException>());
    expect((error! as ForbiddenException).permission, 'report.profit.view');
  });

  test('403 with an HTML body means the override header was lost', () async {
    // LiteSpeed refusing the verb before Laravel ever sees the request. This
    // must not look like a permission problem, or it will be misdiagnosed.
    adapter
      ..statusCode = 403
      ..contentType = 'text/html'
      ..rawBody = '<html><body><h1>403 Forbidden</h1></body></html>';

    final error = await callAndCatch();
    expect(error, isA<MethodOverrideException>());
    expect(
      error.toString(),
      contains('X-HTTP-Method-Override'),
      reason: 'the message has to name the actual cause',
    );
  });

  test('422 validation maps fields to messages', () async {
    answerWith(422, {
      'error': {
        'message': 'The lines field is required.',
        'code': 'validation',
        'fields': {
          'lines': ['The lines field is required.'],
          'email': ['Already taken.', 'Must be an email.'],
        },
      },
    });

    final error = await callAndCatch();
    expect(error, isA<ValidationException>());

    final validation = error! as ValidationException;
    expect(validation.first('lines'), 'The lines field is required.');
    expect(validation.fields['email'], hasLength(2));
    expect(validation.first('nothing'), isNull);
  });

  test('422 with a business code keeps the code and the message', () async {
    answerWith(422, {
      'error': {
        'message': 'Not enough stock for Napa 500mg (4 left)',
        'code': 'insufficient_stock',
      },
    });

    final error = await callAndCatch();
    expect(error, isA<BusinessRuleException>());

    final business = error! as BusinessRuleException;
    expect(business.code, 'insufficient_stock');
    // Shown verbatim: the server already wrote it for a person to read.
    expect(business.message, 'Not enough stock for Napa 500mg (4 left)');
  });

  test('409 already_in_catalog carries the match', () async {
    answerWith(409, {
      'error': {
        'message': 'That product is already in the catalogue.',
        'code': 'already_in_catalog',
        'match': {'id': 91, 'name': 'Napa 500mg'},
        'alreadyInStore': 42,
      },
    });

    final error = await callAndCatch();
    expect(error, isA<ConflictException>());

    final conflict = error! as ConflictException;
    expect(conflict.match?['id'], 91);
    expect(conflict.alreadyInStore, 42);
  });

  test('404 means "not in this store"', () async {
    answerWith(404, {
      'error': {'message': 'Not found.', 'code': 'not_found'},
    });

    expect(await callAndCatch(), isA<NotFoundException>());
  });

  test('400 bad_request is the no-store case', () async {
    answerWith(400, {
      'error': {'message': 'No store selected.', 'code': 'bad_request'},
    });

    expect(await callAndCatch(), isA<NoStoreException>());
  });

  test('429 is rate limiting', () async {
    answerWith(429, {
      'error': {'message': 'Too many attempts.', 'code': 'too_many_requests'},
    });

    expect(await callAndCatch(), isA<RateLimitedException>());
  });

  test('500 is a server problem', () async {
    answerWith(500, {'message': 'Server Error'});
    expect(await callAndCatch(), isA<ServerException>());
  });

  test('a body that is not the documented envelope is a server problem',
      () async {
    adapter
      ..statusCode = 200
      ..body = {'unexpected': true};

    expect(await callAndCatch(), isA<ServerException>());
  });
}
