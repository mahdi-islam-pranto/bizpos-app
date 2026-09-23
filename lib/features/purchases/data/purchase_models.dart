import 'package:decimal/decimal.dart';

import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/network/envelope.dart';

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

List<T> _listOf<T>(Object? raw, T Function(Map<String, dynamic>) parse) {
  if (raw is! List) return const [];
  return raw.whereType<Map<String, dynamic>>().map(parse).toList();
}

/// A photo of the paper bill — usually a WhatsApp forward of what the supplier
/// handed over.
class PurchasePhoto {
  const PurchasePhoto({required this.id, required this.url, this.name});

  final int id;
  final String url;
  final String? name;

  factory PurchasePhoto.fromJson(Map<String, dynamic> json) => PurchasePhoto(
        id: _int(json['id']),
        url: _str(json['url']),
        name: _strOrNull(json['name']),
      );
}

/// A party the shop buys from.
class Supplier {
  const Supplier({
    required this.id,
    required this.name,
    this.company,
    this.phone,
    this.address,
  });

  final int id;
  final String name;
  final String? company;
  final String? phone;
  final String? address;

  factory Supplier.fromJson(Map<String, dynamic> json) => Supplier(
        id: _int(json['id']),
        name: _str(json['name']),
        company: _strOrNull(json['company']),
        phone: _strOrNull(json['phone']),
        address: _strOrNull(json['address']),
      );
}

/// A row of `GET /purchases` — the latest 50 bills.
class PurchaseRow {
  const PurchaseRow({
    required this.id,
    required this.refNo,
    required this.total,
    required this.paid,
    required this.due,
    required this.paymentStatus,
    required this.itemCount,
    required this.photos,
    this.purchaseDate,
    this.subtotal,
    this.discount,
    this.discountPercent,
    this.status,
    this.supplier,
    this.branch,
    this.note,
  });

  final int id;
  final String refNo;
  final num total;
  final num paid;

  /// Still owed to the supplier.
  final num due;
  final String paymentStatus;
  final int itemCount;
  final List<PurchasePhoto> photos;
  final DateTime? purchaseDate;
  final num? subtotal;
  final num? discount;

  /// The rate given on the bill, or null — which is not the same fact as
  /// zero percent; [discount] is the taka either way.
  final num? discountPercent;
  final String? status;
  final String? supplier;
  final String? branch;
  final String? note;

  factory PurchaseRow.fromJson(Map<String, dynamic> json) => PurchaseRow(
        id: _int(json['id']),
        refNo: _str(json['refNo']),
        total: _num(json['total']),
        paid: _num(json['paid']),
        due: _num(json['due']),
        paymentStatus: _str(json['paymentStatus']),
        itemCount: _int(json['itemCount']),
        photos: _listOf(json['photos'], PurchasePhoto.fromJson),
        purchaseDate: AppDates.parse(json['purchaseDate']),
        subtotal: _numOrNull(json['subtotal']),
        discount: _numOrNull(json['discount']),
        discountPercent: _numOrNull(json['discountPercent']),
        status: _strOrNull(json['status']),
        supplier: _strOrNull(json['supplier']),
        branch: _strOrNull(json['branch']),
        note: _strOrNull(json['note']),
      );
}

/// `GET /purchases` with everything its `meta` carries.
class PurchasePage {
  const PurchasePage({
    required this.rows,
    required this.suppliers,
    required this.meta,
  });

  final List<PurchaseRow> rows;

  /// The whole party list, for pickers that do not want to search.
  final List<Supplier> suppliers;
  final Meta meta;

  int get count => _int(meta.objectValue('summary')?['count']);
  num get total => _num(meta.objectValue('summary')?['total']);
  num get due => _num(meta.objectValue('summary')?['due']);

  /// Five photos a bill, today.
  int get maxPhotos => meta.intValue('maxPhotos') ?? 5;

  bool? get mayCreate => meta.flag('mayCreate');
  bool? get mayManageSuppliers => meta.flag('mayManageSuppliers');
  bool? get mayEditBill => meta.flag('mayEditBill');
}

/// A product goods can come in against, from `GET /purchases/products`.
class PurchaseProduct {
  const PurchaseProduct({
    required this.id,
    required this.name,
    required this.trackBatch,
    this.purchasePrice,
    this.unit,
  });

  final int id;
  final String name;

  /// Batch-tracked products ask for a batch number and an expiry date.
  final bool trackBatch;

  /// The last cost, which is the sensible starting figure for this bill's.
  final num? purchasePrice;
  final String? unit;

  factory PurchaseProduct.fromJson(Map<String, dynamic> json) =>
      PurchaseProduct(
        id: _int(json['id']),
        name: _str(json['name']),
        trackBatch: _bool(json['trackBatch']),
        purchasePrice: _numOrNull(json['purchasePrice']),
        unit: _strOrNull(json['unit']),
      );
}

/// One line of the goods-in form.
class PurchaseLine {
  const PurchaseLine({
    required this.product,
    required this.qty,
    required this.unitCost,
    this.batchNo,
    this.expiryDate,
  });

  final PurchaseProduct product;
  final num qty;
  final num unitCost;
  final String? batchNo;
  final DateTime? expiryDate;

  Decimal get lineTotal => Exact.of(qty) * Exact.of(unitCost);

  PurchaseLine copyWith({
    num? qty,
    num? unitCost,
    String? batchNo,
    DateTime? expiryDate,
  }) =>
      PurchaseLine(
        product: product,
        qty: qty ?? this.qty,
        unitCost: unitCost ?? this.unitCost,
        batchNo: batchNo ?? this.batchNo,
        expiryDate: expiryDate ?? this.expiryDate,
      );

  Map<String, dynamic> toBody() => {
        'storeProductId': product.id,
        'qty': qty,
        'unitCost': unitCost,
        if ((batchNo ?? '').isNotEmpty) 'batchNo': batchNo,
        if (expiryDate != null) 'expiryDate': AppDates.bucket(expiryDate!),
      };
}

/// The body of `POST /purchases`.
///
/// The party is either an existing [supplierId] or, for a party the shop has
/// not saved yet, a [supplierName] — saved with the bill, and joined to an
/// existing party when the name matches apart from case and spacing. The
/// second needs `purchase.supplier.manage`.
class PurchaseDraft {
  const PurchaseDraft({
    required this.lines,
    this.supplierId,
    this.supplierName,
    this.discountPercent,
    this.paidAmount,
    this.accountId,
    this.note,
  });

  final List<PurchaseLine> lines;
  final int? supplierId;
  final String? supplierName;

  /// A rate on the whole bill (0–100). The server works out the taka.
  final num? discountPercent;
  final num? paidAmount;

  /// Where [paidAmount] leaves from.
  final int? accountId;
  final String? note;

  bool get hasParty => supplierId != null || (supplierName ?? '').isNotEmpty;

  Decimal get subtotal => Exact.sum(lines.map((l) => l.lineTotal));

  /// A preview; the server's `total` is the bill.
  Decimal get discountAmount {
    final rate = discountPercent ?? 0;
    if (rate <= 0) return Decimal.zero;
    return Exact.paisa((subtotal * Exact.of(rate)).shift(-2));
  }

  Decimal get total => subtotal - discountAmount;

  Map<String, dynamic> toBody() => {
        if (supplierId != null)
          'supplierId': supplierId
        else if ((supplierName ?? '').isNotEmpty)
          'supplierName': supplierName,
        'items': [for (final line in lines) line.toBody()],
        if ((discountPercent ?? 0) > 0) 'discountPercent': discountPercent,
        'paidAmount': paidAmount ?? 0,
        'accountId': ?accountId,
        if ((note ?? '').isNotEmpty) 'note': note,
      };
}

/// What `POST /purchases` answers.
class PurchaseCreated {
  const PurchaseCreated({
    required this.id,
    required this.refNo,
    required this.total,
    required this.due,
    this.supplierId,
  });

  final int id;
  final String refNo;
  final num total;
  final num due;
  final int? supplierId;

  factory PurchaseCreated.fromJson(Map<String, dynamic> json) =>
      PurchaseCreated(
        id: _int(json['id']),
        refNo: _str(json['refNo']),
        total: _num(json['total']),
        due: _num(json['due']),
        supplierId: _intOrNull(json['supplierId']),
      );
}

/// What a photo upload answers: the photos that went up and how much room is
/// left on the bill.
class PhotoUpload {
  const PhotoUpload({
    required this.photos,
    required this.accepted,
    required this.remaining,
  });

  final List<PurchasePhoto> photos;
  final int accepted;
  final int remaining;
}
