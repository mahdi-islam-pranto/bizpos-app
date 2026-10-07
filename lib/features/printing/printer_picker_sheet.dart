import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_sheet.dart';
import '../../l10n/app_localizations.dart';
import 'printer_service.dart';

/// What the person decided in the picker.
enum PickerResult { chosen, saveImage }

/// The phone's paired Bluetooth printers, and the paper in them.
///
/// Pairing itself happens in the phone's Bluetooth settings — that is where
/// the PIN goes — so this lists what is already paired rather than scanning.
class PrinterPickerSheet extends ConsumerStatefulWidget {
  const PrinterPickerSheet({super.key});

  static Future<PickerResult?> show(BuildContext context) =>
      showAppSheet<PickerResult>(
        context,
        title: AppL10n.of(context).choosePrinter,
        builder: (_) => const PrinterPickerSheet(),
      );

  @override
  ConsumerState<PrinterPickerSheet> createState() => _PrinterPickerSheetState();
}

class _PrinterPickerSheetState extends ConsumerState<PrinterPickerSheet> {
  late Future<(BluetoothState, List<PairedPrinter>)> _load = _find();

  Future<(BluetoothState, List<PairedPrinter>)> _find() async {
    final transport = ref.read(printerTransportProvider);
    final state = await transport.check();
    if (state != BluetoothState.ready) return (state, const <PairedPrinter>[]);
    return (state, await transport.paired());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final setup = ref.watch(printerSetupProvider).value ?? const PrinterSetup();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Insets.gutter),
          child: Row(
            children: [
              Expanded(child: Text(l10n.paperWidth, style: text.bodyMedium)),
              SegmentedButton<ReceiptPaper>(
                segments: [
                  for (final paper in ReceiptPaper.values)
                    ButtonSegment(value: paper, label: Text(paper.wire)),
                ],
                selected: {setup.paper},
                showSelectedIcon: false,
                onSelectionChanged: (picked) => ref
                    .read(printerSetupProvider.notifier)
                    .setPaper(picked.single),
              ),
            ],
          ),
        ),
        const SizedBox(height: Insets.s8),
        Flexible(
          child: FutureBuilder(
            future: _load,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(Insets.s32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final (state, printers) =
                  snapshot.data ??
                  (BluetoothState.denied, const <PairedPrinter>[]);
              final problem = switch (state) {
                BluetoothState.denied => l10n.bluetoothDenied,
                BluetoothState.off => l10n.bluetoothOff,
                BluetoothState.ready when printers.isEmpty =>
                  l10n.noPairedPrinters,
                _ => null,
              };
              if (problem != null) {
                return Padding(
                  padding: const EdgeInsets.all(Insets.gutter),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.print_disabled_outlined, color: palette.muted),
                      const SizedBox(height: Insets.s8),
                      Text(
                        problem,
                        textAlign: TextAlign.center,
                        style: text.bodyMedium?.copyWith(color: palette.muted),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _load = _find()),
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                );
              }
              return ListView(
                shrinkWrap: true,
                children: [
                  for (final printer in printers)
                    ListTile(
                      leading: const Icon(Icons.print_outlined),
                      title: Text(printer.name),
                      subtitle: Text(printer.mac),
                      selected: printer.mac == setup.mac,
                      trailing: printer.mac == setup.mac
                          ? Icon(Icons.check, color: palette.accent)
                          : null,
                      onTap: () async {
                        await ref
                            .read(printerSetupProvider.notifier)
                            .choose(printer.name, printer.mac);
                        if (context.mounted) {
                          Navigator.of(context).pop(PickerResult.chosen);
                        }
                      },
                    ),
                ],
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(Insets.gutter),
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(PickerResult.saveImage),
              icon: const Icon(Icons.image_outlined),
              label: Text(l10n.saveAsImage),
            ),
          ),
        ),
      ],
    );
  }
}
