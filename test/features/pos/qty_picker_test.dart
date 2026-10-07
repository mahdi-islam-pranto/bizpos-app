import 'package:bizpos_app/core/theme/app_theme.dart';
import 'package:bizpos_app/core/theme/theme_variant.dart';
import 'package:bizpos_app/features/pos/ui/cart_sheet.dart';
import 'package:bizpos_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<List<num?>> open(WidgetTester tester) async {
    final results = <num?>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.of(ThemeVariant.daylight),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: const [
          AppL10n.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => results.add(
                await QtyPickerSheet.show(context, current: 1, stock: 12),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return results;
  }

  testWidgets('a quick quantity is one tap', (tester) async {
    final results = await open(tester);
    await tester.tap(find.widgetWithText(OutlinedButton, '10'));
    await tester.pumpAndSettle();
    expect(results, [10]);
  });

  testWidgets('a quick quantity past the stock is not on offer', (tester) async {
    await open(tester);
    final twenty = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, '20'),
    );
    expect(twenty.onPressed, isNull);
  });

  testWidgets('any other quantity can be typed', (tester) async {
    final results = await open(tester);
    await tester.enterText(find.byType(TextField), '7.5');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(results, [7.5]);
  });

  testWidgets('an empty or zero figure changes nothing', (tester) async {
    final results = await open(tester);
    await tester.enterText(find.byType(TextField), '0');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(results, isEmpty);
    expect(find.byType(QtyPickerSheet), findsOneWidget);
  });
}
