import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format/money.dart';
import '../../core/session/session_controller.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/async_view.dart';
import '../../l10n/app_localizations.dart';
import '../sales/data/sale_models.dart';
import '../sales/data/sales_repository.dart';
import 'printer_picker_sheet.dart';
import 'printer_service.dart';
import 'receipt_view.dart';

/// The receipt as it will come out of the printer, with Print beside it.
///
/// Built from `GET /sales/{id}`, never from the cart: the server's totals are
/// the sale. Print sends it to this phone's Bluetooth printer; with no printer
/// to reach — none chosen, Bluetooth off or refused, or the printer not
/// answering — the same picture is saved to the gallery instead, so a sale
/// never leaves without its receipt.
class ReceiptSheet extends ConsumerStatefulWidget {
  const ReceiptSheet({required this.saleId, this.afterSale = false, super.key});

  final int saleId;

  /// Straight after checkout: offers "Next sale" beside Print.
  final bool afterSale;

  static Future<void> show(
    BuildContext context, {
    required int saleId,
    bool afterSale = false,
  }) => showAppSheet<void>(
    context,
    title: AppL10n.of(context).receiptTitle,
    builder: (_) => ReceiptSheet(saleId: saleId, afterSale: afterSale),
  );

  @override
  ConsumerState<ReceiptSheet> createState() => _ReceiptSheetState();
}

class _ReceiptSheetState extends ConsumerState<ReceiptSheet> {
  final _boundary = GlobalKey();
  bool _busy = false;

  RenderRepaintBoundary? get _render =>
      _boundary.currentContext?.findRenderObject() as RenderRepaintBoundary?;

  Future<void> _run(Future<void> Function() job) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await job();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// The first print on a phone asks which printer; the spinner waits until
  /// that choice is made, so it never turns behind an open picker.
  Future<void> _print(SaleDetail sale) async {
    if (_busy) return;
    var setup = await ref.read(printerSetupProvider.future);
    if (!mounted) return;

    if (!setup.hasPrinter) {
      final picked = await PrinterPickerSheet.show(context);
      if (!mounted || picked == null) return;
      if (picked == PickerResult.saveImage) {
        return _run(() => _saveImage(sale));
      }
      setup = await ref.read(printerSetupProvider.future);
      // The paper may have changed in the picker; let the preview re-lay
      // itself out at the new width before it is captured.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
    }
    await _run(() => _send(sale, setup));
  }

  Future<void> _send(SaleDetail sale, PrinterSetup setup) async {
    final l10n = AppL10n.of(context);
    final transport = ref.read(printerTransportProvider);
    final state = await transport.check();
    if (!mounted) return;
    if (state != BluetoothState.ready) {
      return _saveImage(
        sale,
        why: state == BluetoothState.off
            ? l10n.bluetoothOffSaved
            : l10n.bluetoothDeniedSaved,
      );
    }

    final render = _render;
    if (render == null) return;
    try {
      final bytes = await ReceiptOutput.rasterFor(render, setup.paper);
      await transport.send(setup.mac!, bytes);
      if (mounted) showNote(context, l10n.printSent(setup.name ?? ''));
    } catch (_) {
      if (!mounted) return;
      await _saveImage(
        sale,
        why: l10n.printerUnreachableSaved(setup.name ?? ''),
      );
    }
  }

  /// [why] says what stopped the print; without it this is a plain save.
  Future<void> _saveImage(SaleDetail sale, {String? why}) async {
    final l10n = AppL10n.of(context);
    final render = _render;
    if (render == null) return;
    final saved = await ReceiptOutput.saveToGallery(
      await ReceiptOutput.pngFor(render),
      sale.invoiceNo,
    );
    if (!mounted) return;
    showNote(
      context,
      saved ? (why ?? l10n.receiptSaved) : l10n.receiptSaveFailed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(saleDetailProvider(widget.saleId));

    return AsyncView<SaleDetailResult>(
      value: detail,
      onRetry: () => ref.invalidate(saleDetailProvider(widget.saleId)),
      builder: (context, result) => _body(context, result.sale),
    );
  }

  Widget _body(BuildContext context, SaleDetail sale) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final setup = ref.watch(printerSetupProvider).value ?? const PrinterSetup();
    final money = ref.watch(moneyProvider);
    final locale = ref.watch(meProvider)?.user.locale ?? 'en';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Insets.gutter),
          child: Row(
            children: [
              Icon(Icons.print_outlined, size: 18, color: palette.muted),
              const SizedBox(width: Insets.s8),
              Expanded(
                child: Text(
                  setup.hasPrinter
                      ? '${setup.name} · ${setup.paper.wire}'
                      : l10n.noPrinterChosen,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(color: palette.muted),
                ),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => PrinterPickerSheet.show(context).then((picked) {
                        if (picked == PickerResult.saveImage && mounted) {
                          _run(() => _saveImage(sale));
                        }
                      }),
                child: Text(l10n.changePrinter),
              ),
            ],
          ),
        ),
        Flexible(
          child: Container(
            color: palette.surfaceAlt,
            width: double.infinity,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Insets.s16),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    // Exactly what is captured: the receipt and nothing else.
                    child: RepaintBoundary(
                      key: _boundary,
                      child: SizedBox(
                        width: setup.paper.logicalWidth,
                        child: ReceiptView(
                          sale: sale,
                          money: money,
                          locale: locale,
                          paper: setup.paper,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(Insets.gutter),
            child: Row(
              children: [
                IconButton.outlined(
                  tooltip: l10n.saveAsImage,
                  onPressed: _busy
                      ? null
                      : () => _run(() => _saveImage(sale)),
                  icon: const Icon(Icons.image_outlined),
                ),
                const SizedBox(width: Insets.s12),
                if (widget.afterSale) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.newSale),
                    ),
                  ),
                  const SizedBox(width: Insets.s12),
                ],
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : () => _print(sale),
                    icon: _busy
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.print),
                    label: Text(l10n.printReceipt),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
