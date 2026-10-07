import 'package:flutter/material.dart';

/// The BizPOS mark: the till and receipt on the green square.
///
/// One widget so the sign-in screen, the splash and the sidebar can never
/// drift apart. The square carries its own green, so it reads the same on the
/// light and the dark theme.
class BrandLogo extends StatelessWidget {
  const BrandLogo({this.size = 72, super.key});

  static const asset = 'assets/brand/logo.png';

  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
    asset,
    width: size,
    height: size,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.medium,
    semanticLabel: 'BizPOS',
  );
}
