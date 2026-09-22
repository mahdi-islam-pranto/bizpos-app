import 'package:intl/intl.dart';

/// Dates as a counter reads them.
///
/// The API sends ISO 8601 with an offset (`2026-09-13T14:05:00+06:00`), which
/// `DateTime.parse` handles; everything here works on the local time that comes
/// out of it, because a shift and a sale are local events to the person holding
/// the phone.
class AppDates {
  const AppDates._();

  static DateTime? parse(Object? value) {
    if (value is DateTime) return value;
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  static String _l(String locale) => locale == 'bn' ? 'bn_BD' : 'en_US';

  /// `13 Sep, 2:05 pm` — what an invoice row shows.
  static String stamp(DateTime? at, {String locale = 'en'}) {
    if (at == null) return '';
    return DateFormat('d MMM, h:mm a', _l(locale)).format(at);
  }

  /// `13 Sep 2026`.
  static String day(DateTime? at, {String locale = 'en'}) {
    if (at == null) return '';
    return DateFormat('d MMM y', _l(locale)).format(at);
  }

  /// `2:05 pm`.
  static String time(DateTime? at, {String locale = 'en'}) {
    if (at == null) return '';
    return DateFormat('h:mm a', _l(locale)).format(at);
  }

  /// Report buckets are `YYYY-MM-DD`, with no time and no offset.
  static String bucket(DateTime at) => DateFormat('yyyy-MM-dd').format(at);

  /// "Today", "Yesterday", else the date — for grouping an invoice list.
  static String relativeDay(
    DateTime? at, {
    required String today,
    required String yesterday,
    String locale = 'en',
  }) {
    if (at == null) return '';
    final now = DateTime.now();
    final thatDay = DateTime(at.year, at.month, at.day);
    final days = DateTime(now.year, now.month, now.day)
        .difference(thatDay)
        .inDays;
    if (days == 0) return today;
    if (days == 1) return yesterday;
    return day(at, locale: locale);
  }
}
