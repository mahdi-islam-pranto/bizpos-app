import '../../../core/format/dates.dart';

int _int(Object? v) => switch (v) {
      final int x => x,
      final num x => x.toInt(),
      final String x => int.tryParse(x) ?? 0,
      _ => 0,
    };

int? _intOrNull(Object? v) => v == null ? null : _int(v);

num _num(Object? v) => switch (v) {
      final num x => x,
      final String x => num.tryParse(x) ?? 0,
      _ => 0,
    };

num? _numOrNull(Object? v) => v == null ? null : _num(v);

String _str(Object? v) => v?.toString() ?? '';

String? _strOrNull(Object? v) {
  final s = v?.toString();
  return (s == null || s.isEmpty) ? null : s;
}

bool _bool(Object? v) => v == true || v == 1 || v == 'true';

Map<String, dynamic> _map(Object? v) =>
    v is Map<String, dynamic> ? v : const <String, dynamic>{};

List<T> _listOf<T>(Object? raw, T Function(Map<String, dynamic>) parse) {
  if (raw is! List) return const [];
  return raw.whereType<Map<String, dynamic>>().map(parse).toList();
}

/// Which slice of the catalogue the list shows.
enum CatalogScope {
  /// Everything for this kind of shop.
  all,

  /// `mine=1` — only what this store already stocks.
  mine,

  /// `missing=1` — what this kind of shop sells and this one does not: the
  /// list to shop from.
  missing,
}

/// One line of the shared catalogue, always of this store's own store type.
class CatalogEntry {
  const CatalogEntry({
    required this.id,
    required this.name,
    required this.pending,
    this.genericName,
    this.barcode,
    this.brand,
    this.unit,
    this.category,
    this.defaultPurchasePrice,
    this.defaultSalePrice,
    this.defaultMrp,
    this.vatPercent = 0,
    this.alreadyInStore,
  });

  final int id;
  final String name;

  /// A shop put it up and the platform has not vouched for it yet. Every
  /// store of this type still sees it and may add it.
  final bool pending;

  final String? genericName;
  final String? barcode;
  final String? brand;
  final String? unit;
  final String? category;
  final num? defaultPurchasePrice;
  final num? defaultSalePrice;

  /// The printed price. The adopt form offers it so the shopkeeper only
  /// corrects it.
  final num? defaultMrp;
  final num vatPercent;

  /// This store's product id when it already stocks it.
  final int? alreadyInStore;

  bool get isInStore => alreadyInStore != null && alreadyInStore! > 0;

  factory CatalogEntry.fromJson(Map<String, dynamic> json) => CatalogEntry(
        id: _int(json['id']),
        name: _str(json['name']),
        pending: _bool(json['pending']),
        genericName: _strOrNull(json['genericName']),
        barcode: _strOrNull(json['barcode']),
        brand: _strOrNull(json['brand']),
        unit: _strOrNull(json['unit']),
        category: _strOrNull(json['category']),
        defaultPurchasePrice: _numOrNull(json['defaultPurchasePrice']),
        defaultSalePrice: _numOrNull(json['defaultSalePrice']),
        defaultMrp: _numOrNull(json['defaultMrp']),
        vatPercent: _num(json['vatPercent']),
        alreadyInStore: _intOrNull(json['alreadyInStore']),
      );

  /// A match from `/catalog/check` is a catalogue entry in another spelling,
  /// so "add this one instead" can open the same adopt form.
  factory CatalogEntry.fromMatch(CatalogMatch match) => CatalogEntry(
        id: match.id,
        name: match.name,
        pending: false,
        genericName: match.genericName,
        brand: match.brand,
        defaultPurchasePrice: match.purchase,
        defaultSalePrice: match.sale,
      );
}

/// The body of `POST /catalog/{id}/adopt`.
class AdoptDraft {
  const AdoptDraft({
    required this.purchasePrice,
    required this.salePrice,
    this.wholesalePrice,
    this.profitPercent,
    this.mrp,
    this.localName,
    this.openingStock,
    this.minimumStock,
  });

  final num purchasePrice;
  final num salePrice;
  final num? wholesalePrice;
  final num? profitPercent;
  final num? mrp;
  final String? localName;

  /// Left out, the product arrives with **one** on the shelf: adopting is the
  /// shop saying it already carries the thing. The form always sends what it
  /// shows, so the default is visible rather than implied.
  final num? openingStock;
  final num? minimumStock;

  Map<String, dynamic> toBody() => {
        'purchasePrice': purchasePrice,
        'salePrice': salePrice,
        'wholesalePrice': ?wholesalePrice,
        'profitPercent': ?profitPercent,
        'mrp': ?mrp,
        'localName': ?localName,
        'openingStock': ?openingStock,
        'minimumStock': ?minimumStock,
      };
}

/// What adopting answered: `201 created: true`, or `200 created: false` when
/// the product was already on the shelf.
class AdoptResult {
  const AdoptResult({required this.productId, required this.created});

  final int productId;
  final bool created;
}

/// One near-match from `GET /catalog/check`.
///
/// These rows come back in **snake_case** (`generic_name`, `reason_en`), unlike
/// the rest of the catalogue, so they are read literally.
class CatalogMatch {
  const CatalogMatch({
    required this.id,
    required this.name,
    required this.match,
    this.genericName,
    this.brand,
    this.purchase,
    this.sale,
    this.strength,
    this.reasonEn,
    this.reasonBn,
  });

  final int id;
  final String name;

  /// How it matches: `exists`, `variant`, `other_brand`, `similar`.
  final String match;
  final String? genericName;
  final String? brand;
  final num? purchase;
  final num? sale;
  final String? strength;
  final String? reasonEn;
  final String? reasonBn;

  String? reasonFor(String locale) =>
      locale == 'bn' && (reasonBn ?? '').isNotEmpty ? reasonBn : reasonEn;

  factory CatalogMatch.fromJson(Map<String, dynamic> json) => CatalogMatch(
        id: _int(json['id']),
        name: _str(json['name']),
        match: _str(json['match']),
        genericName: _strOrNull(json['generic_name'] ?? json['genericName']),
        brand: _strOrNull(json['brand']),
        purchase: _numOrNull(json['purchase']),
        sale: _numOrNull(json['sale']),
        strength: _strOrNull(json['strength']),
        reasonEn: _strOrNull(json['reason_en'] ?? json['reasonEn']),
        reasonBn: _strOrNull(json['reason_bn'] ?? json['reasonBn']),
      );
}

/// What the catalogue says about a name while it is being typed.
enum CheckVerdict {
  /// It is already in the catalogue: adopt that one.
  exists,

  /// The same product at another strength — a different product.
  variant,

  /// The same product from another company.
  otherBrand,

  /// Something close; worth a look before sending.
  similar,

  /// Nothing like it: suggest away.
  isNew;

  static CheckVerdict parse(String value) => switch (value) {
        'exists' => exists,
        'variant' => variant,
        'other_brand' => otherBrand,
        'similar' => similar,
        _ => isNew,
      };
}

/// `GET /catalog/check`.
class CatalogCheck {
  const CatalogCheck({
    required this.verdict,
    required this.matches,
    this.alreadyInStore,
  });

  final CheckVerdict verdict;
  final List<CatalogMatch> matches;

  /// This store's product id when the exact match is already on its shelf.
  final int? alreadyInStore;

  factory CatalogCheck.fromJson(Map<String, dynamic> json) => CatalogCheck(
        verdict: CheckVerdict.parse(_str(json['verdict'])),
        matches: _listOf(json['matches'], CatalogMatch.fromJson),
        alreadyInStore: _intOrNull(json['alreadyInStore']),
      );
}

/// The body of `POST /catalog/suggestions`.
class SuggestionDraft {
  const SuggestionDraft({
    required this.name,
    required this.purchasePrice,
    required this.salePrice,
    this.genericName,
    this.brand,
    this.barcode,
    this.unit,
    this.profitPercent,
    this.mrp,
    this.vatPercent,
    this.minimumStock,
    this.openingStock,
    this.reason,
  });

  final String name;
  final num purchasePrice;
  final num salePrice;
  final String? genericName;
  final String? brand;
  final String? barcode;

  /// A `short` from the lookups, or any word — an unknown unit becomes this
  /// store's own.
  final String? unit;
  final num? profitPercent;
  final num? mrp;
  final num? vatPercent;
  final num? minimumStock;
  final num? openingStock;
  final String? reason;

  Map<String, dynamic> toBody({bool confirmedNew = false}) => {
        'name': name,
        'purchasePrice': purchasePrice,
        'salePrice': salePrice,
        'genericName': ?genericName,
        'brand': ?brand,
        'barcode': ?barcode,
        'unit': ?unit,
        'profitPercent': ?profitPercent,
        'mrp': ?mrp,
        'vatPercent': ?vatPercent,
        'minimumStock': ?minimumStock,
        'openingStock': ?openingStock,
        'reason': ?reason,
        if (confirmedNew) 'confirmedNew': true,
      };
}

/// What sending a suggestion answered.
class SuggestResult {
  const SuggestResult({
    required this.id,
    required this.endorsed,
    this.storeProductId,
    this.name,
  });

  final int id;

  /// True when the sender could endorse it themselves: the product is on sale
  /// in this store already, and waits only for the platform's approval to
  /// reach other shops.
  final bool endorsed;
  final int? storeProductId;
  final String? name;

  factory SuggestResult.fromJson(Map<String, dynamic> json) => SuggestResult(
        id: _int(json['id']),
        endorsed: _bool(json['endorsed']),
        storeProductId: _intOrNull(json['storeProductId']),
        name: _strOrNull(json['name']),
      );
}

enum SuggestionStatus {
  pending,
  endorsed,
  approved,
  rejected;

  static SuggestionStatus parse(String value) => switch (value) {
        'endorsed' => endorsed,
        'approved' => approved,
        'rejected' => rejected,
        _ => pending,
      };
}

/// A row of the owner's review queue, `GET /catalog/suggestions`.
class Suggestion {
  const Suggestion({
    required this.id,
    required this.status,
    required this.name,
    this.genericName,
    this.brand,
    this.reason,
    this.cost,
    this.sale,
    this.mrp,
    this.profit,
    this.margin,
    this.askedBy,
    this.askedAt,
    this.endorsedBy,
    this.reviewNote,
    this.storeProductName,
  });

  final int id;
  final SuggestionStatus status;
  final String name;
  final String? genericName;
  final String? brand;
  final String? reason;

  /// From `economics`: what the shop would pay, charge, and make.
  final num? cost;
  final num? sale;
  final num? mrp;
  final num? profit;
  final num? margin;

  final String? askedBy;
  final DateTime? askedAt;
  final String? endorsedBy;
  final String? reviewNote;
  final String? storeProductName;

  bool get isPending => status == SuggestionStatus.pending;

  factory Suggestion.fromJson(Map<String, dynamic> json) {
    final payload = _map(json['payload']);
    final economics = _map(json['economics']);
    final product = json['storeProduct'];
    return Suggestion(
      id: _int(json['id']),
      status: SuggestionStatus.parse(_str(json['status'])),
      name: _str(payload['name']),
      genericName: _strOrNull(payload['genericName']),
      brand: _strOrNull(payload['brand']),
      reason: _strOrNull(payload['reason']),
      cost: _numOrNull(economics['cost'] ?? payload['purchasePrice']),
      sale: _numOrNull(economics['sale'] ?? payload['salePrice']),
      mrp: _numOrNull(economics['mrp'] ?? payload['mrp']),
      profit: _numOrNull(economics['profit']),
      margin: _numOrNull(economics['margin']),
      askedBy: _strOrNull(json['askedBy']),
      askedAt: AppDates.parse(json['askedAt']),
      endorsedBy: _strOrNull(json['endorsedBy']),
      reviewNote: _strOrNull(json['reviewNote']),
      storeProductName:
          product is Map ? _strOrNull(product['name']) : _strOrNull(product),
    );
  }
}
