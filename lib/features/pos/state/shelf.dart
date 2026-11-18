import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/pos_models.dart';
import '../data/pos_repository.dart';
import 'invoice_edit.dart';

/// What the till is currently asking for: some text, in one of the two lists.
///
/// A value type so a query can be compared rather than rebuilt: setting the
/// same text twice must not refetch the shelf.
class PosQuery {
  const PosQuery({this.text = '', this.packages = false});

  final String text;
  final bool packages;

  PosQuery withText(String value) => PosQuery(text: value, packages: packages);

  PosQuery withPackages(bool value) => PosQuery(text: text, packages: value);

  @override
  bool operator ==(Object other) =>
      other is PosQuery && other.text == text && other.packages == packages;

  @override
  int get hashCode => Object.hash(text, packages);

  @override
  String toString() => 'PosQuery("$text", packages: $packages)';
}

/// The question the till is asking, held outside the screen.
///
/// The shelf watches it, so a keystroke, a chip or a scan re-runs the search
/// through the provider — including the `/me` refresh at start-up that bumps
/// the session scope and throws the repository away. A search started by hand
/// in `initState` used to lose that race and leave the counter on a spinner it
/// could not retry: no products, no sale.
final posQueryProvider = NotifierProvider<PosQueryController, PosQuery>(
  PosQueryController.new,
);

class PosQueryController extends Notifier<PosQuery> {
  @override
  PosQuery build() => const PosQuery();

  void set(PosQuery next) {
    if (next != state) state = next;
  }
}

/// A window of the till's shelf.
class PosShelf {
  const PosShelf({
    required this.items,
    required this.limit,
    required this.hasMore,
  });

  final List<SellableItem> items;

  /// How many rows were asked for. The next page asks for this plus
  /// [PosRepository.shelfPage].
  final int limit;

  /// The server answered with a full window, so there may be more after
  /// [items]. A short answer means the shelf itself is that short.
  final bool hasMore;
}

/// The till's shelf, one page at a time.
///
/// `GET /pos/search` has no `page` and no `offset` — only `limit` — so "the
/// next page" can only be asked for by asking for a longer window, and the
/// server answers with every row from the start again. That is still the right
/// trade: opening the till waits for one page rather than the whole shop, and
/// only somebody who actually scrolls a long way pays for the rest. The rows
/// are replaced whole, so no duplicate can creep in.
final posShelfProvider = AsyncNotifierProvider<PosShelfController, PosShelf>(
  PosShelfController.new,
);

class PosShelfController extends AsyncNotifier<PosShelf> {
  bool _loadingMore = false;

  /// Bumped by every build. A page that started before a query change belongs
  /// to the question that was asked then, and must not land in the answers to
  /// the new one.
  int _generation = 0;

  /// Read by the footer, so it can spin while a page is in flight without the
  /// list being rebuilt around it.
  bool get isLoadingMore => _loadingMore;

  @override
  Future<PosShelf> build() async {
    ++_generation;
    _loadingMore = false;
    final repository = ref.watch(posRepositoryProvider);
    final query = _effective(
      ref.watch(posQueryProvider),
      ref.watch(invoiceEditProvider),
    );

    // Stock moves while the counter stands still. Re-read the window the till
    // is showing rather than leaving this morning's counts up all day — in
    // place, so a cashier deep in the shelf is not thrown back to page one.
    final timer = Timer(const Duration(seconds: 30), _reloadWindow);
    ref.onDispose(timer.cancel);

    return _fetch(repository, query, PosRepository.shelfPage);
  }

  /// One more page, keeping what is already on screen while it arrives.
  ///
  /// An error is left to the caller: the list on screen is still good, so the
  /// screen says what went wrong and the counter keeps selling from what it
  /// has. The next scroll tries again.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null ||
        !current.hasMore ||
        _loadingMore ||
        state.isLoading) {
      return;
    }

    _loadingMore = true;
    ref.notifyListeners();

    final generation = _generation;
    final repository = ref.read(posRepositoryProvider);
    final query = _effective(
      ref.read(posQueryProvider),
      ref.read(invoiceEditProvider),
    );
    try {
      final next = await _fetch(
        repository,
        query,
        current.limit + PosRepository.shelfPage,
      );
      // A query answered while this was in flight has already replaced the
      // list; these rows belong to the old question and would be a lie.
      if (!ref.mounted || generation != _generation) return;
      state = AsyncValue.data(next);
    } finally {
      _loadingMore = false;
      if (ref.mounted) ref.notifyListeners();
    }
  }

  /// The same window again, at the same size, without a loading state.
  Future<void> _reloadWindow() async {
    final current = state.value;
    if (current == null || state.isLoading) return;

    final generation = _generation;
    final repository = ref.read(posRepositoryProvider);
    final query = _effective(
      ref.read(posQueryProvider),
      ref.read(invoiceEditProvider),
    );
    try {
      final next = await _fetch(repository, query, current.limit);
      if (!ref.mounted || generation != _generation) return;
      state = AsyncValue.data(next);
    } catch (_) {
      // The list on screen is the last thing the server said. Replacing it
      // with an error over a background refresh would be worse than stale.
    }
  }

  /// An edit takes product lines only, so the shelf stays on products while
  /// one is open — whichever tab was showing when it started.
  static PosQuery _effective(PosQuery query, InvoiceEdit? editing) =>
      editing == null ? query : query.withPackages(false);

  Future<PosShelf> _fetch(
    PosRepository repository,
    PosQuery query,
    int limit,
  ) async {
    if (query.packages) {
      final items = await repository.sellablePackages(
        query.text.isEmpty ? null : query.text,
      );
      // Bundles come back in one go; there is no second page of them.
      return PosShelf(items: items, limit: items.length, hasMore: false);
    }
    final items = await repository.search(query.text, limit: limit);
    return PosShelf(items: items, limit: limit, hasMore: items.length >= limit);
  }
}
