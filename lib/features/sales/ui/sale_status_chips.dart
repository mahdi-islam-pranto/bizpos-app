import 'package:flutter/material.dart';

import '../../../core/theme/palette.dart';
import '../../../core/widgets/fields.dart';
import '../../../l10n/app_localizations.dart';
import '../data/sale_models.dart';

/// The two statuses an invoice carries, as chips.
///
/// They are separate on purpose: `status` says whether the sale stands,
/// `paymentStatus` says how much of the money arrived, and a void invoice can
/// still read "paid" from before it was cancelled. Showing one colour for both
/// would make a cancelled sale look collectable.
extension SaleStatusPresentation on SaleStatus {
  String label(AppL10n l10n) => switch (this) {
        SaleStatus.completed => l10n.statusCompleted,
        SaleStatus.returned => l10n.statusReturned,
        SaleStatus.isVoid => l10n.statusVoid,
      };

  Color tone(AppPalette palette) => switch (this) {
        SaleStatus.completed => palette.positive,
        SaleStatus.returned => palette.warning,
        SaleStatus.isVoid => palette.danger,
      };
}

extension PaymentStatusPresentation on PaymentStatus {
  String label(AppL10n l10n) => switch (this) {
        PaymentStatus.paid => l10n.statusPaid,
        PaymentStatus.partial => l10n.statusPartial,
        PaymentStatus.unpaid => l10n.statusUnpaid,
      };

  Color tone(AppPalette palette) => switch (this) {
        PaymentStatus.paid => palette.positive,
        PaymentStatus.partial => palette.warning,
        PaymentStatus.unpaid => palette.danger,
      };
}

class PaymentStatusChip extends StatelessWidget {
  const PaymentStatusChip(this.status, {super.key});

  final PaymentStatus status;

  @override
  Widget build(BuildContext context) => StatusChip(
        label: status.label(AppL10n.of(context)),
        tone: status.tone(context.palette),
      );
}

/// Only drawn when the sale is not an ordinary completed one — a chip saying
/// "completed" on every row is noise a person learns to stop reading.
class SaleStatusChip extends StatelessWidget {
  const SaleStatusChip(this.status, {super.key});

  final SaleStatus status;

  @override
  Widget build(BuildContext context) {
    if (status == SaleStatus.completed) return const SizedBox.shrink();

    return StatusChip(
      label: status.label(AppL10n.of(context)),
      tone: status.tone(context.palette),
      icon: status.isCancelled ? Icons.block : Icons.undo,
    );
  }
}
