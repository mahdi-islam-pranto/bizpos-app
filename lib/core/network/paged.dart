import 'envelope.dart';

/// A paginated list.
///
/// **Only `GET /sales`, `GET /products`, `GET /catalog` and `GET /admin/catalog`
/// paginate.** Every other list returns a fixed recent window (the latest 50
/// purchases, 100 customers, ...) and accepts `?q=` to search instead. Wiring an
/// infinite scroll to one of those would silently re-request the same window
/// forever, so the two cases are deliberately different types: [Paged] for the
/// paginated endpoints, and a plain list with a "search to narrow" footer
/// everywhere else.
class Paged<T> {
  const Paged({
    required this.items,
    required this.total,
    required this.page,
    required this.perPage,
    this.meta = const Meta.empty(),
  });

  final List<T> items;
  final int total;
  final int page;
  final int perPage;
  final Meta meta;

  static const int defaultPerPage = 25;

  bool get hasMore => page * perPage < total;
  int get nextPage => page + 1;

  factory Paged.from(Envelope<List<T>> envelope, {int fallbackPage = 1}) {
    final meta = envelope.meta;
    return Paged(
      items: envelope.data,
      total: meta.intValue('total') ?? envelope.data.length,
      page: meta.intValue('page') ?? fallbackPage,
      perPage: meta.intValue('perPage') ?? defaultPerPage,
      meta: meta,
    );
  }
}
