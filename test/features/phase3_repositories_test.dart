import 'package:bizpos_app/core/network/api_client.dart';
import 'package:bizpos_app/features/accounts/data/account_models.dart';
import 'package:bizpos_app/features/accounts/data/accounts_repository.dart';
import 'package:bizpos_app/features/dashboard/data/dashboard_models.dart';
import 'package:bizpos_app/features/dashboard/data/dashboard_repository.dart';
import 'package:bizpos_app/features/reports/data/report_models.dart';
import 'package:bizpos_app/features/reports/data/reports_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_adapter.dart';

/// Phase 3 against `docs/MOBILE-API-NEW.md` sections 5.7, 5.8 and 6:
/// accounts and expenses, the four reports, and the dashboard.
void main() {
  late FakeAdapter adapter;
  late ApiClient client;

  setUp(() {
    adapter = FakeAdapter();
    client = ApiClient.create(
      baseUrl: 'https://example.test/api/v1',
      readToken: () => 'tok',
      onUnauthenticated: () async {},
    );
    client.dio.httpClientAdapter = adapter;
  });

  Map<String, dynamic> sentBody() =>
      adapter.lastRequest.data as Map<String, dynamic>;

  group('accounts', () {
    late AccountsRepository repo;
    setUp(() => repo = AccountsRepository(client, CancelToken()));

    test('GET /accounts reads balances, tiles, employees and the may flags',
        () async {
      adapter.body = {
        'data': {
          'accounts': [
            {'id': 1, 'name': 'Cash drawer', 'type': 'cash', 'balance': 15400, 'isDefault': true},
            {'id': 3, 'name': 'City Bank', 'type': 'bank', 'balance': 82000},
          ],
          'expenses': [
            {
              'id': 51,
              'amount': 12000,
              'categoryId': 9,
              'categoryName': 'Salary',
              'accountName': 'Cash drawer',
              'date': '2026-09-02',
              'isSalary': true,
              'employeeName': 'Karim Uddin',
              'salaryMonth': '2026-08',
            },
          ],
          'transactions': [
            {'id': 7, 'type': 'expense', 'amount': -12000, 'account': 'Cash drawer'},
          ],
          'categories': [
            {'id': 5, 'name': 'Tea', 'icon': '☕', 'defaultAmount': 50, 'isQuick': true},
            {'id': 9, 'name': 'Salary', 'isSalary': true, 'isQuick': true},
          ],
          // A tile row carries less than the category row it points at.
          'quick': [
            {'id': 5, 'name': 'Tea', 'defaultAmount': 50},
            {'id': 9, 'name': 'Salary'},
          ],
          'employees': ['Karim Uddin', 'Rahim'],
          'monthExpense': 18350,
          'todayExpense': 350,
          'monthSalary': 12000,
        },
        'meta': {'mayManage': true, 'mayExpense': true, 'mayDeleteExpense': false},
      };

      final o = await repo.overview();
      expect(o.accounts, hasLength(2));
      expect(o.totalBalance, 97400);
      expect(o.defaultAccount?.id, 1);
      expect(o.employees, ['Karim Uddin', 'Rahim']);
      expect(o.monthSalary, 12000);

      final salary = o.expenses.single;
      expect(salary.isSalary, isTrue);
      expect(salary.employeeName, 'Karim Uddin');
      expect(salary.salaryMonth, '2026-08');
      expect(o.transactions.single.isOut, isTrue);

      // The tiles take the full category row, so Salary knows it is Salary.
      final tea = o.quick.firstWhere((q) => q.id == 5);
      final pay = o.quick.firstWhere((q) => q.id == 9);
      expect(tea.oneTap, isTrue);
      expect(pay.isSalary, isTrue);
      expect(pay.oneTap, isFalse, reason: 'nobody\'s name is on a button');

      expect(o.mayManage, isTrue);
      expect(o.mayDeleteExpense, isFalse);
      // Tri-state: absent is not false.
      expect(o.mayTransfer, isNull);
    });

    test('a quick tile sends the type alone', () async {
      adapter.body = {
        'data': {'ok': true, 'id': 88, 'amount': 50, 'isSalary': false},
      };
      final created = await repo.quickExpense(5);

      expect(sentBody(), {'categoryId': 5});
      // The amount is the server's: the tile sent none.
      expect(created.amount, 50);
      expect(created.id, 88);
    });

    test('a salary sends a name and a month; another type sends neither',
        () async {
      adapter.body = {'data': {'ok': true, 'id': 1, 'amount': 12000, 'isSalary': true}};
      await repo.createExpense(
        ExpenseDraft(
          categoryId: 9,
          amount: 12000,
          isSalary: true,
          employeeName: ' Karim Uddin ',
          salaryMonth: DateTime(2026, 8),
        ),
      );
      expect(sentBody(), {
        'categoryId': 9,
        'amount': 12000,
        'employeeName': 'Karim Uddin',
        'salaryMonth': '2026-08',
      });

      await repo.createExpense(
        ExpenseDraft(
          categoryId: 5,
          amount: 350,
          accountId: 1,
          note: 'Tea',
          employeeName: 'Karim Uddin',
          salaryMonth: DateTime(2026, 8),
        ),
      );
      expect(sentBody(), {
        'categoryId': 5,
        'amount': 350,
        'accountId': 1,
        'note': 'Tea',
      });
    });

    test('a new type goes by name, and a backdated one carries its day',
        () async {
      adapter.body = {'data': {'ok': true, 'id': 2, 'amount': 1200}};
      await repo.createExpense(
        ExpenseDraft(
          categoryName: 'Van rent',
          amount: 1200,
          date: DateTime(2026, 9, 28),
        ),
      );
      expect(sentBody(), {
        'categoryName': 'Van rent',
        'amount': 1200,
        'date': '2026-09-28',
      });
    });

    test('editing a type sends every flag, as an overridden PATCH', () async {
      adapter.body = {'data': {'id': 5}};
      await repo.updateCategory(
        5,
        const CategoryDraft(name: 'Tea', icon: '☕', defaultAmount: 60),
      );

      final sent = adapter.lastRequest;
      expect(sent.method, 'POST');
      expect(sent.headers['X-HTTP-Method-Override'], 'PATCH');
      expect(sent.path, endsWith('/expense-categories/5'));
      // An omitted `isQuick` or `isSalary` reads as false on the server, so a
      // body without them would quietly take the tile off the screen.
      expect(sentBody(), containsPair('isQuick', false));
      expect(sentBody(), containsPair('isSalary', false));
      expect(sentBody(), containsPair('isActive', true));
      expect(sentBody()['defaultAmount'], 60);
    });

    test('deleting a used type reports it retired', () async {
      adapter.body = {
        'data': {'deleted': false, 'retired': true, 'usedCount': 14},
      };
      final result = await repo.deleteCategory(5);
      expect(adapter.lastRequest.headers['X-HTTP-Method-Override'], 'DELETE');
      expect(result.retired, isTrue);
      expect(result.usedCount, 14);
    });

    test('a transfer names both accounts', () async {
      adapter.body = {'data': {'ok': true}};
      await repo.transfer(fromAccountId: 1, toAccountId: 3, amount: 20000);
      expect(sentBody(), {'fromAccountId': 1, 'toAccountId': 3, 'amount': 20000});
    });
  });

  group('reports', () {
    late ReportsRepository repo;
    setUp(() => repo = ReportsRepository(client, CancelToken()));

    test('sales without profit permission keeps profit null, not zero',
        () async {
      adapter.body = {
        'data': {
          'daily': [
            {'date': '2026-09-29', 'total': 5200, 'count': 14},
            {'date': '2026-09-30', 'total': 6100.5, 'count': 17},
          ],
          'topProducts': [
            {'id': 44, 'name': 'Napa 500mg', 'qty': 120, 'revenue': 1440, 'profit': null},
          ],
          'byUser': [
            {'name': 'Karim', 'total': 11300.5, 'count': 31},
          ],
          'byMethod': [
            {'method': 'cash', 'total': 9000},
            {'method': 'bkash', 'total': 2300.5},
          ],
          'showProfit': false,
        },
      };
      final r = await repo.sales(days: 7);
      expect(adapter.lastRequest.queryParameters['days'], 7);
      expect(r.total, 11300.5);
      expect(r.count, 31);
      expect(r.showProfit, isFalse);
      expect(r.topProducts.single.profit, isNull);
      expect(r.byMethod.map((m) => m.label), ['cash', 'bkash']);
    });

    test('a report bucket is a calendar day, never shifted by the zone', () {
      final day = parseBucket('2026-09-30');
      expect(day, DateTime(2026, 9, 30));
      expect(day!.isUtc, isFalse);
      expect(parseBucket(null), isNull);
      expect(parseBucket('nope'), isNull);
    });

    test('dues read the age and the credit limit', () async {
      adapter.body = {
        'data': [
          {'id': 3, 'name': 'Rahim', 'phone': '01711', 'due': 5400, 'creditLimit': 5000, 'ageDays': 41},
          {'id': 4, 'name': 'Salma', 'due': 300, 'creditLimit': null},
        ],
      };
      final rows = await repo.dues();
      expect(rows.first.overLimit, isTrue);
      expect(rows.first.ageDays, 41);
      expect(rows.last.overLimit, isFalse);
    });

    test('profit and stock parse', () async {
      adapter.body = {
        'data': {
          'revenue': 100000,
          'cost': 70000,
          'returnTotal': 2000,
          'grossProfit': 28000,
          'expenses': 9000,
          'netProfit': 19000,
          'margin': 19,
        },
      };
      final p = await repo.profit(days: 30);
      expect(p.netProfit, 19000);
      expect(p.margin, 19);

      adapter.body = {
        'data': {
          'stockValue': 3462945.39,
          'totalUnits': 18000,
          'low': [
            {'id': 774, 'name': 'Folive 400mcg', 'quantity': 0, 'minimum': 10},
          ],
          'expiring': [],
          'dead': [
            {'id': 12, 'name': 'Old syrup', 'quantity': 6},
          ],
        },
      };
      final s = await repo.stock();
      expect(s.low.single.minimum, 10);
      expect(s.dead.single.qty, 6);
    });
  });

  group('dashboard', () {
    late DashboardRepository repo;
    setUp(() => repo = DashboardRepository(client, CancelToken()));

    test('a custom window sends plain dates', () async {
      adapter.body = {'data': <String, dynamic>{}};
      await repo.load(
        DashboardQuery(
          DashboardRange.custom,
          from: DateTime(2026, 9, 1),
          to: DateTime(2026, 9, 15),
        ),
      );
      expect(adapter.lastRequest.queryParameters, {
        'range': 'custom',
        'from': '2026-09-01',
        'to': '2026-09-15',
      });

      await repo.load(const DashboardQuery(DashboardRange.d7));
      expect(adapter.lastRequest.queryParameters, {'range': '7d'});
    });

    test('a section the caller may not see is null, and stays null', () async {
      adapter.body = {
        'data': {
          'range': {'from': '2026-09-24', 'to': '2026-09-30', 'capped': false},
          'headline': {
            'revenue': 45000,
            'invoices': 120,
            'averageSale': 375,
            'discountGiven': 800,
            'dueRaised': 2400,
            'returned': 300,
            'expenses': 5200,
            'grossProfit': null,
            'netProfit': null,
          },
          'capital': null,
          'daily': [
            {'date': '2026-09-29', 'sales': 5200, 'invoices': 14, 'expenses': 300},
          ],
          'payments': [
            {'method': 'cash', 'total': 40000},
          ],
          'collections': {
            'total': 43000,
            'onSales': 40000,
            'onDues': 2500,
            'onPreviousDue': 500,
            'byMethod': {'cash': 38000, 'bkash': 5000},
          },
          'movers': {
            'previous': {'from': '2026-09-17', 'to': '2026-09-23'},
            'rising': [
              {'name': 'Napa', 'qty': 120, 'wasQty': 80, 'revenue': 1440, 'wasRevenue': 960, 'changePercent': 50, 'verdict': 'rising'},
            ],
            'falling': [
              {'name': 'Ace', 'qty': 0, 'wasQty': 30, 'revenue': 0, 'wasRevenue': 300, 'changePercent': null, 'verdict': 'stopped'},
            ],
            'restock': null,
          },
          'dues': {
            'receivableTotal': 18000,
            'payableTotal': 42000,
            'customers': [
              {'id': 3, 'name': 'Rahim', 'due': 5400},
            ],
            'suppliers': [],
          },
          'expenses': {
            'total': 5200,
            'byCategory': [
              {'name': 'Tea', 'total': 700, 'count': 14},
            ],
            'rows': [],
          },
          'stock': null,
          'shifts': [
            {'id': 9, 'openingCash': 2000, 'expected': 15400, 'counted': 15300, 'difference': -100, 'closedAt': '2026-09-29T21:00:00+06:00'},
          ],
        },
        'meta': {'mayProfit': false, 'mayStock': false, 'mayDues': true},
      };

      final d = await repo.load(const DashboardQuery(DashboardRange.d7));
      expect(d.window.from, DateTime(2026, 9, 24));
      expect(d.headline!.revenue, 45000);
      // Profit is not zero for a manager, it is not theirs to see.
      expect(d.headline!.grossProfit, isNull);
      expect(d.headline!.netProfit, isNull);
      expect(d.capital, isNull);
      expect(d.stock, isNull);
      expect(d.movers!.restock, isNull);
      expect(d.movers!.falling.single.changePercent, isNull);
      expect(d.collections!.byMethod.map((m) => m.total), [38000, 5000]);
      expect(d.expenses!.byCategory.single.count, 14);
      expect(d.shifts!.single.difference, -100);
      // Never sent is not the same as null: an older server simply said
      // nothing about purchases.
      expect(d.purchases, isNull);
      expect(d.mayProfit, isFalse);
      expect(d.mayMoney, isNull);
    });
  });
}
