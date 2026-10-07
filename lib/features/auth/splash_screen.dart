import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/brand_logo.dart';

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
            // The mark already says BizPOS; no name under it.
            const BrandLogo(size: 96),
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
