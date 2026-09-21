/// Which store and branch this device is currently working in.
///
/// The token carries the store and branch server-side, so no request ever sends
/// a store id. The consequence is that **every cached screen is wrong the moment
/// a switch happens**, and every record id held in memory now belongs to another
/// store — where it answers 404, not 403.
///
/// So this value is the invalidation key for the whole app. Every repository
/// provider starts with `ref.watch(sessionScopeProvider)`; when the scope value
/// changes, Riverpod disposes and refetches everything that depended on it.
///
/// [epoch] exists for the case where neither store nor branch changed but the
/// data must still be considered stale — a `/me` refresh that returned a
/// different permission set, or leaving impersonation.
class SessionScope {
  const SessionScope({
    required this.storeId,
    required this.branchId,
    this.epoch = 0,
  });

  final int storeId;
  final int? branchId;
  final int epoch;

  SessionScope bumped() => SessionScope(
        storeId: storeId,
        branchId: branchId,
        epoch: epoch + 1,
      );

  /// Namespaces cache entries, so a cached product list cannot leak across
  /// stores or branches.
  String get cacheKey => 's$storeId.b${branchId ?? 0}';

  @override
  bool operator ==(Object other) =>
      other is SessionScope &&
      other.storeId == storeId &&
      other.branchId == branchId &&
      other.epoch == epoch;

  @override
  int get hashCode => Object.hash(storeId, branchId, epoch);

  @override
  String toString() => 'SessionScope($cacheKey, epoch $epoch)';
}
