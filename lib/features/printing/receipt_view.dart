import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/format/money.dart';
import '../../l10n/app_localizations.dart';
import '../sales/data/sale_models.dart';
import 'printer_service.dart';

/// The printed slip, as a widget: black on white, one column, monospaced.
///
/// It is laid out at [paper]'s logical width and captured at the printer's dot
/// width, so what the preview shows is, pixel for pixel, what the paper gets.
/// It reads no theme — a dark-mode phone must not print a black receipt — and
/// every figure on it is the server's, from `GET /sales/{id}`.
class ReceiptView extends StatelessWidget {
  const ReceiptView({
    required this.sale,
    required this.money,
    required this.locale,
    required this.paper,
    super.key,
  });

  final SaleDetail sale;
  final Money money;
  final String locale;
  final ReceiptPaper paper;

  static const _ink = Colors.black;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tag = locale == 'bn' ? 'bn_BD' : 'en_US';
    final base = paper == ReceiptPaper.mm58 ? 11.5 : 13.0;

    TextStyle style({double scale = 1, bool bold = false}) => TextStyle(
      fontFamily: 'monospace',
      fontFamilyFallback: const ['Roboto Mono', 'Courier', 'Noto Sans Bengali'],
      color: _ink,
      fontSize: base * scale,
      height: 1.3,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    // Item figures without the currency sign, as on any till slip: the sign
    // belongs to the totals, and a column of them is noise.
    final figure = NumberFormat('#0.00', tag);
    String fig(num v) => figure.format(v);
    String pct(num v) => '${NumberFormat('#0.##', tag).format(v)}%';

    final phone = sale.branch.phone ?? sale.store.phone;
    final address = sale.branch.address ?? sale.store.address;
    final at = sale.saleDate?.toLocal();
    final lineOff = sale.lineDiscount ?? 0;
    final billOff = sale.orderDiscount ?? 0;
    final split = lineOff > 0 && billOff > 0;

    Widget pair(String left, String right, {TextStyle? s, TextStyle? r}) =>
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(left, style: s ?? style())),
            const SizedBox(width: 8),
            Text(right, style: r ?? s ?? style(), textAlign: TextAlign.end),
          ],
        );

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 18),
      child: DefaultTextStyle(
        style: style(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              sale.store.name,
              textAlign: TextAlign.center,
              style: style(scale: 1.35, bold: true),
            ),
            if ((sale.branch.name).isNotEmpty &&
                sale.branch.name != sale.store.name)
              Text(
                sale.branch.name,
                textAlign: TextAlign.center,
                style: style(scale: 0.9),
              ),
            if ((address ?? '').isNotEmpty)
              Text(address!, textAlign: TextAlign.center, style: style(scale: 0.9)),
            if ((phone ?? '').isNotEmpty)
              Text(phone!, textAlign: TextAlign.center),
            if (sale.status.isCancelled) ...[
              const SizedBox(height: 6),
              Text(
                '*** ${l10n.statusVoid.toUpperCase()} ***',
                textAlign: TextAlign.center,
                style: style(scale: 1.2, bold: true),
              ),
            ],
            const _Rule(),
            pair(l10n.invoice, sale.invoiceNo, r: style(bold: true)),
            if (at != null)
              pair(
                DateFormat('dd MMM y', tag).format(at),
                DateFormat('HH:mm', tag).format(at),
              ),
            if ((sale.seller ?? '').isNotEmpty)
              pair(l10n.receiptServedBy, sale.seller!),
            if (sale.hasCustomer)
              pair(
                l10n.customer,
                [
                  sale.customerName!,
                  if ((sale.customerPhone ?? '').isNotEmpty) sale.customerPhone!,
                ].join('\n'),
              ),
            const _Rule(),
            pair(l10n.receiptItem, l10n.receiptAmount),
            const _Rule(),
            for (var i = 0; i < sale.items.length; i++) ...[
              if (i > 0) const _Rule(light: true),
              _Item(
                item: sale.items[i],
                style: style,
                fig: fig,
                pct: pct,
                l10n: l10n,
              ),
            ],
            const _Rule(),
            pair(l10n.subtotal, money.format(sale.subtotal)),
            if (split) ...[
              pair(l10n.receiptLineDiscounts, '−${money.format(lineOff)}'),
              pair(
                _withRate(l10n.orderDiscount, sale.discountPercent, pct),
                '−${money.format(billOff)}',
              ),
            ] else if (sale.discount > 0)
              pair(
                billOff > 0
                    ? _withRate(l10n.discount, sale.discountPercent, pct)
                    : l10n.discount,
                '−${money.format(sale.discount)}',
              ),
            if (sale.vat > 0) pair(l10n.vatLabel, money.format(sale.vat)),
            const _Rule(solid: true),
            pair(
              l10n.receiptTotal,
              money.format(sale.total),
              s: style(scale: 1.25, bold: true),
            ),
            if ((sale.mrpSaving ?? 0) > 0)
              pair(
                l10n.receiptYouSaved,
                money.format(sale.mrpSaving),
                s: style(bold: true),
              ),
            const _Rule(),
            for (final payment in sale.payments)
              pair(payment.method.toUpperCase(), money.format(payment.amount)),
            if (sale.payments.isEmpty)
              pair(l10n.paidLabel, money.format(sale.paid)),
            if (sale.due > 0)
              pair(l10n.dueLabel, money.format(sale.due), s: style(bold: true)),
            if ((sale.previousDue ?? 0) > 0)
              pair(l10n.previousDueLabel, money.format(sale.previousDue)),
            if ((sale.note ?? '').isNotEmpty) ...[
              const _Rule(),
              Text(sale.note!, style: style(scale: 0.9)),
            ],
            const _Rule(),
            const SizedBox(height: 4),
            Text(l10n.receiptThanks, textAlign: TextAlign.center),
            const SizedBox(height: 2),
            Text('BizPOS', textAlign: TextAlign.center, style: style(scale: 0.85)),
          ],
        ),
      ),
    );
  }

  static String _withRate(String label, num? rate, String Function(num) pct) =>
      rate == null || rate <= 0 ? label : '$label (${pct(rate)})';
}

class _Item extends StatelessWidget {
  const _Item({
    required this.item,
    required this.style,
    required this.fig,
    required this.pct,
    required this.l10n,
  });

  final SaleItem item;
  final TextStyle Function({double scale, bool bold}) style;
  final String Function(num) fig;
  final String Function(num) pct;
  final AppL10n l10n;

  @override
  Widget build(BuildContext context) {
    final qty = item.qty == item.qty.roundToDouble()
        ? item.qty.toStringAsFixed(0)
        : item.qty.toString();
    final small = style(scale: 0.88);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(item.name),
        Row(
          children: [
            Expanded(
              child: Text(
                '$qty${item.unit == null ? '' : ' ${item.unit}'} × '
                '${fig(item.unitPrice)}',
              ),
            ),
            Text(fig(item.total)),
          ],
        ),
        // The saving against the printed price is already inside the
        // selling price; it is shown, never subtracted.
        if ((item.mrp ?? 0) > item.unitPrice && (item.mrpDiscount ?? 0) > 0)
          Text(
            l10n.receiptMrpSave(
              fig(item.mrp!),
              fig(item.mrpDiscount!),
              item.mrpDiscountPercent == null
                  ? ''
                  : ' (${pct(item.mrpDiscountPercent!)})',
            ),
            style: small,
          ),
        if ((item.discount ?? 0) > 0)
          Text(
            '${l10n.discount} −${fig(item.discount!)}'
            '${item.discountPercent == null ? '' : ' (${pct(item.discountPercent!)})'}',
            style: small,
          ),
      ],
    );
  }
}

/// A dashed rule between sections; [solid] above the total, [light] between
/// items.
class _Rule extends StatelessWidget {
  const _Rule({this.solid = false, this.light = false});

  final bool solid;
  final bool light;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: light ? 4 : 6),
    child: CustomPaint(
      size: const Size(double.infinity, 1.4),
      painter: _RulePainter(solid: solid, light: light),
    ),
  );
}

class _RulePainter extends CustomPainter {
  const _RulePainter({required this.solid, required this.light});

  final bool solid;
  final bool light;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = light ? 0.8 : 1.2;
    final y = size.height / 2;
    if (solid) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      return;
    }
    final dash = light ? 2.0 : 4.0;
    final gap = light ? 3.0 : 3.0;
    for (var x = 0.0; x < size.width; x += dash + gap) {
      canvas.drawLine(Offset(x, y), Offset(x + dash, y), paint);
    }
  }

  @override
  bool shouldRepaint(_RulePainter old) =>
      old.solid != solid || old.light != light;
}
