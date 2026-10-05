import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/shell_nav.dart';
import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/permissions/permissions.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/fields.dart';
import '../../../core/widgets/states.dart';
import '../../../l10n/app_localizations.dart';
import '../data/team_models.dart';
import '../data/team_repository.dart';
import 'team_sheets.dart';

/// Team and store settings: who works here, the branches, the shop's own
/// details and loyalty, and who changed what.
///
/// One call (`GET /settings`) fills the first three tabs; every write is
/// `permission && meta.may*`, so an auditor gets the same screen read-only and
/// a manager gets it without the role picker.
class TeamScreen extends ConsumerStatefulWidget {
  const TeamScreen({super.key});

  @override
  ConsumerState<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends ConsumerState<TeamScreen>
    with TickerProviderStateMixin {
  TabController? _tabs;

  void _ensureTabs(int length) {
    if (_tabs?.length == length) return;
    _tabs?.dispose();
    _tabs = TabController(length: length, vsync: this)
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final permissions = ref.watch(permissionsProvider);
    final overview = ref.watch(settingsOverviewProvider);
    final data = overview.value;

    // The activity tab is there by permission; the flag can still lock it.
    final showActivity = permissions.has(P.settingsActivityView);
    _ensureTabs(showActivity ? 4 : 3);
    final tabs = _tabs!;

    final mayUser = permissions.allows(
      P.settingsUserManage,
      alsoRequire: data?.mayManageUser,
    );
    final mayBranch = permissions.allows(
      P.settingsBranchManage,
      alsoRequire: data?.mayManageBranch,
    );

    final fab = data == null
        ? null
        : switch (tabs.index) {
            0 when mayUser => FloatingActionButton.extended(
              onPressed: () => MemberFormSheet.show(context, overview: data),
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: Text(l10n.addMember),
            ),
            1 when mayBranch => FloatingActionButton.extended(
              onPressed: () => BranchFormSheet.show(context),
              icon: const Icon(Icons.add_business_outlined),
              label: Text(l10n.addBranch),
            ),
            _ => null,
          };

    return Scaffold(
      appBar: ShellAppBar(
        title: Text(l10n.team),
        bottom: TabBar(
          controller: tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: l10n.teamMembers),
            Tab(text: l10n.branchesTab),
            Tab(text: l10n.storeTab),
            if (showActivity) Tab(text: l10n.activityTab),
          ],
        ),
      ),
      floatingActionButton: fab,
      body: TabBarView(
        controller: tabs,
        children: [
          _overviewTab((o) => _MembersTab(overview: o)),
          _overviewTab((o) => _BranchesTab(overview: o)),
          _overviewTab((o) => _StoreTab(overview: o)),
          if (showActivity)
            data?.maySeeActivity == false
                ? MessageState(
                    icon: Icons.lock_outline,
                    title: l10n.activityLocked,
                  )
                : const ActivityTab(),
        ],
      ),
    );
  }

  Widget _overviewTab(Widget Function(SettingsOverview) builder) =>
      AsyncView<SettingsOverview>(
        value: ref.watch(settingsOverviewProvider),
        onRetry: () => ref.invalidate(settingsOverviewProvider),
        builder: (context, data) => RefreshIndicator(
          onRefresh: () => ref.refresh(settingsOverviewProvider.future),
          child: builder(data),
        ),
      );
}

// ---------------------------------------------------------------------------
// Members

class _MembersTab extends ConsumerWidget {
  const _MembersTab({required this.overview});

  final SettingsOverview overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final active = overview.members.where((m) => m.isActive).toList();
    final suspended = overview.members.where((m) => !m.isActive).toList();

    if (overview.members.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: Insets.s32),
          MessageState(icon: Icons.group_outlined, title: l10n.membersEmpty),
        ],
      );
    }

    Widget group(List<TeamMember> members) => AppCard(
      children: [
        for (var i = 0; i < members.length; i++) ...[
          if (i > 0) Divider(height: 1, color: palette.hairline, indent: 72),
          _MemberRow(member: members[i], overview: overview),
        ],
      ],
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(Insets.gutter, 0, Insets.gutter, 96),
      children: [
        SectionHeader(l10n.activeMembers(active.length)),
        group(active),
        if (suspended.isNotEmpty) ...[
          SectionHeader(l10n.suspendedMembers(suspended.length)),
          group(suspended),
        ],
      ],
    );
  }
}

class _MemberRow extends ConsumerWidget {
  const _MemberRow({required this.member, required this.overview});

  final TeamMember member;
  final SettingsOverview overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final me = ref.watch(meProvider);
    final locale = me?.user.locale ?? 'en';
    final isSelf = me?.user.id == member.userId.value;
    final role = overview.roleOf(member);

    return ListTile(
      onTap: () =>
          MemberSheet.show(context, member: member, overview: overview),
      leading: CircleAvatar(
        backgroundColor: (member.isActive ? palette.accent : palette.muted)
            .withValues(alpha: 0.14),
        foregroundColor: member.isActive ? palette.accent : palette.muted,
        child: Text(initialsOf(member.name)),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              member.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: member.isActive ? null : TextStyle(color: palette.muted),
            ),
          ),
          if (isSelf) ...[
            const SizedBox(width: Insets.s8),
            StatusChip(label: l10n.youBadge, tone: palette.accent),
          ],
        ],
      ),
      subtitle: Text(
        [
          role?.labelFor(locale) ?? member.roleName ?? '',
          member.lastLoginAt == null
              ? l10n.neverSignedIn
              : l10n.lastSignedIn(
                  AppDates.relativeDay(
                    member.lastLoginAt,
                    today: l10n.today,
                    yesterday: l10n.yesterday,
                    locale: locale,
                  ),
                ),
        ].where((s) => s.isNotEmpty).join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: text.bodySmall?.copyWith(color: palette.muted),
      ),
      trailing: member.isActive
          ? const Icon(Icons.chevron_right)
          : StatusChip(label: l10n.suspendedBadge, tone: palette.danger),
    );
  }
}

String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  if (parts.isEmpty) return '?';
  final letters = parts.take(2).map((p) => p.characters.first.toUpperCase());
  return letters.join();
}

// ---------------------------------------------------------------------------
// Branches

class _BranchesTab extends ConsumerWidget {
  const _BranchesTab({required this.overview});

  final SettingsOverview overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final mayBranch = ref
        .watch(permissionsProvider)
        .allows(P.settingsBranchManage, alsoRequire: overview.mayManageBranch);
    final currentBranch = ref.watch(meProvider)?.branch?.id;

    return ListView(
      padding: const EdgeInsets.fromLTRB(Insets.gutter, 0, Insets.gutter, 96),
      children: [
        SectionHeader(l10n.branchesTab),
        AppCard(
          children: [
            for (var i = 0; i < overview.branches.length; i++) ...[
              if (i > 0) Divider(height: 1, color: palette.hairline),
              Builder(
                builder: (context) {
                  final b = overview.branches[i];
                  return ListTile(
                    onTap: mayBranch
                        ? () => BranchFormSheet.show(context, branch: b)
                        : null,
                    leading: const Icon(Icons.storefront_outlined),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            b.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: Insets.s8),
                        StatusChip(label: b.code, tone: palette.muted),
                        if (b.id == currentBranch) ...[
                          const SizedBox(width: Insets.s4),
                          StatusChip(
                            label: l10n.youAreHere,
                            tone: palette.accent,
                          ),
                        ],
                      ],
                    ),
                    subtitle: (b.phone ?? b.address) == null
                        ? null
                        : Text(
                            [?b.phone, ?b.address].join(' · '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodySmall?.copyWith(
                              color: palette.muted,
                            ),
                          ),
                    trailing: mayBranch
                        ? const Icon(Icons.edit_outlined, size: 20)
                        : null,
                  );
                },
              ),
            ],
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(Insets.s12),
          child: Text(
            l10n.branchesNote,
            style: text.bodySmall?.copyWith(color: palette.muted),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Store

class _StoreTab extends ConsumerWidget {
  const _StoreTab({required this.overview});

  final SettingsOverview overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final money = ref.watch(moneyProvider);
    final mayUpdate = ref
        .watch(permissionsProvider)
        .allows(P.settingsStoreUpdate, alsoRequire: overview.mayUpdateStore);
    final s = overview.store;
    final loyalty = overview.loyalty;
    String dash(String? v) => (v == null || v.isEmpty) ? '—' : v;

    return ListView(
      padding: const EdgeInsets.fromLTRB(Insets.gutter, 0, Insets.gutter, 96),
      children: [
        SectionHeader(
          l10n.storeDetails,
          trailing: mayUpdate
              ? TextButton.icon(
                  onPressed: () => StoreFormSheet.show(context, overview),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(l10n.edit),
                )
              : null,
        ),
        AppCard(
          children: [
            _Fact(label: l10n.shopName, value: s.name),
            _Fact(label: l10n.phone, value: dash(s.phone)),
            _Fact(label: l10n.email, value: dash(s.email)),
            _Fact(label: l10n.addressLabel, value: dash(s.address)),
            _Fact(label: l10n.cityLabel, value: dash(s.city)),
            if (s.currency != null)
              _Fact(label: l10n.currencyLabel, value: s.currency!),
          ],
        ),
        SectionHeader(l10n.atTheCounter),
        AppCard(
          children: [
            _Fact(
              label: l10n.vatLabel,
              value: s.vatMode == 'inclusive'
                  ? l10n.vatInclusive
                  : l10n.vatExclusive,
            ),
            _Fact(label: l10n.receiptPaper, value: s.receiptPaper),
            _Fact(label: l10n.invoicePrefix, value: dash(s.invoicePrefix)),
            _Fact(
              label: l10n.allowCreditSale,
              value: s.allowCreditSale ? l10n.allowed : l10n.notAllowed,
            ),
          ],
        ),
        SectionHeader(
          l10n.loyaltyTitle,
          trailing: mayUpdate
              ? TextButton.icon(
                  onPressed: () => LoyaltySheet.show(context, overview),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(l10n.edit),
                )
              : null,
        ),
        AppCard(
          children: [
            _Fact(
              label: l10n.loyaltyStatus,
              value: loyalty.enabled ? l10n.loyaltyOn : l10n.loyaltyOff,
            ),
            if (loyalty.enabled) ...[
              _Fact(
                label: l10n.loyaltyEarning,
                value: l10n.loyaltyEarnRule(
                  _plain(loyalty.earnPoints),
                  money.format(loyalty.earnPer),
                ),
              ),
              _Fact(
                label: l10n.loyaltyWorth,
                value: l10n.loyaltyPointValue(money.format(loyalty.valuePer)),
              ),
              _Fact(
                label: l10n.loyaltyMinRedeem,
                value: _plain(loyalty.minRedeem),
              ),
              _Fact(
                label: l10n.loyaltyMaxRedeemPct,
                value: '${_plain(loyalty.maxRedeemPct)}%',
              ),
            ],
          ],
        ),
      ],
    );
  }
}

String _plain(num v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.gutter,
        vertical: Insets.s12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: text.bodyMedium?.copyWith(color: context.palette.muted),
            ),
          ),
          const SizedBox(width: Insets.s12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: text.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Activity

class _ActivityQueryController extends Notifier<ActivityQuery> {
  @override
  ActivityQuery build() {
    ref.watch(sessionScopeProvider);
    return const ActivityQuery();
  }

  void set(ActivityQuery query) => state = query;
}

final _activityQueryProvider =
    NotifierProvider<_ActivityQueryController, ActivityQuery>(
      _ActivityQueryController.new,
    );

/// Who changed what — `GET /settings/activity`, the latest 200 rows.
class ActivityTab extends ConsumerStatefulWidget {
  const ActivityTab({super.key});

  @override
  ConsumerState<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends ConsumerState<ActivityTab> {
  final _search = TextEditingController();
  Timer? _debounce;

  static const _periods = [1, 7, 30, 90];

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _setQuery(ActivityQuery q) =>
      ref.read(_activityQueryProvider.notifier).set(q);

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final query = ref.watch(_activityQueryProvider);
    final log = ref.watch(activityLogProvider(query));
    final subjects = log.value?.subjects ?? const <String>[];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Insets.gutter,
            Insets.s12,
            Insets.gutter,
            Insets.s8,
          ),
          child: SearchField(
            controller: _search,
            hint: l10n.activitySearchHint,
            onChanged: (v) {
              _debounce?.cancel();
              _debounce = Timer(
                const Duration(milliseconds: 350),
                () => _setQuery(query.copyWith(q: v.trim())),
              );
            },
            onSubmitted: (v) => _setQuery(query.copyWith(q: v.trim())),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Insets.gutter),
          child: Row(
            children: [
              for (final d in _periods)
                Padding(
                  padding: const EdgeInsets.only(right: Insets.s8),
                  child: ChoiceChip(
                    selected: query.days == d,
                    onSelected: (_) => _setQuery(query.copyWith(days: d)),
                    label: Text(d == 1 ? l10n.today : l10n.lastDays(d)),
                  ),
                ),
              if (subjects.isNotEmpty || query.subject != null)
                _SubjectChip(
                  subjects: subjects,
                  selected: query.subject,
                  onSelected: (s) => _setQuery(
                    s == null
                        ? query.copyWith(clearSubject: true)
                        : query.copyWith(subject: s),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: Insets.s8),
        Expanded(
          child: AsyncView<ActivityLog>(
            value: log,
            onRetry: () => ref.invalidate(activityLogProvider(query)),
            builder: (context, data) {
              if (data.entries.isEmpty) {
                return MessageState(
                  icon: Icons.history,
                  title: l10n.activityEmpty,
                  body: l10n.activityEmptyBody,
                );
              }
              return RefreshIndicator(
                onRefresh: () => ref.refresh(activityLogProvider(query).future),
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: Insets.s32),
                  itemCount: data.entries.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: palette.hairline,
                    indent: Insets.gutter,
                  ),
                  itemBuilder: (context, i) =>
                      ActivityRow(entry: data.entries[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SubjectChip extends StatelessWidget {
  const _SubjectChip({
    required this.subjects,
    required this.selected,
    required this.onSelected,
  });

  final List<String> subjects;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return PopupMenuButton<String>(
      tooltip: l10n.activitySubject,
      onSelected: (v) => onSelected(v.isEmpty ? null : v),
      itemBuilder: (_) => [
        CheckedPopupMenuItem(
          value: '',
          checked: selected == null,
          child: Text(l10n.activityAllSubjects),
        ),
        for (final s in subjects)
          CheckedPopupMenuItem(
            value: s,
            checked: selected == s,
            child: Text(humanizeKey(s)),
          ),
      ],
      child: Chip(
        avatar: const Icon(Icons.filter_list, size: 18),
        label: Text(
          selected == null ? l10n.activityAllSubjects : humanizeKey(selected!),
        ),
      ),
    );
  }
}

/// `StoreProduct` → `Store product`, `opening_balance` → `Opening balance`.
String humanizeKey(String key) {
  final spaced = key
      .replaceAllMapped(RegExp(r'(?<=[a-z0-9])([A-Z])'), (m) => ' ${m[1]}')
      .replaceAll('_', ' ')
      .trim()
      .toLowerCase();
  if (spaced.isEmpty) return key;
  return spaced[0].toUpperCase() + spaced.substring(1);
}

class ActivityRow extends ConsumerWidget {
  const ActivityRow({required this.entry, super.key});

  final ActivityEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final locale = ref.watch(meProvider)?.user.locale ?? 'en';

    final (icon, tone) = switch (entry.event) {
      'created' => (Icons.add_circle_outline, palette.positive),
      'deleted' => (Icons.remove_circle_outline, palette.danger),
      'restored' => (Icons.restore, palette.accent),
      _ => (Icons.edit_outlined, palette.warning),
    };
    final what = [
      if (entry.subjectType != null) humanizeKey(entry.subjectType!),
      ?entry.subjectLabel,
    ].join(' · ');
    final title = Text(
      what.isEmpty ? humanizeKey(entry.event) : what,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
    final subtitle = Text(
      [
        humanizeKey(entry.event),
        entry.userName ?? l10n.activitySystem,
        AppDates.stamp(entry.createdAt, locale: locale),
      ].join(' · '),
      style: text.bodySmall?.copyWith(color: palette.muted),
    );
    final leading = Icon(icon, color: tone);

    if (entry.changes.isEmpty) {
      return ListTile(leading: leading, title: title, subtitle: subtitle);
    }
    return ExpansionTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      shape: const Border(),
      collapsedShape: const Border(),
      childrenPadding: const EdgeInsets.fromLTRB(72, 0, Insets.gutter, 12),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final c in entry.changes)
          Padding(
            padding: const EdgeInsets.only(bottom: Insets.s4),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${humanizeKey(c.field)}: ',
                    style: text.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: c.from ?? l10n.emptyValue,
                    style: text.bodySmall?.copyWith(
                      color: palette.muted,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  TextSpan(text: '  →  ', style: text.bodySmall),
                  TextSpan(
                    text: c.to ?? l10n.emptyValue,
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
