import '../../../core/format/dates.dart';
import '../../../core/network/envelope.dart';

int _int(Object? v) => switch (v) {
      final int x => x,
      final num x => x.toInt(),
      final String x => int.tryParse(x) ?? 0,
      _ => 0,
    };

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

/// Whether the sale itself stands. Distinct from how much of it was paid.
///
/// `void` arrived with the updated spec: the sale is undone entirely and drops
/// out of every revenue figure, but the row stays so the invoice number is
/// never silently reused.
enum SaleStatus {
  completed,
  returned,
  isVoid;

  static SaleStatus parse(String value) => switch (value) {
        'returned' => SaleStatus.returned,
        'void' => SaleStatus.isVoid,
        _ => SaleStatus.completed,
      };

  bool get isCancelled => this == SaleStatus.isVoid;
}

/// How much of the money arrived. Orthogonal to [SaleStatus]: a completed sale
/// can be unpaid, and a void one keeps whatever it last said.
enum PaymentStatus {
  paid,
  partial,
  unpaid;

  static PaymentStatus parse(String value) => switch (value) {
        'paid' => PaymentStatus.paid,
        'partial' => PaymentStatus.partial,
        _ => PaymentStatus.unpaid,
      };
}

/// A row in the invoice list.
class SaleListItem {
  const SaleListItem({
    required this.id,
    required this.invoiceNo,
    required this.total,
    required this.paid,
    required this.due,
    required this.status,
    required this.paymentStatus,
    required this.itemCount,
    this.saleDate,
    this.customer,
    this.seller,
    this.branch,
  });

  final int id;
  final String invoiceNo;
  final num total;
  final num paid;
  final num due;
  final SaleStatus status;
  final PaymentStatus paymentStatus;
  final int itemCount;
  final DateTime? saleDate;
  final String? customer;
  final String? seller;
  final String? branch;

  factory SaleListItem.fromJson(Map<String, dynamic> json) => SaleListItem(
        id: _int(json['id']),
        invoiceNo: _str(json['invoiceNo']),
        total: _num(json['total']),
        paid: _num(json['paid']),
        due: _num(json['due']),
        status: SaleStatus.parse(_str(json['status'])),
        paymentStatus: PaymentStatus.parse(_str(json['paymentStatus'])),
        itemCount: _int(json['itemCount']),
        saleDate: AppDates.parse(json['saleDate']),
        customer: _strOrNull(json['customer']),
        seller: _strOrNull(json['seller']),
        branch: _strOrNull(json['branch']),
      );
}

/// `meta.summary` on the list — the strip above it.
class SalesSummary {
  const SalesSummary({
    required this.count,
    required this.total,
    required this.due,
  });

  final int count;
  final num total;
  final num due;

  static SalesSummary? from(Meta meta) {
    final raw = meta.objectValue('summary');
    if (raw == null) return null;
    return SalesSummary(
      count: _int(raw['count']),
      total: _num(raw['total']),
      due: _num(raw['due']),
    );
  }
}

/// One line of an invoice. [id] is the `saleItemId` a return refers to.
class SaleItem {
  const SaleItem({
    required this.id,
    required this.name,
    required this.qty,
    required this.unitPrice,
    required this.total,
    this.unit,
    this.discount,
    this.vat,
  });

  final int id;
  final String name;
  final num qty;
  final num unitPrice;
  final num total;
  final String? unit;
  final num? discount;
  final num? vat;

  factory SaleItem.fromJson(Map<String, dynamic> json) => SaleItem(
        id: _int(json['id']),
        name: _str(json['name']),
        qty: _num(json['qty']),
        unitPrice: _num(json['unitPrice']),
        total: _num(json['total']),
        unit: _strOrNull(json['unit']),
        discount: _numOrNull(json['discount']),
        vat: _numOrNull(json['vat']),
      );
}

class SalePayment {
  const SalePayment({
    required this.method,
    required this.amount,
    this.account,
    this.reference,
  });

  final String method;
  final num amount;
  final String? account;
  final String? reference;

  factory SalePayment.fromJson(Map<String, dynamic> json) => SalePayment(
        method: _str(json['method']),
        amount: _num(json['amount']),
        account: _strOrNull(json['account']),
        reference: _strOrNull(json['reference']),
      );
}

/// A name, address and phone on the receipt. Used for both the branch and the
/// store, which carry the same three fields.
class ReceiptParty {
  const ReceiptParty({required this.name, this.address, this.phone});

  final String name;
  final String? address;
  final String? phone;

  factory ReceiptParty.fromJson(Map<String, dynamic>? json) => ReceiptParty(
        name: _str(json?['name']),
        address: _strOrNull(json?['address']),
        phone: _strOrNull(json?['phone']),
      );
}

/// Everything a detail screen and a receipt need, from `GET /sales/{id}`.
class SaleDetail {
  const SaleDetail({
    required this.id,
    required this.invoiceNo,
    required this.subtotal,
    required this.discount,
    required this.vat,
    required this.total,
    required this.paid,
    required this.due,
    required this.status,
    required this.paymentStatus,
    required this.items,
    required this.payments,
    required this.branch,
    required this.store,
    this.saleDate,
    this.note,
    this.customerName,
    this.customerPhone,
    this.seller,
    this.currency,
  });

  final int id;
  final String invoiceNo;
  final num subtotal;
  final num discount;
  final num vat;
  final num total;
  final num paid;
  final num due;
  final SaleStatus status;
  final PaymentStatus paymentStatus;
  final List<SaleItem> items;
  final List<SalePayment> payments;
  final ReceiptParty branch;
  final ReceiptParty store;
  final DateTime? saleDate;
  final String? note;
  final String? customerName;
  final String? customerPhone;
  final String? seller;
  final String? currency;

  bool get hasCustomer => (customerName ?? '').isNotEmpty;

  factory SaleDetail.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>?;
    final store = json['store'] as Map<String, dynamic>?;

    return SaleDetail(
      id: _int(json['id']),
      invoiceNo: _str(json['invoiceNo']),
      subtotal: _num(json['subtotal']),
      discount: _num(json['discount']),
      vat: _num(json['vat']),
      total: _num(json['total']),
      paid: _num(json['paid']),
      due: _num(json['due']),
      status: SaleStatus.parse(_str(json['status'])),
      paymentStatus: PaymentStatus.parse(_str(json['paymentStatus'])),
      items: _listOf(json['items'], SaleItem.fromJson),
      payments: _listOf(json['payments'], SalePayment.fromJson),
      branch: ReceiptParty.fromJson(json['branch'] as Map<String, dynamic>?),
      store: ReceiptParty.fromJson(store),
      saleDate: AppDates.parse(json['saleDate']),
      note: _strOrNull(json['note']),
      customerName: _strOrNull(customer?['name']),
      customerPhone: _strOrNull(customer?['phone']),
      seller: _strOrNull(json['seller']),
      currency: _strOrNull(store?['currency']),
    );
  }
}

/// A detail response and the `may*` flags that came with it.
///
/// The flags are tri-state and evaluated as `permission && (flag ?? true)`:
/// absent means the endpoint said nothing, so the permission alone decides.
/// `mayVoid` is the one that is genuinely informative — it is true only for a
/// **completed** invoice, so a returned or already-void one hides the action
/// even from an owner who holds `pos.sale.void`.
class SaleDetailResult {
  const SaleDetailResult({required this.sale, required this.meta});

  final SaleDetail sale;
  final Meta meta;

  bool? get mayVoid => meta.flag('mayVoid');
  bool? get mayReturn => meta.flag('mayReturn');
  bool? get mayCollect => meta.flag('mayCollect');
}

/// What `POST /sales/{id}/void` answers with. [restored] is how many units went
/// back on the shelf — worth reporting, because lines already returned are left
/// alone and the number is often smaller than the invoice's own item count.
class VoidResult {
  const VoidResult({
    required this.id,
    required this.invoiceNo,
    required this.restored,
  });

  final int id;
  final String invoiceNo;
  final num restored;

  factory VoidResult.fromJson(Map<String, dynamic> json) => VoidResult(
        id: _int(json['id']),
        invoiceNo: _str(json['invoiceNo']),
        restored: _num(json['restored']),
      );
}

/// What `POST /sales/{id}/returns` answers with.
class ReturnResult {
  const ReturnResult({
    required this.id,
    required this.returnNo,
    required this.total,
  });

  final int id;
  final String returnNo;
  final num total;

  factory ReturnResult.fromJson(Map<String, dynamic> json) => ReturnResult(
        id: _int(json['id']),
        returnNo: _str(json['returnNo']),
        total: _num(json['total']),
      );
}

List<T> _listOf<T>(Object? raw, T Function(Map<String, dynamic>) parse) {
  if (raw is! List) return const [];
  return raw.whereType<Map<String, dynamic>>().map(parse).toList();
}
