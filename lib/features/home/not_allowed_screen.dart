import 'package:flutter/material.dart';

import '../../core/widgets/states.dart';
import '../../l10n/app_localizations.dart';

/// Where a deep link into a screen the person's role does not include lands.
///
/// The server would refuse the screen's first call anyway; this just says so
/// before anything looks broken.
class NotAllowedScreen extends StatelessWidget {
  const NotAllowedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.notAllowedTitle)),
      body: MessageState(
        icon: Icons.lock_outline,
        title: l10n.notAllowedTitle,
        body: l10n.notAllowedBody,
      ),
    );
  }
}
