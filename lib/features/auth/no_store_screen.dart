import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session/session_controller.dart';
import '../../core/widgets/states.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../settings/open_store_sheet.dart';

/// Signed in, but the account belongs to no active store — or was suspended.
///
/// This is a screen rather than a message because every other call would answer
/// `400 bad_request`; there is genuinely nothing else to show.
class NoStoreScreen extends ConsumerWidget {
  const NoStoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final me = ref.watch(meProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(me?.user.name ?? l10n.appName),
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(sessionControllerProvider.notifier).signOut(),
            child: Text(l10n.signOut),
          ),
        ],
      ),
      body: MessageState(
        icon: Icons.storefront_outlined,
        title: l10n.noStoreTitle,
        body: l10n.noStoreBody,
        action: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: () =>
                  ref.read(sessionControllerProvider.notifier).refreshMe(),
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
            const SizedBox(height: Insets.s12),
            // With no shop to be in, opening one of your own is still open.
            FilledButton.icon(
              onPressed: () => OpenStoreSheet.show(context),
              icon: const Icon(Icons.add_business_outlined),
              label: Text(l10n.openAnotherShop),
            ),
          ],
        ),
      ),
    );
  }
}
