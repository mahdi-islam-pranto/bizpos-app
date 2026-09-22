import 'dart:async';
import 'dart:developer' as developer;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../env.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';
import '../permissions/permission_set.dart';
import 'auth_api.dart';
import 'me.dart';
import 'me_cache.dart';
import 'session_scope.dart';
import 'session_state.dart';
import 'token_holder.dart';
import 'token_store.dart';

final tokenHolderProvider = Provider<TokenHolder>((ref) => TokenHolder());

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

final apiClientProvider = Provider<ApiClient>((ref) {
  final holder = ref.watch(tokenHolderProvider);
  return ApiClient.create(
    baseUrl: Env.baseUrl,
    readToken: () => holder.token,
    // Read, not watch: this fires long after the client is built, and watching
    // the controller here would rebuild the client on every session change.
    onUnauthenticated: () =>
        ref.read(sessionControllerProvider.notifier).handleUnauthenticated(),
  );
});

final authApiProvider =
    Provider<AuthApi>((ref) => AuthApi(ref.watch(apiClientProvider)));

final sessionControllerProvider =
    AsyncNotifierProvider<SessionController, SessionState>(
  SessionController.new,
);

/// The current store and branch, or null when no store is active.
///
/// **Every repository provider should start with
/// `ref.watch(sessionScopeProvider)`.** That single line is what makes a store
/// or branch switch discard every cached screen: the scope value changes, and
/// Riverpod disposes and refetches everything that depended on it.
final sessionScopeProvider = Provider<SessionScope?>((ref) {
  final state = ref.watch(sessionControllerProvider).value;
  return state is SessionActive ? state.scope : null;
});

/// Cancels in-flight requests when the scope changes, so a slow answer for the
/// previous store cannot land in a screen that now shows another one.
final scopeCancelTokenProvider = Provider<CancelToken>((ref) {
  ref.watch(sessionScopeProvider);
  final token = CancelToken();
  ref.onDispose(() => token.cancel('store or branch changed'));
  return token;
});

/// Convenience reads, so widgets do not unpack [SessionState] themselves.
final meProvider = Provider<Me?>((ref) {
  final state = ref.watch(sessionControllerProvider).value;
  return switch (state) {
    SessionActive(:final me) => me,
    SessionNoStore(:final me) => me,
    _ => null,
  };
});

final permissionsProvider = Provider<PermissionSet>(
  (ref) => ref.watch(meProvider)?.permissions ?? const PermissionSet.empty(),
);

/// Owns the token, `/me`, and the store/branch scope.
class SessionController extends AsyncNotifier<SessionState> {
  int _epoch = 0;
  bool _refreshingAfterForbidden = false;

  AuthApi get _api => ref.read(authApiProvider);
  TokenHolder get _holder => ref.read(tokenHolderProvider);
  TokenStore get _tokens => ref.read(tokenStoreProvider);

  @override
  Future<SessionState> build() => _bootstrap();

  Future<SessionState> _bootstrap() async {
    final token = await _tokens.read();
    if (token == null) return const SessionLoggedOut();

    _holder.set(token);
    final expiresAt = await _tokens.readExpiry();

    // A token past its 90 days will only fail on the first real call, and the
    // first real call is usually a sale. Ask for a password instead.
    if (expiresAt != null && expiresAt.isBefore(DateTime.now())) {
      await _clearCredentials();
      return const SessionLoggedOut(
        reason: 'This device was signed out after 90 days.',
      );
    }

    try {
      final me = await _api.me();
      return await _stateFor(me, expiresAt: expiresAt);
    } on UnauthenticatedException catch (e) {
      await _clearCredentials();
      return SessionLoggedOut(reason: e.message);
    } on NetworkException {
      // Offline at launch. The last `/me` is a good enough menu to open with;
      // every screen fetches its own data and shows its own error.
      final cached = await MeCache.read();
      if (cached == null) rethrow;
      developer.log('offline start: using the cached session', name: 'session');
      return _stateFor(cached, expiresAt: expiresAt, cache: false);
    }
  }

  Future<SessionState> _stateFor(
    Me me, {
    DateTime? expiresAt,
    bool cache = true,
  }) async {
    if (cache) await MeCache.write(me);

    final store = me.store;
    if (store == null) return SessionNoStore(me);

    return SessionActive(
      me: me,
      scope: SessionScope(
        storeId: store.id,
        branchId: me.branch?.id,
        epoch: _epoch,
      ),
      expiresAt: expiresAt,
    );
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _api.login(
        email: email,
        password: password,
        deviceName: await _deviceName(),
      );
      _holder.set(result.token);
      await _tokens.write(result.token, expiresAt: result.expiresAt);
      // A previous session's 401 burst latched the interceptor shut; this is a
      // new token, so a 401 means something again.
      ref.read(apiClientProvider).allowSignOutAgain();

      // The login response carries only the user; the store, branch and
      // permissions come from `/me`.
      final me = await _api.me();
      state = AsyncValue.data(await _stateFor(me, expiresAt: result.expiresAt));
    } catch (e, stack) {
      // Keep no half-signed-in state: the screen shows the error and the user
      // is still on the login form.
      _holder.clear();
      await _tokens.clear();
      state = AsyncValue.error(e, stack);
    }
  }

  /// Refetches `/me` in place, keeping the current screen.
  ///
  /// [bumpEpoch] forces every scope-keyed provider to refetch even when the
  /// store and branch did not change — used when the permission set itself may
  /// have moved under us.
  Future<void> refreshMe({bool bumpEpoch = false}) async {
    final current = state.value;
    if (current is! SessionActive && current is! SessionNoStore) return;

    if (bumpEpoch) _epoch++;
    try {
      final me = await _api.me();
      final expiresAt =
          current is SessionActive ? current.expiresAt : null;
      state = AsyncValue.data(await _stateFor(me, expiresAt: expiresAt));
    } on UnauthenticatedException {
      // The interceptor is already signing us out.
    } on ApiException catch (e) {
      developer.log('could not refresh the session: ${e.message}',
          name: 'session');
    }
  }

  /// A 403 means the local permission list is out of date — an owner just
  /// revoked something. Refresh once so the app stops offering the action.
  Future<void> reconcileAfterForbidden() async {
    if (_refreshingAfterForbidden) return;
    _refreshingAfterForbidden = true;
    try {
      await refreshMe(bumpEpoch: true);
    } finally {
      _refreshingAfterForbidden = false;
    }
  }

  /// Switching store resets the branch to that store's default and changes the
  /// permission set, so the whole app is rebuilt from the new `/me`.
  Future<void> switchStore(int storeId) async {
    await _api.switchStore(storeId);
    _epoch++;
    await refreshMe();
  }

  /// Stock, sales, shifts and reports are per branch, so every screen reloads.
  Future<void> switchBranch(int branchId) async {
    await _api.switchBranch(branchId);
    _epoch++;
    await refreshMe();
  }

  /// Saves the account preferences the web workspace shares.
  ///
  /// Failure is deliberately quiet: the app has already applied the change
  /// locally, and a modal about a preference would be worse than the drift.
  Future<void> savePreferences({String? locale, String? theme}) async {
    try {
      await _api.savePreferences(locale: locale, theme: theme);
      final current = state.value;
      if (current is SessionActive) {
        await refreshMe();
      }
    } on ApiException catch (e) {
      developer.log('could not save preferences: ${e.message}',
          name: 'session');
    }
  }

  /// The user asked to sign out. Tell the server, then forget the token either
  /// way — a failed call must not trap someone in a session.
  Future<void> signOut() async {
    try {
      await _api.logout();
    } on ApiException catch (e) {
      developer.log('logout call failed: ${e.message}', name: 'session');
    }
    await _clearCredentials();
    state = const AsyncValue.data(SessionLoggedOut());
  }

  /// Called by [UnauthenticatedInterceptor] on the first 401 of a burst. The
  /// interceptor's own latch means this runs once, not once per parallel call.
  Future<void> handleUnauthenticated() async {
    if (state.value is SessionLoggedOut) return;
    await _clearCredentials();
    state = const AsyncValue.data(
      SessionLoggedOut(reason: 'Your session has ended. Please sign in again.'),
    );
  }

  Future<void> _clearCredentials() async {
    _holder.clear();
    await _tokens.clear();
    await MeCache.clear();
  }

  /// Shows in the device list, so it should say something a person recognises.
  ///
  /// Uses [defaultTargetPlatform] rather than `dart:io`, which cannot be
  /// imported in a web build at all.
  Future<String?> _deviceName() async {
    try {
      if (kIsWeb) return 'Browser';

      final info = DeviceInfoPlugin();
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final android = await info.androidInfo;
          return '${android.manufacturer} ${android.model}'.trim();
        case TargetPlatform.iOS:
          final ios = await info.iosInfo;
          return ios.name;
        case TargetPlatform.windows:
          final windows = await info.windowsInfo;
          return windows.computerName;
        case TargetPlatform.macOS:
          final mac = await info.macOsInfo;
          return mac.computerName;
        case TargetPlatform.linux:
        case TargetPlatform.fuchsia:
          return null;
      }
    } catch (e) {
      developer.log('could not read the device name: $e', name: 'session');
    }
    return null;
  }
}

/// The scope as a plain string — `s3.b7 e0`.
///
/// Anything that only needs to *notice* a store or branch change (the cart, a
/// cache key, a list's scroll position) watches this rather than the scope
/// object, so it does not have to import the session state types to say
/// "start again".
final scopeKeyProvider = Provider<String>((ref) {
  final scope = ref.watch(sessionScopeProvider);
  return scope == null ? 'none' : '${scope.cacheKey} e${scope.epoch}';
});
