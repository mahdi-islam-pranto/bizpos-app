import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';

/// Shown while the stored token is read and `/me` answers. Usually a blink; on
/// a slow counter connection, a few seconds.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: palette.accentSoft,
                borderRadius: BorderRadius.circular(Radii.sheet),
              ),
              child: Icon(
                Icons.storefront_outlined,
                color: palette.accent,
                size: 28,
              ),
            ),
            const SizedBox(height: Insets.s16),
            Text(
              AppL10n.of(context).appName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: Insets.s24),
            SizedBox(
              height: 2,
              width: 80,
              child: LinearProgressIndicator(
                backgroundColor: palette.surfaceAlt,
                color: palette.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
