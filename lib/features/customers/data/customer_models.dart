import '../../../core/format/dates.dart';

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

bool _bool(Object? v) => v == true || v == 1 || v == 'true';

/// A customer as `GET /customers` returns one.
///
/// Three fields are nullable because the server tells a weaker role less, not
/// because the data is missing: [loyaltyPoints] is null without
/// `customers.points.view`, and [creditLimit] means nothing to a role that
/// cannot manage credit. Treating a null as a zero would turn "we are not
/// telling you" into "there is none".
class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.isWalkIn,
    required this.saleCount,
    required this.due,
    this.phone,
    this.email,
    this.address,
    this.creditLimit,
    this.loyaltyPoints,
    this.group,
    this.addedBy,
    this.changedBy,
  });

  final int id;
  final String name;

  /// The store's one anonymous customer. It cannot buy on credit and is not
  /// worth editing, so the list hides its actions.
  final bool isWalkIn;

  final int saleCount;
  final num due;
  final String? phone;
  final String? email;
  final String? address;
  final num? creditLimit;
  final num? loyaltyPoints;
  final String? group;
  final String? addedBy;
  final String? changedBy;

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        id: _int(json['id']),
        name: _str(json['name']),
        isWalkIn: _bool(json['isWalkIn']),
        saleCount: _int(json['saleCount']),
        due: _num(json['due']),
        phone: _strOrNull(json['phone']),
        email: _strOrNull(json['email']),
        address: _strOrNull(json['address']),
        creditLimit: _numOrNull(json['creditLimit']),
        loyaltyPoints: _numOrNull(json['loyaltyPoints']),
        group: _strOrNull(json['group']),
        addedBy: _strOrNull(json['addedBy']),
        changedBy: _strOrNull(json['changedBy']),
      );
}

/// A row on `GET /customers/{id}/ledger` — the last 100 movements.
class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.refType,
    required this.debit,
    required this.credit,
    required this.balance,
    this.note,
    this.date,
  });

  final int id;

  /// `sale`, `payment`, `return`, ... what moved the balance.
  final String refType;

  /// What the customer was charged.
  final num debit;

  /// What the customer paid.
  final num credit;

  /// Running balance after this row.
  final num balance;

  final String? note;
  final DateTime? date;

  factory LedgerEntry.fromJson(Map<String, dynamic> json) => LedgerEntry(
        id: _int(json['id']),
        refType: _str(json['refType']),
        debit: _num(json['debit']),
        credit: _num(json['credit']),
        balance: _num(json['balance']),
        note: _strOrNull(json['note']),
        date: AppDates.parse(json['date']),
      );
}

/// `GET /customers/{id}/points`.
class PointsAccount {
  const PointsAccount({
    required this.balance,
    required this.worth,
    required this.ledger,
  });

  final num balance;

  /// What the balance is worth in money, as the server reckons it.
  final num worth;
  final List<LedgerEntry> ledger;

  factory PointsAccount.fromJson(Map<String, dynamic> json) => PointsAccount(
        balance: _num(json['balance']),
        worth: _num(json['worth']),
        ledger: (json['ledger'] is List)
            ? (json['ledger'] as List)
                .whereType<Map<String, dynamic>>()
                .map(LedgerEntry.fromJson)
                .toList()
            : const [],
      );
}
