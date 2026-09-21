import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/router/app_router.dart';
import '../../core/network/api_exception.dart';
import '../../core/session/me.dart';
import '../../core/session/session_controller.dart';
import '../../core/session/session_state.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/theme/theme_variant.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/states.dart';
import '../../l10n/app_localizations.dart';

/// Who you are, where you are, and what you may do.
///
/// In Phase 0 this is also the app's proof: sign in as each seeded role and this
/// screen shows the store, the branch, the role and the exact permission list
/// the navigation was built from.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final session = ref.watch(sessionControllerProvider).value;
    final preferences = ref.watch(appPreferencesProvider).value;

    if (session is! SessionActive || preferences == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.profile)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final me = session.me;
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profile)),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: Insets.gutter),
        children: [
          const SizedBox(height: Insets.s8),
          _Identity(me: me, locale: preferences.localeCode),

          if (session.expiresSoon && session.expiresAt != null)
            Padding(
              padding: const EdgeInsets.only(top: Insets.s16),
              child: _Notice(
                icon: Icons.timer_outlined,
                tone: palette.warning,
                text: l10n.sessionExpiresSoon(
                  DateFormat.yMMMd(preferences.localeCode)
                      .format(session.expiresAt!),
                ),
              ),
            ),

          SectionHeader(l10n.store),
          AppCard(
            children: [
              ListTile(
                leading: const Icon(Icons.storefront_outlined),
                title: Text(me.store?.name ?? '—'),
                subtitle: Text(
                  [
                    me.store?.storeTypeName,
                    me.store?.currency,
                  ].whereType<String>().join(' · '),
                ),
                trailing: me.canSwitchStore
                    ? TextButton(
                        onPressed: () => _pickStore(context, ref, me),
                        child: Text(l10n.switchStore),
                      )
                    : null,
              ),
              Divider(height: 1, color: palette.hairline),
              ListTile(
                leading: const Icon(Icons.account_tree_outlined),
                title: Text(me.branch?.name ?? '—'),
                subtitle: Text(me.branch?.code ?? l10n.branch),
                trailing: me.canSwitchBranch
                    ? TextButton(
                        onPressed: () => _pickBranch(context, ref, me),
                        child: Text(l10n.switchBranch),
                      )
                    : null,
              ),
            ],
          ),

          SectionHeader(l10n.appearance),
          AppCard(
            children: [
              Padding(
                padding: const EdgeInsets.all(Insets.s12),
                child: SegmentedButton<ThemeVariant>(
                  segments: [
                    ButtonSegment(
                      value: ThemeVariant.daylight,
                      icon: const Icon(Icons.light_mode_outlined, size: 18),
                      label: Text(l10n.themeLight),
                    ),
                    ButtonSegment(
                      value: ThemeVariant.midnight,
                      icon: const Icon(Icons.dark_mode_outlined, size: 18),
                      label: Text(l10n.themeDark),
                    ),
                  ],
                  selected: {
                    // `workspace`, `paper` and `contrast` render as light for
                    // now; the stored preference keeps its real value.
                    preferences.variant.isDark
                        ? ThemeVariant.midnight
                        : ThemeVariant.daylight,
                  },
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) => ref
                      .read(appPreferencesProvider.notifier)
                      .setVariant(selection.first),
                ),
              ),
              Divider(height: 1, color: palette.hairline),
              Padding(
                padding: const EdgeInsets.all(Insets.s12),
                child: SegmentedButton<Locale>(
                  segments: [
                    ButtonSegment(
                      value: localeEn,
                      label: Text(l10n.languageEnglish),
                    ),
                    ButtonSegment(
                      value: localeBn,
                      label: Text(l10n.languageBangla),
                    ),
                  ],
                  selected: {preferences.locale},
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) => ref
                      .read(appPreferencesProvider.notifier)
                      .setLocale(selection.first),
                ),
              ),
            ],
          ),

          SectionHeader(l10n.permissionsHeading),
          AppCard(
            children: [
              ExpansionTile(
                shape: const Border(),
                collapsedShape: const Border(),
                leading: const Icon(Icons.key_outlined),
                title: Text(l10n.permissionCount(me.permissions.length)),
                subtitle: Text(
                  me.user.isSuperAdmin ? 'Super admin' : me.role?.name ?? '',
                  style: text.bodySmall,
                ),
                childrenPadding: const EdgeInsets.only(
                  left: Insets.s16,
                  right: Insets.s16,
                  bottom: Insets.s16,
                ),
                children: [
                  for (final permission in me.permissions.all.toList()..sort())
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Icon(Icons.check, size: 14, color: palette.positive),
                          const SizedBox(width: Insets.s8),
                          Expanded(
                            child: Text(permission, style: text.bodySmall),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),

          const SizedBox(height: Insets.s24),
          AppCard(
            children: [
              ListTile(
                leading: const Icon(Icons.devices_outlined),
                title: Text(l10n.devices),
                subtitle: Text(l10n.devicesBody),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.devices),
              ),
              Divider(height: 1, color: palette.hairline),
              ListTile(
                leading: Icon(Icons.logout, color: palette.danger),
                title: Text(
                  l10n.signOut,
                  style: text.bodyMedium?.copyWith(color: palette.danger),
                ),
                onTap: () =>
                    ref.read(sessionControllerProvider.notifier).signOut(),
              ),
            ],
          ),
          const SizedBox(height: Insets.s32),
        ],
      ),
    );
  }

  /// Switching store resets the branch and changes the permission set, so the
  /// whole app reloads behind this.
  Future<void> _pickStore(BuildContext context, WidgetRef ref, Me me) =>
      _pick<StoreRef>(
        context: context,
        title: AppL10n.of(context).switchStore,
        options: me.stores,
        isCurrent: (s) => s.id == me.store?.id,
        labelOf: (s) => s.name,
        onPick: (s) =>
            ref.read(sessionControllerProvider.notifier).switchStore(s.id),
      );

  Future<void> _pickBranch(BuildContext context, WidgetRef ref, Me me) =>
      _pick<MeBranch>(
        context: context,
        title: AppL10n.of(context).switchBranch,
        options: me.branches,
        isCurrent: (b) => b.id == me.branch?.id,
        labelOf: (b) => b.name,
        onPick: (b) =>
            ref.read(sessionControllerProvider.notifier).switchBranch(b.id),
      );

  Future<void> _pick<T>({
    required BuildContext context,
    required String title,
    required List<T> options,
    required bool Function(T) isCurrent,
    required String Function(T) labelOf,
    required Future<void> Function(T) onPick,
  }) async {
    final choice = await showModalBottomSheet<T>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(Insets.s16),
              child: Text(
                title,
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
            ),
            for (final option in options)
              ListTile(
                title: Text(labelOf(option)),
                trailing: isCurrent(option)
                    ? Icon(Icons.check, color: sheetContext.palette.accent)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(option),
              ),
          ],
        ),
      ),
    );

    if (choice == null || isCurrent(choice)) return;
    if (!context.mounted) return;

    try {
      await onPick(choice);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.me, required this.locale});

  final Me me;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final initial = me.user.name.isEmpty ? '?' : me.user.name.characters.first;

    return Row(
      children: [
        Container(
          height: 52,
          width: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.accentSoft,
            borderRadius: BorderRadius.circular(Radii.pill),
          ),
          child: Text(
            initial,
            style: text.titleLarge?.copyWith(color: palette.accent),
          ),
        ),
        const SizedBox(width: Insets.s16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(me.user.name, style: text.titleMedium),
              Text(me.user.email, style: text.bodySmall),
              const SizedBox(height: Insets.s4),
              // The server supplies both languages for the role label, so
              // nothing is translated here.
              if (me.role != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Insets.s8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surfaceAlt,
                    borderRadius: BorderRadius.circular(Radii.pill),
                    border: Border.all(color: palette.hairline),
                  ),
                  child: Text(
                    me.role!.labelFor(locale),
                    style: text.labelSmall,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.tone, required this.text});

  final IconData icon;
  final Color tone;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(Insets.s12),
        decoration: BoxDecoration(
          color: tone.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(Radii.row),
          border: Border.all(color: tone.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: tone),
            const SizedBox(width: Insets.s8),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      );
}
