import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/permissions/permissions.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/fields.dart';
import '../../../core/widgets/states.dart';
import '../../../l10n/app_localizations.dart';
import '../../pos/data/pos_repository.dart';
import '../data/team_models.dart';
import '../data/team_repository.dart';
import 'team_screen.dart' show humanizeKey, initialsOf;

/// Roles a store hands out. Platform staff is not one of them.
List<TeamRole> _assignable(List<TeamRole> roles) =>
    roles.where((r) => r.name != 'super_admin').toList();

// ---------------------------------------------------------------------------
// One member

/// A member's details and what may be done to them.
///
/// Nobody may suspend or re-role themselves (`422 self`), so on one's own row
/// the actions are replaced by a line saying so.
class MemberSheet extends ConsumerStatefulWidget {
  const MemberSheet({required this.member, required this.overview, super.key});

  final TeamMember member;
  final SettingsOverview overview;

  static Future<void> show(
    BuildContext context, {
    required TeamMember member,
    required SettingsOverview overview,
  }) => showAppSheet<void>(
    context,
    title: member.name,
    subtitle: member.email,
    builder: (_) => MemberSheet(member: member, overview: overview),
  );

  @override
  ConsumerState<MemberSheet> createState() => _MemberSheetState();
}

class _MemberSheetState extends ConsumerState<MemberSheet> {
  bool _busy = false;

  TeamMember get _member => widget.member;

  Future<void> _changeRole() async {
    final l10n = AppL10n.of(context);
    final current = widget.overview.roleOf(_member);
    final picked = await RolePickerSheet.show(
      context,
      roles: _assignable(widget.overview.roles),
      selectedId: current?.id,
    );
    if (picked == null || picked.id == current?.id || !mounted) return;

    setState(() => _busy = true);
    final locale = ref.read(meProvider)?.user.locale ?? 'en';
    try {
      // The user's own id — not the member row's storeUserId.
      await ref
          .read(teamRepositoryProvider)
          .changeRole(_member.userId, roleId: picked.id);
      ref.invalidate(settingsOverviewProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      showNote(
        context,
        l10n.roleChanged(_member.name, picked.labelFor(locale)),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showApiError(context, e);
      }
    }
  }

  Future<void> _toggleActive() async {
    final l10n = AppL10n.of(context);
    final suspending = _member.isActive;
    final ok = await confirmSheet(
      context,
      title: suspending
          ? l10n.suspendMemberTitle(_member.name)
          : l10n.reactivateMemberTitle(_member.name),
      message: suspending ? l10n.suspendMemberBody : l10n.reactivateMemberBody,
      confirmLabel: suspending ? l10n.suspendMember : l10n.reactivateMember,
      cancelLabel: l10n.cancel,
      destructive: suspending,
    );
    if (!ok || !mounted) return;

    setState(() => _busy = true);
    try {
      // The member row's storeUserId — not the user's own id.
      await ref
          .read(teamRepositoryProvider)
          .setMemberActive(_member.storeUserId, active: !suspending);
      ref.invalidate(settingsOverviewProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      showNote(
        context,
        suspending
            ? l10n.memberSuspended(_member.name)
            : l10n.memberReactivated(_member.name),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showApiError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final permissions = ref.watch(permissionsProvider);
    final me = ref.watch(meProvider);
    final locale = me?.user.locale ?? 'en';
    final o = widget.overview;
    final isSelf = me?.user.id == _member.userId.value;
    final role = o.roleOf(_member);

    final mayRole = permissions.allows(
      P.settingsRoleManage,
      alsoRequire: o.mayManageRole,
    );
    final mayUser = permissions.allows(
      P.settingsUserManage,
      alsoRequire: o.mayManageUser,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: Insets.s16),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: CircleAvatar(child: Text(initialsOf(_member.name))),
              title: Text(role?.labelFor(locale) ?? _member.roleName ?? ''),
              subtitle: Text(
                [
                  ?_member.phone,
                  _member.lastLoginAt == null
                      ? l10n.neverSignedIn
                      : l10n.lastSignedIn(
                          AppDates.stamp(_member.lastLoginAt, locale: locale),
                        ),
                ].join(' · '),
              ),
              trailing: StatusChip(
                label: _member.isActive
                    ? l10n.activeBadge
                    : l10n.suspendedBadge,
                tone: _member.isActive ? palette.positive : palette.danger,
              ),
            ),
            Divider(height: 1, color: palette.hairline),
            if (_busy)
              const Padding(
                padding: EdgeInsets.all(Insets.s24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (isSelf)
              Padding(
                padding: const EdgeInsets.all(Insets.gutter),
                child: Text(
                  l10n.cannotChangeSelf,
                  style: text.bodySmall?.copyWith(color: palette.muted),
                ),
              )
            else ...[
              if (mayRole && _member.isActive)
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: Text(l10n.changeRole),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _changeRole,
                ),
              if (mayRole && role != null)
                ListTile(
                  leading: const Icon(Icons.checklist_outlined),
                  title: Text(l10n.whatRoleCanDo(role.labelFor(locale))),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => RoleDetailSheet.show(context, role),
                ),
              if (mayUser)
                ListTile(
                  leading: Icon(
                    _member.isActive
                        ? Icons.block_outlined
                        : Icons.check_circle_outline,
                    color: _member.isActive ? palette.danger : palette.positive,
                  ),
                  title: Text(
                    _member.isActive
                        ? l10n.suspendMember
                        : l10n.reactivateMember,
                    style: TextStyle(
                      color: _member.isActive
                          ? palette.danger
                          : palette.positive,
                    ),
                  ),
                  onTap: _toggleActive,
                ),
              if (!mayRole && !mayUser)
                Padding(
                  padding: const EdgeInsets.all(Insets.gutter),
                  child: Text(
                    l10n.readOnlyTeam,
                    style: text.bodySmall?.copyWith(color: palette.muted),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Roles

/// Picks a role. Each row can open what that role may do, so an owner is not
/// choosing between names.
class RolePickerSheet extends ConsumerWidget {
  const RolePickerSheet({required this.roles, this.selectedId, super.key});

  final List<TeamRole> roles;
  final int? selectedId;

  static Future<TeamRole?> show(
    BuildContext context, {
    required List<TeamRole> roles,
    int? selectedId,
  }) => showAppSheet<TeamRole>(
    context,
    title: AppL10n.of(context).chooseRole,
    builder: (_) => RolePickerSheet(roles: roles, selectedId: selectedId),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final locale = ref.watch(meProvider)?.user.locale ?? 'en';
    final mayReadRoles = ref
        .watch(permissionsProvider)
        .has(P.settingsRoleManage);

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: Insets.s16),
      children: [
        for (final role in roles)
          ListTile(
            onTap: () => Navigator.of(context).pop(role),
            leading: Icon(
              role.id == selectedId
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: role.id == selectedId ? palette.accent : palette.muted,
            ),
            title: Text(role.labelFor(locale)),
            trailing: mayReadRoles
                ? IconButton(
                    tooltip: l10n.whatRoleCanDo(role.labelFor(locale)),
                    icon: const Icon(Icons.info_outline),
                    onPressed: () => RoleDetailSheet.show(context, role),
                  )
                : null,
          ),
      ],
    );
  }
}

/// `GET /settings/roles/{id}`, grouped the way the doc's matrix is.
class RoleDetailSheet extends ConsumerWidget {
  const RoleDetailSheet({required this.role, super.key});

  final TeamRole role;

  static Future<void> show(BuildContext context, TeamRole role) =>
      showAppSheet<void>(
        context,
        title: AppL10n.of(context).whatRoleCanDo(role.label),
        builder: (_) => RoleDetailSheet(role: role),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final detail = ref.watch(roleDetailProvider(role.id));

    return AsyncView<RoleDetail>(
      value: detail,
      onRetry: () => ref.invalidate(roleDetailProvider(role.id)),
      builder: (context, d) {
        final groups = d.byModule;
        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(Insets.gutter),
          children: [
            Text(
              l10n.permissionCount(d.permissions.length),
              style: text.bodySmall?.copyWith(color: palette.muted),
            ),
            if (d.isLocked) ...[
              const SizedBox(height: Insets.s4),
              Text(
                l10n.builtInRole,
                style: text.bodySmall?.copyWith(color: palette.muted),
              ),
            ],
            for (final entry in groups.entries) ...[
              SectionHeader(humanizeKey(entry.key)),
              Wrap(
                spacing: Insets.s8,
                runSpacing: Insets.s8,
                children: [
                  for (final p in entry.value)
                    StatusChip(
                      label: humanizeKey(
                        p.substring(p.indexOf('.') + 1).replaceAll('.', ' '),
                      ),
                      tone: palette.accent,
                    ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Add a member

class MemberFormSheet extends ConsumerStatefulWidget {
  const MemberFormSheet({required this.overview, super.key});

  final SettingsOverview overview;

  static Future<void> show(
    BuildContext context, {
    required SettingsOverview overview,
  }) => showAppSheet<void>(
    context,
    title: AppL10n.of(context).addMember,
    builder: (_) => MemberFormSheet(overview: overview),
  );

  @override
  ConsumerState<MemberFormSheet> createState() => _MemberFormSheetState();
}

class _MemberFormSheetState extends ConsumerState<MemberFormSheet> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late final List<TeamRole> _roles = _assignable(widget.overview.roles);
  int? _roleId;
  int? _branchId;
  bool _obscure = true;
  bool _busy = false;
  Map<String, List<String>> _fieldErrors = const {};

  @override
  void initState() {
    super.initState();
    // A new hand at the counter is the common case.
    final cashier = _roles.where((r) => r.name == 'cashier');
    _roleId = (cashier.isNotEmpty ? cashier.first : _roles.firstOrNull)?.id;
    _branchId = ref.read(meProvider)?.branch?.id;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _server(String field) {
    final messages = _fieldErrors[field];
    return (messages == null || messages.isEmpty) ? null : messages.first;
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _fieldErrors = const {});
    if (!_form.currentState!.validate()) return;

    setState(() => _busy = true);
    final l10n = AppL10n.of(context);
    final name = _name.text.trim();
    try {
      final added = await ref
          .read(teamRepositoryProvider)
          .addMember(
            MemberDraft(
              name: name,
              email: _email.text,
              password: _password.text,
              roleId: _roleId!,
              branchId: _branchId,
            ),
          );
      ref.invalidate(settingsOverviewProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      showNote(
        context,
        added.reusedExistingAccount
            ? l10n.memberReusedAccount(name)
            : l10n.memberAdded(name),
      );
    } on ValidationException catch (e) {
      if (mounted) {
        setState(() => _fieldErrors = e.fields);
        _form.currentState!.validate();
      }
    } catch (e) {
      // `plan_limit`, `duplicate`, `bad_role` — the message says which.
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final locale = ref.watch(meProvider)?.user.locale ?? 'en';
    final branches = widget.overview.branches;

    return Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(Insets.gutter),
              children: [
                TextFormField(
                  controller: _name,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: l10n.fullName),
                  validator: (v) => (v ?? '').trim().isEmpty
                      ? l10n.requiredField
                      : _server('name'),
                ),
                const SizedBox(height: Insets.s12),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: l10n.email),
                  validator: (v) {
                    final s = (v ?? '').trim();
                    if (s.isEmpty) return l10n.requiredField;
                    if (!s.contains('@') || !s.contains('.')) {
                      return l10n.invalidEmail;
                    }
                    return _server('email');
                  },
                ),
                const SizedBox(height: Insets.s12),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: l10n.password,
                    helperText: l10n.passwordRule,
                    suffixIcon: IconButton(
                      tooltip: _obscure ? l10n.showPassword : l10n.hidePassword,
                      icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v ?? '').length < 6
                      ? l10n.passwordRule
                      : _server('password'),
                ),
                const SizedBox(height: Insets.s12),
                DropdownButtonFormField<int>(
                  initialValue: _roleId,
                  decoration: InputDecoration(labelText: l10n.role),
                  items: [
                    for (final r in _roles)
                      DropdownMenuItem(
                        value: r.id,
                        child: Text(r.labelFor(locale)),
                      ),
                  ],
                  onChanged: (v) => setState(() => _roleId = v),
                  validator: (v) =>
                      v == null ? l10n.requiredField : _server('roleId'),
                ),
                if (branches.length > 1) ...[
                  const SizedBox(height: Insets.s12),
                  DropdownButtonFormField<int>(
                    initialValue: branches.any((b) => b.id == _branchId)
                        ? _branchId
                        : null,
                    decoration: InputDecoration(labelText: l10n.branch),
                    items: [
                      for (final b in branches)
                        DropdownMenuItem(value: b.id, child: Text(b.name)),
                    ],
                    onChanged: (v) => setState(() => _branchId = v),
                    validator: (_) => _server('branchId'),
                  ),
                ],
                const SizedBox(height: Insets.s12),
                Text(
                  l10n.memberFormNote,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: palette.muted),
                ),
              ],
            ),
          ),
          SheetAction(
            label: l10n.addMember,
            icon: Icons.person_add_alt_1_outlined,
            busy: _busy,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Branches

class BranchFormSheet extends ConsumerStatefulWidget {
  const BranchFormSheet({this.branch, super.key});

  /// Null to add one.
  final Branch? branch;

  static Future<void> show(BuildContext context, {Branch? branch}) =>
      showAppSheet<void>(
        context,
        title: branch == null
            ? AppL10n.of(context).addBranch
            : AppL10n.of(context).editBranch,
        builder: (_) => BranchFormSheet(branch: branch),
      );

  @override
  ConsumerState<BranchFormSheet> createState() => _BranchFormSheetState();
}

class _BranchFormSheetState extends ConsumerState<BranchFormSheet> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.branch?.name);
  late final _code = TextEditingController(text: widget.branch?.code);
  late final _phone = TextEditingController(text: widget.branch?.phone);
  late final _address = TextEditingController(text: widget.branch?.address);
  bool _busy = false;
  Map<String, List<String>> _fieldErrors = const {};

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  String? _server(String field) {
    final messages = _fieldErrors[field];
    return (messages == null || messages.isEmpty) ? null : messages.first;
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _fieldErrors = const {});
    if (!_form.currentState!.validate()) return;

    setState(() => _busy = true);
    final l10n = AppL10n.of(context);
    final draft = BranchDraft(
      name: _name.text,
      code: _code.text,
      phone: _phone.text,
      address: _address.text,
    );
    final repository = ref.read(teamRepositoryProvider);
    final session = ref.read(sessionControllerProvider.notifier);
    try {
      if (widget.branch == null) {
        await repository.createBranch(draft);
      } else {
        await repository.updateBranch(widget.branch!.id, draft);
      }
      ref.invalidate(settingsOverviewProvider);
      // The branch switcher on Profile reads `/me`.
      unawaited(session.refreshMe());
      if (!mounted) return;
      Navigator.of(context).pop();
      showNote(context, l10n.branchSaved);
    } on ValidationException catch (e) {
      if (mounted) {
        setState(() => _fieldErrors = e.fields);
        _form.currentState!.validate();
      }
    } catch (e) {
      // `plan_limit` is the usual one.
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(Insets.gutter),
              children: [
                TextFormField(
                  controller: _name,
                  autofocus: widget.branch == null,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(labelText: l10n.branchName),
                  validator: (v) => (v ?? '').trim().isEmpty
                      ? l10n.requiredField
                      : _server('name'),
                ),
                const SizedBox(height: Insets.s12),
                TextFormField(
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [LengthLimitingTextInputFormatter(20)],
                  decoration: InputDecoration(
                    labelText: l10n.branchCode,
                    helperText: l10n.branchCodeHelp,
                  ),
                  validator: (v) => (v ?? '').trim().isEmpty
                      ? l10n.requiredField
                      : _server('code'),
                ),
                const SizedBox(height: Insets.s12),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(labelText: l10n.phone),
                  validator: (_) => _server('phone'),
                ),
                const SizedBox(height: Insets.s12),
                TextFormField(
                  controller: _address,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                  decoration: InputDecoration(labelText: l10n.addressLabel),
                  validator: (_) => _server('address'),
                ),
              ],
            ),
          ),
          SheetAction(
            label: l10n.save,
            icon: Icons.check,
            busy: _busy,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Store details

/// The settings both the till and the receipt obey; `/me` carries the name,
/// and the POS lookups carry VAT and credit, so both are refreshed after.
void _afterStoreChange(WidgetRef ref) {
  ref.invalidate(settingsOverviewProvider);
  ref.invalidate(posLookupsProvider);
  unawaited(ref.read(sessionControllerProvider.notifier).refreshMe());
}

class StoreFormSheet extends ConsumerStatefulWidget {
  const StoreFormSheet({required this.overview, super.key});

  final SettingsOverview overview;

  static Future<void> show(BuildContext context, SettingsOverview overview) =>
      showAppSheet<void>(
        context,
        title: AppL10n.of(context).editStore,
        builder: (_) => StoreFormSheet(overview: overview),
      );

  @override
  ConsumerState<StoreFormSheet> createState() => _StoreFormSheetState();
}

class _StoreFormSheetState extends ConsumerState<StoreFormSheet> {
  final _form = GlobalKey<FormState>();
  late final StoreProfile _s = widget.overview.store;
  late final _name = TextEditingController(text: _s.name);
  late final _phone = TextEditingController(text: _s.phone);
  late final _email = TextEditingController(text: _s.email);
  late final _address = TextEditingController(text: _s.address);
  late final _city = TextEditingController(text: _s.city);
  late final _prefix = TextEditingController(text: _s.invoicePrefix);
  late String _vatMode = _s.vatMode;
  late String _paper = _s.receiptPaper;
  late bool _credit = _s.allowCreditSale;
  bool _busy = false;
  Map<String, List<String>> _fieldErrors = const {};

  static const _papers = ['58mm', '80mm', 'A4'];

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _address, _city, _prefix]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _server(String field) {
    final messages = _fieldErrors[field];
    return (messages == null || messages.isEmpty) ? null : messages.first;
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _fieldErrors = const {});
    if (!_form.currentState!.validate()) return;

    setState(() => _busy = true);
    final l10n = AppL10n.of(context);
    try {
      await ref
          .read(teamRepositoryProvider)
          .updateStore(
            StoreDraft(
              name: _name.text,
              phone: _phone.text,
              email: _email.text,
              address: _address.text,
              city: _city.text,
              vatMode: _vatMode,
              receiptPaper: _paper,
              invoicePrefix: _prefix.text,
              allowCreditSale: _credit,
            ),
          );
      _afterStoreChange(ref);
      if (!mounted) return;
      Navigator.of(context).pop();
      showNote(context, l10n.storeSaved);
    } on ValidationException catch (e) {
      if (mounted) {
        setState(() => _fieldErrors = e.fields);
        _form.currentState!.validate();
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

    return Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(Insets.gutter),
              children: [
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(labelText: l10n.shopName),
                  validator: (v) => (v ?? '').trim().isEmpty
                      ? l10n.requiredField
                      : _server('name'),
                ),
                const SizedBox(height: Insets.s12),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(labelText: l10n.phone),
                  validator: (_) => _server('phone'),
                ),
                const SizedBox(height: Insets.s12),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: InputDecoration(labelText: l10n.email),
                  validator: (_) => _server('email'),
                ),
                const SizedBox(height: Insets.s12),
                TextFormField(
                  controller: _address,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(labelText: l10n.addressLabel),
                  validator: (_) => _server('address'),
                ),
                const SizedBox(height: Insets.s12),
                TextFormField(
                  controller: _city,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(labelText: l10n.cityLabel),
                  validator: (_) => _server('city'),
                ),
                SectionHeader(l10n.atTheCounter),
                Text(l10n.vatLabel, style: text.labelLarge),
                const SizedBox(height: Insets.s8),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'exclusive',
                      label: Text(l10n.vatExclusive),
                    ),
                    ButtonSegment(
                      value: 'inclusive',
                      label: Text(l10n.vatInclusive),
                    ),
                  ],
                  selected: {_vatMode},
                  onSelectionChanged: (s) => setState(() => _vatMode = s.first),
                ),
                const SizedBox(height: Insets.s16),
                Text(l10n.receiptPaper, style: text.labelLarge),
                const SizedBox(height: Insets.s8),
                SegmentedButton<String>(
                  segments: [
                    for (final p in {..._papers, _paper})
                      ButtonSegment(value: p, label: Text(p)),
                  ],
                  selected: {_paper},
                  onSelectionChanged: (s) => setState(() => _paper = s.first),
                ),
                const SizedBox(height: Insets.s16),
                TextFormField(
                  controller: _prefix,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [LengthLimitingTextInputFormatter(10)],
                  decoration: InputDecoration(
                    labelText: l10n.invoicePrefix,
                    helperText: l10n.invoicePrefixHelp,
                  ),
                  validator: (_) => _server('invoicePrefix'),
                ),
                const SizedBox(height: Insets.s8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _credit,
                  onChanged: (v) => setState(() => _credit = v),
                  title: Text(l10n.allowCreditSale),
                  subtitle: Text(
                    l10n.allowCreditSaleHelp,
                    style: text.bodySmall?.copyWith(color: palette.muted),
                  ),
                ),
              ],
            ),
          ),
          SheetAction(
            label: l10n.save,
            icon: Icons.check,
            busy: _busy,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loyalty

class LoyaltySheet extends ConsumerStatefulWidget {
  const LoyaltySheet({required this.overview, super.key});

  final SettingsOverview overview;

  static Future<void> show(BuildContext context, SettingsOverview overview) =>
      showAppSheet<void>(
        context,
        title: AppL10n.of(context).loyaltyTitle,
        builder: (_) => LoyaltySheet(overview: overview),
      );

  @override
  ConsumerState<LoyaltySheet> createState() => _LoyaltySheetState();
}

class _LoyaltySheetState extends ConsumerState<LoyaltySheet> {
  late final LoyaltySettings _l = widget.overview.loyalty;
  late bool _enabled = _l.enabled;
  late final _earnPer = TextEditingController(text: _plain(_l.earnPer));
  late final _earnPoints = TextEditingController(text: _plain(_l.earnPoints));
  late final _valuePer = TextEditingController(text: _plain(_l.valuePer));
  late final _minRedeem = TextEditingController(text: _plain(_l.minRedeem));
  late final _maxPct = TextEditingController(text: _plain(_l.maxRedeemPct));
  late String _round = _l.round;
  bool _busy = false;
  bool _tried = false;

  static String _plain(num v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  @override
  void dispose() {
    for (final c in [_earnPer, _earnPoints, _valuePer, _minRedeem, _maxPct]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _valid {
    if (!_enabled) return true;
    final earnPer = AmountField.read(_earnPer) ?? 0;
    final earnPoints = AmountField.read(_earnPoints) ?? 0;
    final value = AmountField.read(_valuePer) ?? 0;
    final pct = AmountField.read(_maxPct) ?? 0;
    return earnPer > 0 && earnPoints > 0 && value > 0 && pct > 0 && pct <= 100;
  }

  Future<void> _save() async {
    setState(() => _tried = true);
    if (_busy || !_valid) return;
    setState(() => _busy = true);
    final l10n = AppL10n.of(context);
    try {
      await ref
          .read(teamRepositoryProvider)
          .updateStore(
            StoreDraft.loyaltyOnly(
              widget.overview.store.name,
              LoyaltySettings(
                enabled: _enabled,
                earnPer: AmountField.read(_earnPer) ?? _l.earnPer,
                earnPoints: AmountField.read(_earnPoints) ?? _l.earnPoints,
                valuePer: AmountField.read(_valuePer) ?? _l.valuePer,
                minRedeem: AmountField.read(_minRedeem) ?? 0,
                maxRedeemPct: AmountField.read(_maxPct) ?? _l.maxRedeemPct,
                round: _round,
              ),
            ),
          );
      _afterStoreChange(ref);
      if (!mounted) return;
      Navigator.of(context).pop();
      showNote(context, l10n.storeSaved);
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
    final money = ref.watch(moneyProvider);
    final pct = AmountField.read(_maxPct) ?? 0;

    String? positive(TextEditingController c) =>
        _tried && _enabled && (AmountField.read(c) ?? 0) <= 0
        ? l10n.mustBePositive
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(Insets.gutter),
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _enabled,
                onChanged: (v) => setState(() => _enabled = v),
                title: Text(l10n.loyaltyEnabled),
              ),
              if (_enabled) ...[
                const SizedBox(height: Insets.s8),
                Row(
                  children: [
                    Expanded(
                      child: AmountField(
                        controller: _earnPoints,
                        label: l10n.loyaltyEarnPoints,
                        errorText: positive(_earnPoints),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: Insets.s12),
                    Expanded(
                      child: AmountField(
                        controller: _earnPer,
                        label: l10n.loyaltyEarnPer,
                        prefix: '${money.sign} ',
                        errorText: positive(_earnPer),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Insets.s8),
                Text(
                  l10n.loyaltyEarnRule(
                    _earnPoints.text.isEmpty ? '–' : _earnPoints.text,
                    money.format(AmountField.read(_earnPer) ?? 0),
                  ),
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: palette.muted),
                ),
                const SizedBox(height: Insets.s16),
                AmountField(
                  controller: _valuePer,
                  label: l10n.loyaltyWorth,
                  prefix: '${money.sign} ',
                  errorText: positive(_valuePer),
                ),
                const SizedBox(height: Insets.s12),
                AmountField(
                  controller: _minRedeem,
                  label: l10n.loyaltyMinRedeem,
                ),
                const SizedBox(height: Insets.s12),
                AmountField(
                  controller: _maxPct,
                  label: l10n.loyaltyMaxRedeemPct,
                  prefix: '% ',
                  onChanged: (_) => setState(() {}),
                  errorText: _tried && (pct <= 0 || pct > 100)
                      ? l10n.percentRange
                      : null,
                ),
                const SizedBox(height: Insets.s16),
                Text(
                  l10n.loyaltyRound,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: Insets.s8),
                SegmentedButton<String>(
                  segments: [
                    for (final r in {'down', 'nearest', 'up', _round})
                      ButtonSegment(
                        value: r,
                        label: Text(switch (r) {
                          'down' => l10n.roundDown,
                          'nearest' => l10n.roundNearest,
                          'up' => l10n.roundUp,
                          _ => humanizeKey(r),
                        }),
                      ),
                  ],
                  selected: {_round},
                  onSelectionChanged: (s) => setState(() => _round = s.first),
                ),
              ],
            ],
          ),
        ),
        SheetAction(
          label: l10n.save,
          icon: Icons.check,
          busy: _busy,
          onPressed: _save,
        ),
      ],
    );
  }
}
