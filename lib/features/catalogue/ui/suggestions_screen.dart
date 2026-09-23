import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/fields.dart';
import '../../../core/widgets/states.dart';
import '../../../l10n/app_localizations.dart';
import '../../products/data/products_repository.dart';
import '../data/catalog_models.dart';
import '../data/catalog_repository.dart';

/// The owner's and manager's review queue, `catalog.suggestion.review`.
///
/// Approving puts the product on sale in this store now and sends it on to the
/// platform, which decides whether every shop of this kind gets it. Rejecting
/// asks for a reason, because the person who asked will want one.
class SuggestionsScreen extends ConsumerWidget {
  const SuggestionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final queue = ref.watch(suggestionQueueProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.suggestionsTitle),
        bottom: queue.value == null || queue.value!.pending == 0
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(28),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: Insets.s8),
                  child: Text(l10n.suggestionsPending(queue.value!.pending)),
                ),
              ),
      ),
      body: AsyncView<SuggestionQueue>(
        value: queue,
        onRetry: () => ref.invalidate(suggestionQueueProvider),
        builder: (context, data) {
          if (data.suggestions.isEmpty) {
            return EmptyState(
              icon: Icons.rule_outlined,
              title: l10n.suggestionsEmpty,
              body: l10n.suggestionsEmptyBody,
            );
          }
          final ordered = [
            ...data.suggestions.where((s) => s.isPending),
            ...data.suggestions.where((s) => !s.isPending),
          ];
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(suggestionQueueProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(Insets.gutter),
              itemCount: ordered.length,
              separatorBuilder: (_, _) => const SizedBox(height: Insets.s12),
              itemBuilder: (context, i) => _SuggestionCard(
                suggestion: ordered[i],
                mayReview: data.mayEndorse ?? true,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SuggestionCard extends ConsumerStatefulWidget {
  const _SuggestionCard({required this.suggestion, required this.mayReview});

  final Suggestion suggestion;
  final bool mayReview;

  @override
  ConsumerState<_SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends ConsumerState<_SuggestionCard> {
  bool _busy = false;

  Future<void> _review({required bool approve}) async {
    final l10n = AppL10n.of(context);
    final answer = await _ReviewSheet.show(context, approve: approve);
    if (answer == null || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(catalogRepositoryProvider).review(
            widget.suggestion.id,
            approve: approve,
            note: answer.note,
            openingStock: answer.openingStock,
          );
      ref.invalidate(suggestionQueueProvider);
      ref.invalidate(catalogListProvider);
      if (approve) {
        ref.invalidate(productsListProvider);
        ref.invalidate(productStatsProvider);
      }
      if (mounted) {
        showNote(
          context,
          approve ? l10n.suggestionApproved : l10n.suggestionRejected,
        );
      }
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final money = ref.watch(moneyProvider);
    final locale = ref.watch(meProvider)?.user.locale ?? 'en';
    final s = widget.suggestion;

    final (statusLabel, statusTone) = switch (s.status) {
      SuggestionStatus.pending => (l10n.statusPending, palette.warning),
      SuggestionStatus.endorsed => (l10n.statusEndorsed, palette.accent),
      SuggestionStatus.approved => (l10n.statusApproved, palette.positive),
      SuggestionStatus.rejected => (l10n.statusRejected, palette.danger),
    };

    return AppCard(
      padding: const EdgeInsets.all(Insets.s12),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(s.name, style: text.titleMedium)),
            StatusChip(label: statusLabel, tone: statusTone),
          ],
        ),
        if (s.brand != null || s.genericName != null)
          Text(
            [?s.brand, ?s.genericName].join(' · '),
            style: text.bodySmall?.copyWith(color: palette.muted),
          ),
        const SizedBox(height: Insets.s8),
        Wrap(
          spacing: Insets.s16,
          runSpacing: Insets.s4,
          children: [
            if (s.cost != null) Text('${l10n.costLabel} ${money.format(s.cost)}'),
            if (s.sale != null) Text('${l10n.saleLabel} ${money.format(s.sale)}'),
            if (s.mrp != null) Text('${l10n.mrpLabel} ${money.format(s.mrp)}'),
            if (s.margin != null)
              Text(
                '${l10n.marginLabel} ${s.margin!.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: s.margin! < 0 ? palette.danger : palette.positive,
                ),
              ),
          ],
        ),
        if (s.reason != null) ...[
          const SizedBox(height: Insets.s8),
          Text('“${s.reason}”', style: text.bodySmall),
        ],
        const SizedBox(height: Insets.s8),
        Text(
          [
            if (s.askedBy != null) l10n.askedBy(s.askedBy!),
            if (s.askedAt != null) AppDates.day(s.askedAt, locale: locale),
          ].join(' · '),
          style: text.labelSmall?.copyWith(color: palette.muted),
        ),
        if (s.reviewNote != null)
          Text(
            s.reviewNote!,
            style: text.labelSmall?.copyWith(color: palette.muted),
          ),
        if (s.isPending && widget.mayReview) ...[
          const SizedBox(height: Insets.s12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : () => _review(approve: false),
                  child: Text(l10n.reject),
                ),
              ),
              const SizedBox(width: Insets.s12),
              Expanded(
                child: FilledButton(
                  onPressed: _busy ? null : () => _review(approve: true),
                  child: Text(l10n.approveAndStock),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

typedef _ReviewAnswer = ({String? note, num? openingStock});

/// Approve with an opening stock, or reject with a reason.
class _ReviewSheet extends StatefulWidget {
  const _ReviewSheet({required this.approve});

  final bool approve;

  static Future<_ReviewAnswer?> show(
    BuildContext context, {
    required bool approve,
  }) =>
      showAppSheet<_ReviewAnswer>(
        context,
        title: approve
            ? AppL10n.of(context).approveAndStock
            : AppL10n.of(context).reject,
        builder: (_) => _ReviewSheet(approve: approve),
      );

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  final _note = TextEditingController();
  final _opening = TextEditingController(text: '1');

  @override
  void dispose() {
    _note.dispose();
    _opening.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final note = _note.text.trim();
    // A rejection without a reason leaves the person who asked guessing.
    final ready = widget.approve || note.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(Insets.gutter),
          child: Column(
            children: [
              if (widget.approve) ...[
                AmountField(
                  controller: _opening,
                  label: l10n.openingStockLabel,
                  helperText: l10n.adoptOpeningHelp,
                ),
                const SizedBox(height: Insets.s16),
              ],
              TextField(
                controller: _note,
                autofocus: !widget.approve,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: widget.approve
                      ? l10n.reviewNoteOptional
                      : l10n.rejectReason,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),
        SheetAction(
          label: widget.approve ? l10n.approveAndStock : l10n.reject,
          icon: widget.approve ? Icons.check : Icons.close,
          onPressed: ready
              ? () => Navigator.of(context).pop((
                    note: note.isEmpty ? null : note,
                    openingStock:
                        widget.approve ? AmountField.read(_opening) : null,
                  ))
              : null,
        ),
      ],
    );
  }
}
