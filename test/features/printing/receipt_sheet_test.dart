import 'package:bizpos_app/core/network/envelope.dart';
import 'package:bizpos_app/core/theme/app_theme.dart';
import 'package:bizpos_app/core/theme/theme_variant.dart';
import 'package:bizpos_app/features/printing/printer_service.dart';
import 'package:bizpos_app/features/printing/receipt_sheet.dart';
import 'package:bizpos_app/features/sales/data/sale_models.dart';
import 'package:bizpos_app/features/sales/data/sales_repository.dart';
import 'package:bizpos_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_session.dart';
import '../../support/role_fixtures.dart';

class FakePrinter implements PrinterTransport {
  FakePrinter({this.state = BluetoothState.ready, this.fails = false});

  final BluetoothState state;
  final bool fails;
  final sent = <(String, List<int>)>[];

  @override
  Future<BluetoothState> check() async => state;

  @override
  Future<List<PairedPrinter>> paired() async => const [
    PairedPrinter(name: 'Counter printer', mac: 'AA:BB'),
  ];

  @override
  Future<void> send(String mac, List<int> bytes) async {
    if (fails) throw const PrintFailed();
    sent.add((mac, bytes));
  }
}

/// The slip that leaves the shop: every figure from `GET /sales/{id}`, and a
/// picture at the printer's own width — or the gallery, when no printer can
/// be reached.
void main() {
  final sale = SaleDetail.fromJson({
    'id': 7,
    'invoiceNo': 'INV-2026-001567',
    'subtotal': 1434,
    'discount': 0,
    'vat': 0,
    'total': 1434,
    'paid': 1434,
    'due': 0,
    'status': 'completed',
    'paymentStatus': 'paid',
    'mrpSaving': 1166,
    'saleDate': '2026-10-07T11:40:00+06:00',
    'seller': 'Abdur Rahman',
    'store': {'name': 'Shamim Pharmacy', 'phone': '01711000009', 'currency': 'BDT'},
    'branch': {'name': 'Shamim Pharmacy'},
    'items': [
      {
        'id': 1,
        'name': 'A Fenac SR 100 (100 pcs) 100mg',
        'qty': 4,
        'unitPrice': 288.5,
        'total': 1154,
        'mrp': 350,
        'mrpDiscount': 246,
        'mrpDiscountPercent': 17.57,
      },
      {'id': 2, 'name': 'A To Z GOL (Amee) (30 Pcs)', 'qty': 4, 'unitPrice': 70, 'total': 280},
    ],
    'payments': [
      {'method': 'cash', 'amount': 1434},
    ],
  });

  Future<void> pump(
    WidgetTester tester,
    FakePrinter printer, {
    Map<String, Object> prefs = const {
      'printer.name': 'Counter printer',
      'printer.mac': 'AA:BB',
      'printer.paper': '58mm',
    },
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fakeSession(activeSession(Roles.cashier, roleName: 'cashier')),
          saleDetailProvider(7).overrideWith(
            (ref) async => SaleDetailResult(sale: sale, meta: const Meta.empty()),
          ),
          printerTransportProvider.overrideWithValue(printer),
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
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => ReceiptSheet.show(context, saleId: 7),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> tapPrint(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Print'));
    // The capture and its pixels are real image work, which fake time never
    // finishes: let real time pass, then flush what it unblocked.
    for (var i = 0; i < 8; i++) {
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
    }
    await tester.pumpAndSettle();
  }

  testWidgets('reads like a till slip', (tester) async {
    await pump(tester, FakePrinter());

    expect(tester.takeException(), isNull);
    expect(find.text('Shamim Pharmacy'), findsOneWidget);
    expect(find.text('INV-2026-001567'), findsOneWidget);
    expect(find.text('Abdur Rahman'), findsOneWidget);
    expect(find.text('4 × 288.50'), findsOneWidget);
    expect(find.text('1154.00'), findsOneWidget);
    expect(find.text('MRP 350.00 · save 246.00 (17.57%)'), findsOneWidget);
    expect(find.text('TOTAL'), findsOneWidget);
    expect(find.text('YOU SAVED'), findsOneWidget);
    expect(find.text('CASH'), findsOneWidget);
    expect(find.text('Thank you, please come again'), findsOneWidget);
  });

  testWidgets('prints at the 58 mm head width on the chosen printer', (
    tester,
  ) async {
    final printer = FakePrinter();
    await pump(tester, printer);
    await tapPrint(tester);

    expect(printer.sent, hasLength(1));
    final (mac, bytes) = printer.sent.single;
    expect(mac, 'AA:BB');
    expect(bytes.sublist(0, 2), [0x1B, 0x40]);
    // GS v 0 with 48 bytes a row: 384 dots.
    expect(bytes.sublist(2, 8), [0x1D, 0x76, 0x30, 0x00, 48, 0]);
    expect(find.text('Printed on Counter printer'), findsOneWidget);
  });

  testWidgets('80 mm paper prints 576 dots wide', (tester) async {
    final printer = FakePrinter();
    await pump(
      tester,
      printer,
      prefs: const {
        'printer.name': 'Counter printer',
        'printer.mac': 'AA:BB',
        'printer.paper': '80mm',
      },
    );
    await tapPrint(tester);

    expect(printer.sent.single.$2.sublist(6, 8), [72, 0]);
  });

  testWidgets('a printer that does not answer falls back to the image', (
    tester,
  ) async {
    final printer = FakePrinter(fails: true);
    await pump(tester, printer);
    await tapPrint(tester);

    expect(printer.sent, isEmpty);
    // The gallery plugin is not there in a test, so the save itself reports
    // failure — what matters is that the receipt went that way.
    expect(find.text("Couldn't save the receipt image"), findsOneWidget);
  });

  testWidgets('Bluetooth off sends nothing to the printer', (tester) async {
    final printer = FakePrinter(state: BluetoothState.off);
    await pump(tester, printer);
    await tapPrint(tester);

    expect(printer.sent, isEmpty);
    expect(find.text("Couldn't save the receipt image"), findsOneWidget);
  });

  testWidgets('with no printer chosen, Print asks which one', (tester) async {
    final printer = FakePrinter();
    await pump(tester, printer, prefs: const {});

    expect(find.text('No printer chosen'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Print'));
    await tester.pumpAndSettle();

    expect(find.text('Choose a printer'), findsOneWidget);
    expect(find.text('Counter printer'), findsOneWidget);
    expect(find.text('Save as image'), findsOneWidget);
  });

  testWidgets('choosing a printer prints on it and remembers it', (
    tester,
  ) async {
    final printer = FakePrinter();
    await pump(tester, printer, prefs: const {});
    await tester.tap(find.widgetWithText(FilledButton, 'Print'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Counter printer'));
    for (var i = 0; i < 8; i++) {
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
    }
    await tester.pumpAndSettle();

    expect(printer.sent.single.$1, 'AA:BB');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('printer.mac'), 'AA:BB');
    expect(find.text('Counter printer · 58mm'), findsOneWidget);
  });
}
