import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/dates.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/permissions/permissions.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/states.dart';
import '../../../l10n/app_localizations.dart';
import '../../team/ui/team_screen.dart' show humanizeKey;
import '../data/platform_models.dart';
import '../data/platform_repository.dart';
import 'platform_screen.dart' show StoreBadges, plainNumber;

// ---------------------------------------------------------------------------
// One shop

/// A shop's details and what platform staff may do with it.
class StoreAdminSheet extends ConsumerStatefulWidget {
  const StoreAdminSheet({
    required this.store,
    required this.overview,
    super.key,
  });

  final AdminStore store;
  final PlatformOverview overview;

  static Future<void> show(
    BuildContext context, {
    required AdminStore store,
    required PlatformOverview overview,
  }) => showAppSheet<void>(
    context,
    title: store.name,
    subtitle: store.slug,
    builder: (_) => StoreAdminSheet(store: store, overview: overview),
  );

  @override
  ConsumerState<StoreAdminSheet> createState() => _StoreAdminSheetState();
}

class _StoreAdminSheetState extends ConsumerState<StoreAdminSheet> {
  bool _busy = false;

  AdminStore get _store => widget.store;

  Future<void> _enter() async {
    final l10n = AppL10n.of(context);
    final ok = await confirmSheet(
      context,
      title: l10n.enterStoreTitle(_store.name),
      message: l10n.enterStoreBody,
      confirmLabel: l10n.enterStore,
      cancelLabel: l10n.cancel,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    final navigator = Navigator.of(context);
    try {
      await ref.read(sessionControllerProvider.notifier).impersonate(_store.id);
      // The router has already taken the shell to the new shop's home.
      if (navigator.mounted && navigator.canPop()) navigator.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showApiError(context, e);
    }
  }

  Future<void> _toggleStatus() async {
    final l10n = AppL10n.of(context);
    final suspending = !_store.isSuspended;
    final ok = await confirmSheet(
      context,
      title: suspending
          ? l10n.suspendStoreTitle(_store.name)
          : l10n.reactivateStoreTitle(_store.name),
      message: suspending ? l10n.suspendStoreBody : l10n.reactivateStoreBody,
      confirmLabel: suspending ? l10n.suspendStore : l10n.reactivateStore,
      cancelLabel: l10n.cancel,
      destructive: suspending,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(platformRepositoryProvider)
          .setStatus(_store.id, active: !suspending);
      ref.invalidate(platformOverviewProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      showNote(
        context,
        suspending
            ? l10n.storeSuspended(_store.name)
            : l10n.storeReactivated(_store.name),
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
    final here = me?.store?.id == _store.id;
    final s = _store;
    final o = widget.overview;
    final mayUpdate = permissions.has(P.adminStoreUpdate);

    Widget fact(String label, String? value) => value == null || value.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Insets.gutter,
              vertical: Insets.s8,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    label,
                    style: text.bodyMedium?.copyWith(color: palette.muted),
                  ),
                ),
                const SizedBox(width: Insets.s12),
                Expanded(flex: 3, child: Text(value, textAlign: TextAlign.end)),
              ],
            ),
          );

    final trial = !s.hasTrial
        ? l10n.noTimeLimit
        : '${AppDates.day(s.trialEndsAt, locale: locale)}'
              '${s.trialDaysLeft == null ? '' : ' · ${s.trialDaysLeft! <= 0 ? l10n.trialOver : l10n.daysLeft('${s.trialDaysLeft}')}'}';

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: Insets.s16),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Insets.gutter,
                Insets.s12,
                Insets.gutter,
                Insets.s4,
              ),
              child: StoreBadges(store: s),
            ),
            fact(
              l10n.storeTypeLabel,
              s.storeTypeName ?? o.storeTypeName(s.storeTypeId),
            ),
            fact(l10n.planLabel, s.planName ?? o.planName(s.planId)),
            fact(l10n.trialLabel, trial),
            fact(l10n.ownerLabel, [?s.ownerName, ?s.ownerEmail].join('\n')),
            fact(l10n.phone, s.phone),
            fact(l10n.email, s.email),
            fact(l10n.addressLabel, [?s.address, ?s.city].join(', ')),
            fact(l10n.currencyLabel, [?s.currency, ?s.timezone].join(' · ')),
            fact(l10n.createdLabel, AppDates.day(s.createdAt, locale: locale)),
            fact(
              l10n.databaseLabel,
              s.dbName == null
                  ? null
                  : '${s.dbName}\n${!s.dbReady
                        ? l10n.dbNotReady
                        : s.dbMigratedAt == null
                        ? l10n.dbNotMoved
                        : l10n.dbServing}',
            ),
            for (final c in s.counts.entries)
              fact(humanizeKey(c.key), plainNumber(c.value)),
            const SizedBox(height: Insets.s8),
            Divider(height: 1, color: palette.hairline),
            if (_busy)
              const Padding(
                padding: EdgeInsets.all(Insets.s24),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              if (permissions.has(P.adminStoreImpersonate))
                ListTile(
                  enabled: !here && !s.isSuspended,
                  leading: const Icon(Icons.support_agent),
                  title: Text(l10n.enterStore),
                  subtitle: here
                      ? Text(l10n.youAreInThisStore)
                      : s.isSuspended
                      ? Text(l10n.reactivateFirst)
                      : null,
                  onTap: _enter,
                ),
              if (mayUpdate) ...[
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: Text(l10n.editStoreDetails),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    // The sheet's own context goes with it; open the next
                    // one from the navigator's, which stays.
                    final navigator = Navigator.of(context);
                    navigator.pop();
                    await EditStoreSheet.show(
                      navigator.context,
                      store: s,
                      overview: o,
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.more_time),
                  title: Text(l10n.extendTrial),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final navigator = Navigator.of(context);
                    navigator.pop();
                    await ExtendTrialSheet.show(navigator.context, store: s);
                  },
                ),
                ListTile(
                  leading: Icon(
                    s.isSuspended
                        ? Icons.check_circle_outline
                        : Icons.block_outlined,
                    color: s.isSuspended ? palette.positive : palette.danger,
                  ),
                  title: Text(
                    s.isSuspended ? l10n.reactivateStore : l10n.suspendStore,
                    style: TextStyle(
                      color: s.isSuspended ? palette.positive : palette.danger,
                    ),
                  ),
                  onTap: _toggleStatus,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// A new shop

class NewStoreSheet extends ConsumerStatefulWidget {
  const NewStoreSheet({required this.overview, super.key});

  final PlatformOverview overview;

  static Future<void> show(
    BuildContext context, {
    required PlatformOverview overview,
  }) => showAppSheet<void>(
    context,
    title: AppL10n.of(context).newStore,
    builder: (_) => NewStoreSheet(overview: overview),
  );

  @override
  ConsumerState<NewStoreSheet> createState() => _NewStoreSheetState();
}

class _NewStoreSheetState extends ConsumerState<NewStoreSheet> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _ownerName = TextEditingController();
  final _ownerEmail = TextEditingController();
  final _ownerPassword = TextEditingController();
  final _address = TextEditingController();
  final _branch = TextEditingController();
  int? _storeTypeId;
  int? _planId;
  bool _obscure = true;
  bool _busy = false;
  Map<String, List<String>> _fieldErrors = const {};

  @override
  void initState() {
    super.initState();
    final types = widget.overview.storeTypes;
    if (types.length == 1) _storeTypeId = types.first.id;
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _phone,
      _ownerName,
      _ownerEmail,
      _ownerPassword,
      _address,
      _branch,
    ]) {
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
    final name = _name.text.trim();
    try {
      final created = await ref
          .read(platformRepositoryProvider)
          .createStore(
            NewStoreDraft(
              name: name,
              storeTypeId: _storeTypeId!,
              ownerName: _ownerName.text,
              ownerEmail: _ownerEmail.text,
              ownerPassword: _ownerPassword.text,
              phone: _phone.text,
              planId: _planId,
              address: _address.text,
              branchName: _branch.text,
            ),
          );
      ref.invalidate(platformOverviewProvider);
      if (!mounted) return;
      final navigator = Navigator.of(context);
      // The database is a step of its own: a shop can exist without one, and
      // staff need to know before the owner tries to sign in.
      if (!created.dbOk) {
        await showAppSheet<void>(
          context,
          title: l10n.storeCreated(name),
          builder: (sheet) => _DbProblem(created: created),
        );
      }
      if (!navigator.mounted) return;
      navigator.pop();
      if (created.dbOk && mounted) {
        showNote(
          context,
          created.reusedExistingAccount
              ? '${l10n.storeCreated(name)} ${l10n.ownerReusedAccount}'
              : l10n.storeCreated(name),
        );
      }
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
    final o = widget.overview;
    String? required(String? v, String field) =>
        (v ?? '').trim().isEmpty ? l10n.requiredField : _server(field);

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
                  decoration: InputDecoration(labelText: l10n.shopName),
                  validator: (v) => required(v, 'name'),
                ),
                const SizedBox(height: Insets.s12),
                DropdownButtonFormField<int>(
                  initialValue: _storeTypeId,
                  decoration: InputDecoration(labelText: l10n.storeTypeLabel),
                  items: [
                    for (final t in o.storeTypes)
                      DropdownMenuItem(value: t.id, child: Text(t.name)),
                  ],
                  onChanged: (v) => setState(() => _storeTypeId = v),
                  validator: (v) =>
                      v == null ? l10n.requiredField : _server('storeTypeId'),
                ),
                if (o.plans.isNotEmpty) ...[
                  const SizedBox(height: Insets.s12),
                  DropdownButtonFormField<int?>(
                    initialValue: _planId,
                    decoration: InputDecoration(labelText: l10n.planLabel),
                    items: [
                      DropdownMenuItem(value: null, child: Text(l10n.noPlan)),
                      for (final p in o.plans)
                        DropdownMenuItem(value: p.id, child: Text(p.name)),
                    ],
                    onChanged: (v) => setState(() => _planId = v),
                    validator: (_) => _server('planId'),
                  ),
                ],
                const SizedBox(height: Insets.s12),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: l10n.phone,
                    helperText: l10n.shopPhoneHelp,
                  ),
                  validator: (v) => required(v, 'phone'),
                ),
                SectionHeader(l10n.ownerLabel),
                TextFormField(
                  controller: _ownerName,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(labelText: l10n.fullName),
                  validator: (v) => required(v, 'ownerName'),
                ),
                const SizedBox(height: Insets.s12),
                TextFormField(
                  controller: _ownerEmail,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: InputDecoration(labelText: l10n.email),
                  validator: (v) {
                    final s = (v ?? '').trim();
                    if (s.isEmpty) return l10n.requiredField;
                    if (!s.contains('@')) return l10n.invalidEmail;
                    return _server('ownerEmail');
                  },
                ),
                const SizedBox(height: Insets.s12),
                TextFormField(
                  controller: _ownerPassword,
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
                      : _server('ownerPassword'),
                ),
                SectionHeader(l10n.optionalDetails),
                TextFormField(
                  controller: _address,
                  maxLines: 2,
                  decoration: InputDecoration(labelText: l10n.addressLabel),
                  validator: (_) => _server('address'),
                ),
                const SizedBox(height: Insets.s12),
                TextFormField(
                  controller: _branch,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n.branchNameOptional,
                  ),
                  validator: (_) => _server('branchName'),
                ),
              ],
            ),
          ),
          SheetAction(
            label: l10n.createStore,
            icon: Icons.add_business_outlined,
            busy: _busy,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

class _DbProblem extends StatelessWidget {
  const _DbProblem({required this.created});

  final StoreCreated created;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(Insets.gutter),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.storage, color: palette.danger),
              const SizedBox(width: Insets.s8),
              Expanded(
                child: Text(l10n.dbProblemTitle, style: text.titleSmall),
              ),
            ],
          ),
          const SizedBox(height: Insets.s12),
          Text(
            [
              if (created.dbName != null) created.dbName!,
              l10n.dbSteps(
                created.dbCreated ? l10n.yes : l10n.no,
                created.dbMigrated ? l10n.yes : l10n.no,
              ),
              ?created.dbProblem,
              ?created.dbDetail,
            ].join('\n\n'),
            style: text.bodySmall,
          ),
          const SizedBox(height: Insets.s12),
          Text(
            l10n.dbProblemNote,
            style: text.bodySmall?.copyWith(color: palette.muted),
          ),
          const SizedBox(height: Insets.s16),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Correcting a shop

/// `PATCH /admin/stores/{id}` with only what changed. The slug, the database
/// and the trial are not here: the first two identify the shop for good, and
/// the trial has its own action.
class EditStoreSheet extends ConsumerStatefulWidget {
  const EditStoreSheet({
    required this.store,
    required this.overview,
    super.key,
  });

  final AdminStore store;
  final PlatformOverview overview;

  static Future<void> show(
    BuildContext context, {
    required AdminStore store,
    required PlatformOverview overview,
  }) => showAppSheet<void>(
    context,
    title: AppL10n.of(context).editStoreDetails,
    subtitle: store.name,
    builder: (_) => EditStoreSheet(store: store, overview: overview),
  );

  @override
  ConsumerState<EditStoreSheet> createState() => _EditStoreSheetState();
}

class _EditStoreSheetState extends ConsumerState<EditStoreSheet> {
  final _form = GlobalKey<FormState>();
  late final AdminStore _s = widget.store;
  late final _name = TextEditingController(text: _s.name);
  late final _phone = TextEditingController(text: _s.phone);
  late final _email = TextEditingController(text: _s.email);
  late final _address = TextEditingController(text: _s.address);
  late final _city = TextEditingController(text: _s.city);
  late final _currency = TextEditingController(text: _s.currency);
  late final _timezone = TextEditingController(text: _s.timezone);
  late int? _storeTypeId = _s.storeTypeId;
  late int? _planId = _s.planId;
  bool _busy = false;
  Map<String, List<String>> _fieldErrors = const {};

  @override
  void dispose() {
    for (final c in [
      _name,
      _phone,
      _email,
      _address,
      _city,
      _currency,
      _timezone,
    ]) {
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

    final l10n = AppL10n.of(context);
    final edit = StoreEdit.diff(
      _s,
      StoreEdit(
        name: _name.text,
        storeTypeId: _storeTypeId,
        planId: _planId,
        phone: _phone.text,
        email: _email.text,
        address: _address.text,
        city: _city.text,
        currency: _currency.text.toUpperCase(),
        timezone: _timezone.text,
      ),
    );
    if (edit.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _busy = true);
    try {
      final updated = await ref
          .read(platformRepositoryProvider)
          .updateStore(_s.id, edit);
      ref.invalidate(platformOverviewProvider);
      // Editing the shop this device is in changes `/me` too.
      if (ref.read(meProvider)?.store?.id == _s.id) {
        await ref.read(sessionControllerProvider.notifier).refreshMe();
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      showNote(
        context,
        updated.storeTypeChanged ? l10n.storeTypeChangedNote : l10n.storeSaved,
      );
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
    final o = widget.overview;
    final typeChanged =
        _s.storeTypeId != null && _storeTypeId != _s.storeTypeId;

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
                DropdownButtonFormField<int>(
                  initialValue: o.storeTypes.any((t) => t.id == _storeTypeId)
                      ? _storeTypeId
                      : null,
                  decoration: InputDecoration(labelText: l10n.storeTypeLabel),
                  items: [
                    for (final t in o.storeTypes)
                      DropdownMenuItem(value: t.id, child: Text(t.name)),
                  ],
                  onChanged: (v) => setState(() => _storeTypeId = v),
                  validator: (_) => _server('storeTypeId'),
                ),
                if (typeChanged) ...[
                  const SizedBox(height: Insets.s8),
                  Text(
                    l10n.storeTypeChangeWarning,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: palette.warning),
                  ),
                ],
                if (o.plans.isNotEmpty) ...[
                  const SizedBox(height: Insets.s12),
                  DropdownButtonFormField<int?>(
                    initialValue: o.plans.any((p) => p.id == _planId)
                        ? _planId
                        : null,
                    decoration: InputDecoration(labelText: l10n.planLabel),
                    items: [
                      // A plan can be set, not cleared: nothing is sent for
                      // "no plan" on a shop that already has one.
                      if (_s.planId == null)
                        DropdownMenuItem(value: null, child: Text(l10n.noPlan)),
                      for (final p in o.plans)
                        DropdownMenuItem(value: p.id, child: Text(p.name)),
                    ],
                    onChanged: (v) => setState(() => _planId = v),
                    validator: (_) => _server('planId'),
                  ),
                ],
                const SizedBox(height: Insets.s12),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(labelText: l10n.phone),
                  // Every door a shop comes in by demands one, so it cannot be
                  // cleared here either.
                  validator: (v) => (v ?? '').trim().isEmpty
                      ? l10n.requiredField
                      : _server('phone'),
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
                const SizedBox(height: Insets.s12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _currency,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [LengthLimitingTextInputFormatter(3)],
                        decoration: InputDecoration(
                          labelText: l10n.currencyLabel,
                        ),
                        validator: (_) => _server('currency'),
                      ),
                    ),
                    const SizedBox(width: Insets.s12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _timezone,
                        autocorrect: false,
                        decoration: InputDecoration(
                          labelText: l10n.timezoneLabel,
                          hintText: 'Asia/Dhaka',
                        ),
                        validator: (_) => _server('timezone'),
                      ),
                    ),
                  ],
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
// The trial clock

/// `POST /admin/stores/{id}/extend`: some days, or no limit. Switching the
/// shop back on goes with it unless unticked — "let them carry on" is one
/// decision.
class ExtendTrialSheet extends ConsumerStatefulWidget {
  const ExtendTrialSheet({required this.store, super.key});

  final AdminStore store;

  static Future<void> show(BuildContext context, {required AdminStore store}) =>
      showAppSheet<void>(
        context,
        title: AppL10n.of(context).extendTrial,
        subtitle: store.name,
        builder: (_) => ExtendTrialSheet(store: store),
      );

  @override
  ConsumerState<ExtendTrialSheet> createState() => _ExtendTrialSheetState();
}

class _ExtendTrialSheetState extends ConsumerState<ExtendTrialSheet> {
  static const _presets = [7, 14, 30, 90, 365];

  final _days = TextEditingController(text: '30');
  bool _unlimited = false;
  bool _activate = true;
  bool _busy = false;

  @override
  void dispose() {
    _days.dispose();
    super.dispose();
  }

  int? get _dayCount {
    final n = int.tryParse(_days.text.trim());
    return n == null || n < 1 || n > 3650 ? null : n;
  }

  Future<void> _save() async {
    if (_busy || (!_unlimited && _dayCount == null)) return;
    setState(() => _busy = true);
    final l10n = AppL10n.of(context);
    final locale = ref.read(meProvider)?.user.locale ?? 'en';
    try {
      final state = await ref
          .read(platformRepositoryProvider)
          .extend(
            widget.store.id,
            days: _unlimited ? null : _dayCount,
            unlimited: _unlimited,
            activate: _activate,
          );
      ref.invalidate(platformOverviewProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      showNote(
        context,
        state.trialEndsAt == null
            ? l10n.trialNowUnlimited(widget.store.name)
            : l10n.trialNowEnds(
                widget.store.name,
                AppDates.day(state.trialEndsAt, locale: locale),
              ),
      );
    } catch (e) {
      // `nothing_to_do`: already unlimited, say.
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
    final locale = ref.watch(meProvider)?.user.locale ?? 'en';
    final s = widget.store;
    final ended = s.trialDaysLeft != null && s.trialDaysLeft! <= 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(Insets.gutter),
            children: [
              Text(
                !s.hasTrial
                    ? l10n.noTimeLimit
                    : l10n.trialCurrentlyEnds(
                        AppDates.day(s.trialEndsAt, locale: locale),
                      ),
                style: text.bodyMedium,
              ),
              const SizedBox(height: Insets.s4),
              Text(
                ended ? l10n.extendFromToday : l10n.extendFromEnd,
                style: text.bodySmall?.copyWith(color: palette.muted),
              ),
              const SizedBox(height: Insets.s16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _unlimited,
                onChanged: (v) => setState(() => _unlimited = v),
                title: Text(l10n.extendUnlimited),
                subtitle: Text(
                  l10n.extendUnlimitedHelp,
                  style: text.bodySmall?.copyWith(color: palette.muted),
                ),
              ),
              if (!_unlimited) ...[
                const SizedBox(height: Insets.s8),
                Wrap(
                  spacing: Insets.s8,
                  runSpacing: Insets.s8,
                  children: [
                    for (final d in _presets)
                      ChoiceChip(
                        selected: _dayCount == d,
                        onSelected: (_) => setState(() => _days.text = '$d'),
                        label: Text(l10n.daysCount(d)),
                      ),
                  ],
                ),
                const SizedBox(height: Insets.s12),
                TextField(
                  controller: _days,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: l10n.extendDays,
                    errorText: _dayCount == null ? l10n.extendDaysRange : null,
                  ),
                ),
              ],
              const SizedBox(height: Insets.s8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _activate,
                onChanged: (v) => setState(() => _activate = v ?? true),
                title: Text(l10n.extendActivate),
              ),
            ],
          ),
        ),
        SheetAction(
          label: l10n.extendTrial,
          icon: Icons.more_time,
          busy: _busy,
          onPressed: _unlimited || _dayCount != null ? _save : null,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

/// A one-line reason. Null when dismissed; an empty string when sent blank.
Future<String?> askNote(BuildContext context, {required String title}) =>
    showAppSheet<String>(
      context,
      title: title,
      builder: (_) => const _NotePrompt(),
    );

class _NotePrompt extends StatefulWidget {
  const _NotePrompt();

  @override
  State<_NotePrompt> createState() => _NotePromptState();
}

class _NotePromptState extends State<_NotePrompt> {
  // Owned here, so it dies with the sheet rather than under it.
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Padding(
      padding: const EdgeInsets.all(Insets.gutter),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: l10n.reviewNoteOptional),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: Insets.s16),
          FilledButton(onPressed: _submit, child: Text(l10n.confirm)),
        ],
      ),
    );
  }
}
