import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/network/api_exception.dart';
import '../../core/session/me.dart';
import '../../core/session/session_controller.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/states.dart';
import '../../l10n/app_localizations.dart';

/// Every phone this account is signed in on.
///
/// One token is one device, so this is how a lost phone gets cut off — the
/// token stops working on the spot.
final devicesProvider = FutureProvider<List<DeviceSession>>((ref) {
  // Not scope-keyed on purpose: devices belong to the account, not to a store.
  return ref.watch(authApiProvider).devices();
});

class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final devices = ref.watch(devicesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.devices)),
      body: switch (devices) {
        AsyncValue(hasError: true, :final error?) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(devicesProvider),
          ),
        AsyncValue(:final value?) => value.isEmpty
            ? EmptyState(title: l10n.emptyTitle)
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(devicesProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(Insets.gutter),
                  itemCount: value.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: Insets.s12),
                  itemBuilder: (context, i) => _DeviceRow(
                    device: value[i],
                    onRevoke: () => _revoke(context, ref, value[i]),
                  ),
                ),
              ),
        _ => const LoadingList(rows: 3),
      },
    );
  }

  Future<void> _revoke(
    BuildContext context,
    WidgetRef ref,
    DeviceSession device,
  ) async {
    final l10n = AppL10n.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(l10n.revokeDeviceConfirm(device.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.revokeDevice),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      // A DELETE, so it travels as a POST with the override header.
      await ref.read(authApiProvider).revokeDevice(device.id);
      ref.invalidate(devicesProvider);

      // Signing this device out revokes the token in use, and the next call
      // would 401 anyway — so do it properly.
      if (device.isCurrent) {
        await ref.read(sessionControllerProvider.notifier).signOut();
      }
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({required this.device, required this.onRevoke});

  final DeviceSession device;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final locale = Localizations.localeOf(context).languageCode;

    final lastUsed = device.lastUsedAt;
    final subtitle = device.isCurrent
        ? l10n.thisDevice
        : lastUsed == null
            ? ''
            : l10n.lastUsed(DateFormat.yMMMd(locale).add_jm().format(lastUsed));

    return AppCard(
      children: [
        ListTile(
          leading: Icon(
            device.isCurrent
                ? Icons.phone_android_outlined
                : Icons.devices_other_outlined,
            color: device.isCurrent ? palette.accent : palette.muted,
          ),
          title: Text(device.name),
          subtitle: subtitle.isEmpty ? null : Text(subtitle),
          trailing: TextButton(
            onPressed: onRevoke,
            child: Text(
              l10n.revokeDevice,
              style: TextStyle(color: palette.danger),
            ),
          ),
        ),
      ],
    );
  }
}
