import 'package:bizpos_app/core/theme/app_theme.dart';
import 'package:bizpos_app/core/theme/theme_variant.dart';
import 'package:bizpos_app/features/products/data/product_models.dart';
import 'package:bizpos_app/features/products/ui/unit_field.dart';
import 'package:bizpos_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_session.dart';
import '../../support/role_fixtures.dart';

/// The Unit box offers every unit `GET /products/lookups` knows, and still
/// takes a word that is not on the list.
void main() {
  const units = [
    ProductUnit(short: 'pc', label: 'Piece', labelBn: 'পিস'),
    ProductUnit(short: 'box', label: 'Box', labelBn: 'বক্স'),
    ProductUnit(short: 'kg', label: 'Kilogram', labelBn: 'কেজি'),
  ];

  Future<TextEditingController> pump(WidgetTester tester) async {
    final controller = TextEditingController(text: 'pc');
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fakeSession(activeSession(Roles.stockKeeper, roleName: 'stock_keeper')),
        ],
        child: MaterialApp(
          theme: AppTheme.of(ThemeVariant.daylight, locale: 'en'),
          locale: const Locale('en'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: const [
            AppL10n.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: UnitField(controller: controller, label: 'Unit', units: units),
          ),
        ),
      ),
    );
    return controller;
  }

  testWidgets('tapping the box lists every unit', (tester) async {
    await pump(tester);
    await tester.tap(find.byType(UnitField));
    await tester.pumpAndSettle();

    expect(find.text('Choose a unit'), findsOneWidget);
    expect(find.text('Piece'), findsOneWidget);
    expect(find.text('Box'), findsOneWidget);
    expect(find.text('Kilogram'), findsOneWidget);
  });

  testWidgets('picking one writes its short form', (tester) async {
    final controller = await pump(tester);
    await tester.tap(find.byType(UnitField));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kilogram'));
    await tester.pumpAndSettle();

    expect(controller.text, 'kg');
  });

  testWidgets('a unit not on the list can still be used', (tester) async {
    final controller = await pump(tester);
    await tester.tap(find.byType(UnitField));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'strip');
    await tester.pumpAndSettle();

    expect(find.text('Piece'), findsNothing);
    await tester.tap(find.text('Use “strip” as a new unit'));
    await tester.pumpAndSettle();
    expect(controller.text, 'strip');
  });
}
