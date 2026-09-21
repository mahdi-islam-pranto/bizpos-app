import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/session/session_controller.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../core/theme/theme_variant.dart';
import '../l10n/app_localizations.dart';
import 'router/app_router.dart';

class BizposApp extends ConsumerStatefulWidget {
  const BizposApp({super.key});

  @override
  ConsumerState<BizposApp> createState() => _BizposAppState();
}

class _BizposAppState extends ConsumerState<BizposApp>
    with WidgetsBindingObserver {
  /// Long enough that a normal screen-lock does not trigger a refetch, short
  /// enough that a phone left on the counter over lunch comes back current.
  static const _staleAfter = Duration(minutes: 15);

  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _backgroundedAt = DateTime.now();
      return;
    }

    if (state == AppLifecycleState.resumed) {
      final since = _backgroundedAt;
      _backgroundedAt = null;
      if (since == null) return;
      if (DateTime.now().difference(since) < _staleAfter) return;

      // An owner may have changed this person's role while the app was away.
      ref.read(sessionControllerProvider.notifier).refreshMe(bumpEpoch: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final preferences = ref.watch(appPreferencesProvider).value;

    // Before preferences load (one frame, from SharedPreferences) fall back to
    // the default rather than flashing a different theme.
    final variant = preferences?.variant ?? ThemeVariant.daylight;
    final locale = preferences?.locale;

    return MaterialApp.router(
      title: 'bizPOS',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.of(variant, locale: locale?.languageCode ?? 'en'),
      // The account preference is explicit, so it wins over the OS setting.
      themeMode: variant.isDark ? ThemeMode.dark : ThemeMode.light,
      darkTheme: AppTheme.of(
        ThemeVariant.midnight,
        locale: locale?.languageCode ?? 'en',
      ),
      locale: locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: const [
        AppL10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
