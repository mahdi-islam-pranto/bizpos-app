/// Every failure the app can see, as a type. No screen inspects a status code.
sealed class ApiException implements Exception {
  const ApiException(this.message);

  /// Safe to show to a person: either the server's own `error.message` or a
  /// generic fallback. Business rules come back already human-readable.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// 401 — token missing, wrong, expired, revoked, or the user was deactivated.
final class UnauthenticatedException extends ApiException {
  const UnauthenticatedException([super.message = 'Your session has ended.']);
}

/// 403 — the user lacks a permission. [permission] names it when the server said.
final class ForbiddenException extends ApiException {
  const ForbiddenException(super.message, {this.permission});

  final String? permission;
}

/// 403 `trial_ended` or `store_suspended` at sign-in: the password was right
/// and there is nowhere to go. Every store this person can reach has been
/// switched off — a trial nobody extended, or a suspension. Nothing in it is
/// deleted; it waits for the platform to turn it back on.
///
/// Not a [ForbiddenException]: nothing the app does will change it, so there is
/// no permission to hide and no retry to offer — only the message to show.
final class StoreLockedException extends ApiException {
  const StoreLockedException(
    super.message, {
    required this.code,
    this.messageBn,
    this.storeName,
  });

  /// `trial_ended` or `store_suspended`. The same to the app, different to the
  /// shopkeeper, which is why the server tells them apart.
  final String code;

  /// The server writes this one in Bangla as well.
  final String? messageBn;
  final String? storeName;

  bool get isTrialEnded => code == 'trial_ended';

  /// [message] in the reader's language, when the server supplied it.
  String messageFor(String locale) =>
      locale == 'bn' && (messageBn ?? '').isNotEmpty ? messageBn! : message;
}

/// A 403 whose body is HTML came from the web server, not from bizPOS: the
/// `X-HTTP-Method-Override` header was lost, so LiteSpeed refused the real verb
/// before Laravel saw it. This is a bug in the app, not a condition to handle.
final class MethodOverrideException extends ApiException {
  const MethodOverrideException(this.attemptedMethod, this.path)
      : super('This request could not reach the server.');

  final String attemptedMethod;
  final String path;

  @override
  String toString() =>
      'MethodOverrideException: $attemptedMethod $path was refused by the web '
      'server with an HTML 403. The X-HTTP-Method-Override header is missing — '
      'send this verb as a POST. See docs/MOBILE-API-NEW.md section 1.';
}

/// 422 `validation` — [fields] maps a field name to its messages.
final class ValidationException extends ApiException {
  const ValidationException(super.message, this.fields);

  final Map<String, List<String>> fields;

  /// The first message for [field], for binding under a text input.
  String? first(String field) {
    final messages = fields[field];
    return (messages == null || messages.isEmpty) ? null : messages.first;
  }
}

/// 422 with a business code: `insufficient_stock`, `sale`, `shift_open`,
/// `no_shift`, `over_payment`, `plan_limit`, `negative`, `self`, ...
/// [message] already says why, so show it verbatim.
final class BusinessRuleException extends ApiException {
  const BusinessRuleException(super.message, this.code);

  final String code;
}

/// 409 — something that already exists.
///
/// [code] tells the cases apart: `already_in_catalog` (a product suggestion
/// duplicates the catalogue), `sign_in_to_add_store` and `already_registered`
/// (a sign-up with an email or phone the platform knows), `duplicate_store`
/// (the same shop name twice under one account).
final class ConflictException extends ApiException {
  const ConflictException(
    super.message, {
    this.code,
    this.messageBn,
    this.on,
    this.match,
    this.alreadyInStore,
  });

  final String? code;

  /// The server writes the sign-up conflicts in Bangla too.
  final String? messageBn;

  /// Which field the conflict is about (`email`, `phone`), when it said.
  final String? on;

  /// The catalogue entry that matched.
  final Map<String, dynamic>? match;

  /// This store's product id, when the match is already on sale here.
  final int? alreadyInStore;

  String messageFor(String locale) =>
      locale == 'bn' && (messageBn ?? '').isNotEmpty ? messageBn! : message;
}

/// 404 — no such record *in the current store*, or no such route. Worth its own
/// wording: after a store switch, ids from the previous store answer 404.
final class NotFoundException extends ApiException {
  const NotFoundException([super.message = 'Not available in this store.']);
}

/// 400 `bad_request` — the user belongs to no active store. This is a screen,
/// not a toast: a suspended member hits it on every call.
final class NoStoreException extends ApiException {
  const NoStoreException([super.message = 'You have no active store.']);
}

/// 429 — login was tried more than 10 times a minute.
final class RateLimitedException extends ApiException {
  const RateLimitedException(super.message, {this.retryAfter});

  final Duration? retryAfter;
}

/// 5xx, or a response that was not the JSON envelope we expect.
final class ServerException extends ApiException {
  const ServerException([super.message = 'The server had a problem.']);
}

/// No usable connection, a DNS failure, or a timeout.
final class NetworkException extends ApiException {
  const NetworkException([
    super.message = 'No connection. Check the network and try again.',
  ]);
}

/// A request that was deliberately cancelled — usually because the store or
/// branch changed while it was in flight. Never shown to anyone.
final class CancelledException extends ApiException {
  const CancelledException() : super('Cancelled.');
}
