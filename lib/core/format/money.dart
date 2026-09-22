import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../session/session_controller.dart';

/// Formats money in the store's own currency.
///
/// Every amount in the API is a plain JSON number in `store.currency` (usually
/// `BDT`), so there is exactly one place that decides how it reads. Figures are
/// tabular, because a cart and an invoice are columns of numbers that must line
/// up.
class Money {
  const Money(this.currency, {this.symbol, required this.locale});

  /// `BDT`, `USD`, ... straight from `/me`.
  final String currency;

  /// What is drawn in front of the number. Falls back to the code itself.
  final String? symbol;

  /// `en` or `bn`. Bangla renders its own digits, which is what a shopkeeper
  /// reading a Bangla app expects.
  final String locale;

  static const Map<String, String> _symbols = {
    'BDT': '৳',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'INR': '₹',
    'PKR': '₨',
  };

  String get sign => symbol ?? _symbols[currency.toUpperCase()] ?? currency;

  /// `৳1,250.50`. Two decimals, because a price of 1.2 and a price of 1.25 are
  /// different prices and rounding one away is a wrong receipt.
  String format(num? amount) {
    final value = amount ?? 0;
    final formatter = NumberFormat.currency(
      locale: locale == 'bn' ? 'bn_BD' : 'en_US',
      symbol: sign,
      decimalDigits: _hasPaisa(value) ? 2 : 0,
    );
    return formatter.format(value);
  }

  /// The number alone, for a field a person types into.
  String plain(num? amount) {
    final value = amount ?? 0;
    return _hasPaisa(value)
        ? value.toStringAsFixed(2)
        : value.toStringAsFixed(0);
  }

  /// Whole taka lose the `.00`: a counter reads `৳120` faster than `৳120.00`,
  /// and the paisa are still shown the moment they exist.
  static bool _hasPaisa(num value) =>
      (value * 100).round() % 100 != 0;
}

final moneyProvider = Provider<Money>((ref) {
  final me = ref.watch(meProvider);
  return Money(
    me?.store?.currency ?? 'BDT',
    locale: me?.user.locale ?? 'en',
  );
});

/// Exact arithmetic for anything the app adds up itself.
///
/// The server is the authority on every total — `POST /pos/checkout` returns
/// the real one and the receipt shows *that*. But a cart still has to show a
/// running subtotal while the person is deciding, and `1.2 * 10` in binary
/// floating point is `11.999999999999998`. [Decimal] keeps the preview honest,
/// so the number on screen never disagrees with the number on the receipt by a
/// stray paisa.
class Exact {
  const Exact._();

  static Decimal of(num value) => Decimal.parse(value.toString());

  static Decimal sum(Iterable<Decimal> values) =>
      values.fold(Decimal.zero, (a, b) => a + b);

  /// Back to a plain number for display and for the JSON body.
  static double toDouble(Decimal value) => value.toDouble();

  /// Rounds to paisa, the smallest unit anyone can actually pay.
  static Decimal paisa(Decimal value) =>
      value.round(scale: 2);
}
