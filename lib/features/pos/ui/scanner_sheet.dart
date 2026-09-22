import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';

/// The camera, returning one barcode.
///
/// Two things make this usable at a counter rather than a demo:
///
/// * **Repeat reads are swallowed.** MLKit fires the same code many times a
///   second while the label is in frame. The same value inside
///   [AppDurations.scanDebounce] is ignored, so one label is one item.
/// * **There is always a way out.** A blocked camera permission, a phone with
///   no camera, a scratched lens — any of them leaves the cashier able to type
///   the barcode instead. A till that can only be used one way is a till that
///   stops.
class ScannerSheet extends StatefulWidget {
  const ScannerSheet({super.key});

  /// Returns the scanned or typed code, or null if the sheet was dismissed.
  static Future<String?> show(BuildContext context) => showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: context.palette.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.sheet)),
        ),
        builder: (_) => const ScannerSheet(),
      );

  @override
  State<ScannerSheet> createState() => _ScannerSheetState();
}

class _ScannerSheetState extends State<ScannerSheet> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.qrCode,
    ],
  );
  final _manual = TextEditingController();

  String? _lastCode;
  DateTime? _lastAt;
  bool _failed = false;

  @override
  void dispose() {
    _controller.dispose();
    _manual.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final code = capture.barcodes
        .map((b) => b.rawValue)
        .firstWhere((v) => v != null && v.isNotEmpty, orElse: () => null);
    if (code == null) return;

    // The same label, read again a few milliseconds later, is not a second item.
    final now = DateTime.now();
    if (_lastCode == code &&
        _lastAt != null &&
        now.difference(_lastAt!) < AppDurations.scanDebounce) {
      return;
    }
    _lastCode = code;
    _lastAt = now;

    if (mounted) Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Insets.gutter,
                Insets.s12,
                Insets.s8,
                Insets.s8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.posScan,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (!_failed)
                    IconButton(
                      tooltip: l10n.torch,
                      icon: const Icon(Icons.flashlight_on_outlined),
                      onPressed: () => _controller.toggleTorch(),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _failed
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(Insets.s32),
                        child: Text(
                          l10n.cameraDenied,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        MobileScanner(
                          controller: _controller,
                          onDetect: _onDetect,
                          errorBuilder: (context, error) {
                            // Rebuilding into the manual path rather than
                            // showing a dead black rectangle.
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) setState(() => _failed = true);
                            });
                            return const SizedBox.shrink();
                          },
                        ),
                        IgnorePointer(
                          child: Center(
                            child: Container(
                              width: 240,
                              height: 140,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: palette.accent,
                                  width: 2,
                                ),
                                borderRadius:
                                    BorderRadius.circular(Radii.row),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: Insets.s24,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: Insets.s12,
                                vertical: Insets.s8,
                              ),
                              decoration: BoxDecoration(
                                color: palette.bg.withValues(alpha: 0.85),
                                borderRadius:
                                    BorderRadius.circular(Radii.pill),
                              ),
                              child: Text(
                                l10n.scanning,
                                style:
                                    Theme.of(context).textTheme.labelMedium,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(Insets.gutter),
                child: TextField(
                  controller: _manual,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) {
                    final code = value.trim();
                    if (code.isNotEmpty) Navigator.of(context).pop(code);
                  },
                  decoration: InputDecoration(
                    labelText: l10n.typeBarcode,
                    prefixIcon: const Icon(Icons.keyboard_outlined),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: () {
                        final code = _manual.text.trim();
                        if (code.isNotEmpty) Navigator.of(context).pop(code);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
