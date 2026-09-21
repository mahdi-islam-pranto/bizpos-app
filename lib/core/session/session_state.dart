import 'me.dart';
import 'session_scope.dart';

/// The four states the app can boot into. The router's redirect reads nothing
/// else.
sealed class SessionState {
  const SessionState();
}

/// Still reading the stored token. The splash screen.
final class SessionUnknown extends SessionState {
  const SessionUnknown();
}

/// No token, or the token was refused. The login screen.
final class SessionLoggedOut extends SessionState {
  const SessionLoggedOut({this.reason});

  /// Why, when the sign-out was not the user's own doing — an expired token, or
  /// a keystore that could not be read.
  final String? reason;
}

/// Signed in, but `store` came back null: the person belongs to no active
/// store, or was suspended. A dedicated screen, because every other call would
/// answer `400 bad_request`.
final class SessionNoStore extends SessionState {
  const SessionNoStore(this.me);

  final Me me;
}

/// Signed in and working in a store.
final class SessionActive extends SessionState {
  const SessionActive({
    required this.me,
    required this.scope,
    this.expiresAt,
  });

  final Me me;
  final SessionScope scope;

  /// Tokens last 90 days. Worth warning about before a sale fails.
  final DateTime? expiresAt;

  bool get expiresSoon {
    final at = expiresAt;
    if (at == null) return false;
    return at.difference(DateTime.now()).inDays <= 7;
  }

  SessionActive copyWith({Me? me, SessionScope? scope}) => SessionActive(
        me: me ?? this.me,
        scope: scope ?? this.scope,
        expiresAt: expiresAt,
      );
}
