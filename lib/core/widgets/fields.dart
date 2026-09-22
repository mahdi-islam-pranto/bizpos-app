import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/palette.dart';
import '../theme/tokens.dart';

/// A quantity control sized for a thumb.
///
/// The number itself is tappable: typing `24` beats holding `+` twenty-four
/// times, which is the whole difference between a demo and a counter.
/// [max] is the branch stock — going past it is allowed but marked, because the
/// server is the one that refuses an oversell and it says so in its own words.
class QtyStepper extends StatelessWidget {
  const QtyStepper({
    required this.qty,
    required this.onChanged,
    this.max,
    this.min = 1,
    this.compact = false,
    super.key,
  });

  final num qty;
  final ValueChanged<num> onChanged;
  final num? max;
  final num min;
  final bool compact;

  bool get _overStock => max != null && qty > max!;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final size = compact ? 32.0 : 40.0;

    return Container(
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(
          color: _overStock ? palette.warning : palette.hairline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Round(
            icon: qty <= min ? Icons.delete_outline : Icons.remove,
            size: size,
            onTap: () => onChanged(qty - 1),
            tone: qty <= min ? palette.danger : palette.text,
          ),
          GestureDetector(
            onTap: () => _typeQty(context),
            child: Container(
              constraints: BoxConstraints(minWidth: size),
              alignment: Alignment.center,
              child: Text(
                _pretty(qty),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: _overStock ? palette.warning : palette.text,
                    ),
              ),
            ),
          ),
          _Round(
            icon: Icons.add,
            size: size,
            onTap: () => onChanged(qty + 1),
            tone: palette.text,
          ),
        ],
      ),
    );
  }

  static String _pretty(num value) =>
      value == value.roundToDouble() ? value.toStringAsFixed(0) : '$value';

  Future<void> _typeQty(BuildContext context) async {
    final controller = TextEditingController(text: _pretty(qty));
    final typed = await showDialog<num>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Quantity'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onSubmitted: (value) => Navigator.of(dialogContext)
              .pop(num.tryParse(value.trim())),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext)
                .pop(num.tryParse(controller.text.trim())),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (typed != null && typed >= min) onChanged(typed);
  }
}

class _Round extends StatelessWidget {
  const _Round({
    required this.icon,
    required this.size,
    required this.onTap,
    required this.tone,
  });

  final IconData icon;
  final double size;
  final VoidCallback onTap;
  final Color tone;

  @override
  Widget build(BuildContext context) => InkResponse(
        onTap: onTap,
        radius: size * 0.6,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: size * 0.5, color: tone),
        ),
      );
}

/// A money input.
///
/// Accepts digits and one decimal point and nothing else, so a cashier cannot
/// produce `12.3.4` and get a validation round-trip for it. The value read back
/// is a `num`, which is what every amount in the API is.
class AmountField extends StatelessWidget {
  const AmountField({
    required this.controller,
    required this.label,
    this.prefix,
    this.autofocus = false,
    this.enabled = true,
    this.errorText,
    this.helperText,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String? prefix;
  final bool autofocus;
  final bool enabled;
  final String? errorText;
  final String? helperText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;

  static num? read(TextEditingController controller) =>
      num.tryParse(controller.text.trim());

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        enabled: enabled,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.end,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
        ],
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          labelText: label,
          prefixText: prefix,
          errorText: errorText,
          helperText: helperText,
        ),
      );
}

/// A search field with a clear button and an optional trailing action (the
/// camera, on the POS screen).
class SearchField extends StatelessWidget {
  const SearchField({
    required this.controller,
    required this.hint,
    this.onChanged,
    this.onSubmitted,
    this.trailing,
    this.autofocus = false,
    this.focusNode,
    super.key,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? trailing;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
        valueListenable: controller,
        builder: (context, value, _) => TextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: autofocus,
          textInputAction: TextInputAction.search,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: const Icon(Icons.search),
            isDense: true,
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (value.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: MaterialLocalizations.of(context)
                        .deleteButtonTooltip,
                    onPressed: () {
                      controller.clear();
                      onChanged?.call('');
                    },
                  ),
                ?trailing,
              ],
            ),
          ),
        ),
      );
}

/// A small coloured label: payment status, stock state, shift state.
class StatusChip extends StatelessWidget {
  const StatusChip({
    required this.label,
    required this.tone,
    this.icon,
    super.key,
  });

  final String label;
  final Color tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.s8,
          vertical: 3,
        ),
        decoration: BoxDecoration(
          // A wash of the tone rather than the tone itself: a list of rows each
          // shouting in full-strength colour is unreadable.
          color: tone.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: tone),
              const SizedBox(width: Insets.s4),
            ],
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: tone, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
}
