import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session/session_controller.dart';
import '../data/pos_models.dart';
import 'cart.dart';

/// An invoice open on the till for correcting.
///
/// Editing happens on the till itself — search, scan, quantities, prices,
/// discounts, customer and payment all work as they do for a sale — so the
/// cart the till was holding is parked in [parked] and handed back when the
/// edit ends, saved or not.
class InvoiceEdit {
  const InvoiceEdit({
    required this.saleId,
    required this.invoiceNo,
    required this.sold,
    required this.paid,
    required this.originalTotal,
    required this.parked,
    this.method,
    this.accountId,
  });

  final int saleId;
  final String invoiceNo;

  /// `{productId: qty}` this invoice took off the shelf. They go back before
  /// the new version is written, so they count as stock while editing.
  final Map<int, num> sold;

  /// How the invoice was paid.
  final num paid;
  final PayMethod? method;
  final int? accountId;

  /// The cart's own figure for the invoice as it was opened.
  final num originalTotal;

  /// The till's cart from before the edit.
  final Cart parked;

  /// [item] with this invoice's own units back in its stock. A package is left
  /// alone: an edit takes product lines only.
  SellableItem withSold(SellableItem item) {
    if (item.isPackage || item.stock == null) return item;
    final back = sold[item.id];
    return back == null || back == 0
        ? item
        : item.withStock(item.stock! + back);
  }

  /// What the payment starts at for a corrected bill of [total]: the whole of
  /// it when the invoice was paid in full, nothing when it was all on the
  /// khata, and otherwise what was paid — never more than the new bill.
  num openingPayment(num total) {
    if (paid <= 0) return 0;
    if (paid >= originalTotal - 0.01) return total;
    return paid < total ? paid : total;
  }
}

/// The invoice being edited, or null for an ordinary till.
class InvoiceEditController extends Notifier<InvoiceEdit?> {
  @override
  InvoiceEdit? build() {
    // A store or branch switch empties the till, and the invoice belongs to
    // the shop that was left.
    ref.watch(scopeKeyProvider);
    return null;
  }

  /// Parks whatever the till holds and puts [draft] in its place.
  void start(SaleEditDraft draft) {
    final current = state;
    // Starting over on another invoice keeps the till's own cart parked, not
    // the half-edited one.
    final Cart parked = current?.parked ?? ref.read(cartProvider);
    final cart = cartFromDraft(draft);
    ref.read(cartProvider.notifier).replace(cart);
    state = InvoiceEdit(
      saleId: draft.id,
      invoiceNo: draft.invoiceNo,
      sold: draft.sold,
      paid: draft.paid,
      method: draft.method,
      accountId: draft.accountId,
      originalTotal: cart.estimatedTotal.toDouble(),
      parked: parked,
    );
  }

  /// Ends the edit, saved or abandoned, and gives the till its cart back.
  void end() {
    final parked = state?.parked;
    state = null;
    ref.read(cartProvider.notifier).replace(parked ?? const Cart());
  }
}

final invoiceEditProvider =
    NotifierProvider<InvoiceEditController, InvoiceEdit?>(
      InvoiceEditController.new,
    );

/// The invoice as a cart. A price that differs from the product's own is kept
/// as the line's price, and a line discount as its discount, so saving without
/// touching anything writes the same bill. Two lines of one product become one
/// line, the way the till keeps them.
Cart cartFromDraft(SaleEditDraft draft) {
  final lines = <int, CartLine>{};
  for (final line in draft.lines) {
    if (line.productId == 0) continue;
    final existing = lines[line.productId];
    if (existing != null) {
      final off = (existing.lineDiscount ?? 0) + (line.discount ?? 0);
      lines[line.productId] = existing.copyWith(
        qty: existing.qty + line.qty,
        lineDiscount: off > 0 ? off : null,
      );
      continue;
    }
    lines[line.productId] = CartLine(
      item: SellableItem(
        id: line.productId,
        name: line.name,
        salePrice: line.basePrice,
        isPackage: false,
        unit: line.unit,
        vatPercent: line.vatPercent,
        stock: line.stock,
        purchasePrice: line.cost,
        mrp: line.mrp,
      ),
      qty: line.qty,
      unitPrice: line.unitPrice == line.basePrice ? null : line.unitPrice,
      lineDiscount: (line.discount ?? 0) > 0 ? line.discount : null,
    );
  }
  final customer = draft.customer;
  return Cart(
    lines: lines.values.toList(),
    customer: customer == null || customer.isWalkIn || customer.id == 0
        ? null
        : customer,
    orderDiscountPercent: (draft.orderDiscountPercent ?? 0) > 0
        ? draft.orderDiscountPercent
        : null,
    redeemPoints: draft.pointsRedeemed ?? 0,
    note: draft.note,
  );
}
