import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../data/report_models.dart';

/// One headline number.
class Figure {
  const Figure(this.label, this.value, {this.tone, this.note, this.locked = false});

  final String label;
  final String value;
  final Color? tone;
  final String? note;

  /// The figure exists but this person may not see it — profit for a
  /// manager. Shown as a lock, never as a zero.
  final bool locked;
}

/// Figures two to a row. Wraps rather than scales, so Bangla — a good deal
/// wider than English — gets a taller tile instead of a clipped number.
class FigureGrid extends StatelessWidget {
  const FigureGrid(this.figures, {super.key});

  final List<Figure> figures;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth > 560 ? 3 : 2;
          final width =
              (constraints.maxWidth - Insets.s8 * (columns - 1)) / columns;
          return Wrap(
            spacing: Insets.s8,
            runSpacing: Insets.s8,
            children: [
              for (final f in figures)
                SizedBox(width: width, child: FigureTile(f)),
            ],
          );
        },
      );
}

class FigureTile extends StatelessWidget {
  const FigureTile(this.figure, {super.key});

  final Figure figure;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final l10n = AppL10n.of(context);

    return Container(
      padding: const EdgeInsets.all(Insets.s12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(Radii.row),
        border: Border.all(color: palette.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            figure.label,
            maxLines: 2,
            style: text.labelSmall?.copyWith(color: palette.muted),
          ),
          const SizedBox(height: Insets.s4),
          if (figure.locked)
            Row(
              children: [
                Icon(Icons.lock_outline, size: 16, color: palette.muted),
                const SizedBox(width: Insets.s4),
                Flexible(
                  child: Text(
                    l10n.notYours,
                    style: text.bodySmall?.copyWith(color: palette.muted),
                  ),
                ),
              ],
            )
          else
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                figure.value,
                style: text.titleMedium?.copyWith(
                  color: figure.tone,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          if (figure.note != null) ...[
            const SizedBox(height: Insets.s4),
            Text(
              figure.note!,
              style: text.labelSmall?.copyWith(color: palette.muted),
            ),
          ],
        ],
      ),
    );
  }
}

/// A titled group on a report or the dashboard.
class ReportSection extends StatelessWidget {
  const ReportSection({
    required this.title,
    required this.child,
    this.scope,
    super.key,
  });

  final String title;
  final Widget child;

  /// Which part of the shop the figures cover — see [ScopeLabel].
  final ReportScope? scope;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsets.only(top: Insets.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: Insets.s4, bottom: Insets.s8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: text.labelSmall?.copyWith(
                      color: palette.muted,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                if (scope != null) ScopeLabel(scope!),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

enum ReportScope { branch, store, mixed }

/// Sales, stock and profit's revenue and cost are per **branch**; returns,
/// expenses and dues are **store-wide**. A report that does not say which
/// invites an owner to add a branch figure to a store one.
class ScopeLabel extends StatelessWidget {
  const ScopeLabel(this.scope, {super.key});

  final ReportScope scope;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final (icon, label) = switch (scope) {
      ReportScope.branch => (Icons.storefront_outlined, l10n.scopeBranch),
      ReportScope.store => (Icons.business_outlined, l10n.scopeStore),
      ReportScope.mixed => (Icons.call_split, l10n.scopeMixed),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: palette.muted),
        const SizedBox(width: Insets.s4),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: palette.muted),
        ),
      ],
    );
  }
}

/// A section this person may not see. Said plainly, so a dashboard missing
/// its profit does not pass for one where profit simply is not tracked.
class LockedSection extends StatelessWidget {
  const LockedSection({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);
    return Container(
      padding: const EdgeInsets.all(Insets.s12),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(Radii.row),
        border: Border.all(color: palette.hairline),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, size: 18, color: palette.muted),
          const SizedBox(width: Insets.s8),
          Expanded(
            child: Text(
              l10n.sectionLocked,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: palette.muted),
            ),
          ),
        ],
      ),
    );
  }
}

/// A quiet "nothing here" line inside a section.
class SectionEmpty extends StatelessWidget {
  const SectionEmpty(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.s4,
          vertical: Insets.s8,
        ),
        child: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: context.palette.muted),
        ),
      );
}

/// A bordered list of rows.
class RowsCard extends StatelessWidget {
  const RowsCard({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.row),
        side: BorderSide(color: palette.hairline),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, color: palette.hairline),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// A label, an optional line under it, and a figure on the right.
class FigureRow extends StatelessWidget {
  const FigureRow({
    required this.label,
    required this.value,
    this.detail,
    this.tone,
    this.share,
    this.onTap,
    super.key,
  });

  final String label;
  final String value;
  final String? detail;
  final Color? tone;

  /// 0–1: a hairline bar under the row showing its part of the whole, for
  /// lists that are shares of one total (payment methods, expense types).
  final double? share;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.s12,
          vertical: Insets.s12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodyMedium,
                      ),
                      if (detail != null)
                        Text(
                          detail!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall?.copyWith(color: palette.muted),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: Insets.s8),
                Text(
                  value,
                  style: text.titleSmall?.copyWith(
                    color: tone,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            if (share != null) ...[
              const SizedBox(height: Insets.s8),
              ClipRRect(
                borderRadius: BorderRadius.circular(Radii.pill),
                child: LinearProgressIndicator(
                  value: share!.clamp(0, 1),
                  minHeight: 4,
                  color: palette.accent,
                  backgroundColor: palette.surfaceAlt,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One bar a day: the trend, not the ledger.
///
/// A single series in the accent colour, so there is no legend — the section
/// title names it. Bars are thin with rounded tops and a gap between them;
/// tapping one reads its day and figure out above the chart, because a bar's
/// height alone is a comparison, not an answer.
class TrendBars extends StatefulWidget {
  const TrendBars({
    required this.points,
    required this.format,
    required this.dayLabel,
    this.height = 120,
    super.key,
  });

  final List<(DateTime?, num)> points;
  final String Function(num) format;
  final String Function(DateTime?) dayLabel;
  final double height;

  @override
  State<TrendBars> createState() => _TrendBarsState();
}

class _TrendBarsState extends State<TrendBars> {
  int? _picked;

  @override
  void didUpdateWidget(TrendBars old) {
    super.didUpdateWidget(old);
    if (old.points.length != widget.points.length) _picked = null;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final points = widget.points;
    if (points.isEmpty) return const SizedBox.shrink();

    num peak = 0;
    for (final p in points) {
      if (p.$2 > peak) peak = p.$2;
    }
    final shown = _picked ?? points.length - 1;
    final (day, value) = points[shown];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.dayLabel(day),
                style: text.bodySmall?.copyWith(color: palette.muted),
              ),
            ),
            Text(
              widget.format(value),
              style: text.titleSmall?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: Insets.s8),
        SizedBox(
          height: widget.height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final slot = constraints.maxWidth / points.length;
              final gap = slot > 6 ? 2.0 : 1.0;
              return Stack(
                children: [
                  // The baseline: recessive, so the bars carry the eye.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(height: 1, color: palette.hairline),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < points.length; i++)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(() => _picked = i),
                          child: SizedBox(
                            width: slot,
                            height: widget.height,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                margin: EdgeInsets.symmetric(horizontal: gap / 2),
                                height: peak <= 0
                                    ? 0
                                    : (points[i].$2 / peak * widget.height)
                                        .clamp(points[i].$2 > 0 ? 2.0 : 0.0,
                                            widget.height)
                                        .toDouble(),
                                decoration: BoxDecoration(
                                  color: i == shown
                                      ? palette.accent
                                      : palette.accent.withValues(alpha: 0.45),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// A report bucket as a person reads it: `Mon 14 Sep`. Formatted as a
/// calendar date — the bucket was never a moment, so nothing converts it.
String bucketLabel(DateTime? day, String locale) {
  if (day == null) return '';
  return DateFormat('EEE d MMM', locale == 'bn' ? 'bn_BD' : 'en_US').format(day);
}

/// The share of [part] in [whole], for [FigureRow.share].
double shareOf(num part, num whole) =>
    whole <= 0 ? 0 : (part / whole).toDouble();

/// Stock alert rows, shared by the stock report and the small dashboard.
List<Widget> stockLineRows(
  BuildContext context,
  List<StockLine> lines, {
  required String Function(StockLine) value,
  String? Function(StockLine)? detail,
  Color? tone,
}) =>
    [
      for (final line in lines)
        FigureRow(
          label: line.name,
          value: value(line),
          detail: detail?.call(line),
          tone: tone,
        ),
    ];

/// A quantity without a pointless `.0`.
String qtyText(num n) =>
    n == n.roundToDouble() ? n.toInt().toString() : n.toStringAsFixed(2);
