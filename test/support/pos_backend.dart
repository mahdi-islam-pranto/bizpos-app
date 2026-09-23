import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// A stand-in bizPOS, answering with payloads captured from the real backend at
/// `biz.softwhile.com` with the seeded `cashier@rahman.test` account.
///
/// Recorded rather than invented: the awkward parts of the real thing — a
/// `salePrice` of `154.219999999999998863…`, a `null` `purchasePrice` for a
/// cashier, a `null` `shift` — are exactly what a hand-written fixture smooths
/// away and exactly what breaks the counter.
class PosBackend implements HttpClientAdapter {
  PosBackend({this.shift, this.held = const [], this.hideCost = false});

  Map<String, dynamic>? shift;
  List<Map<String, dynamic>> held;

  /// Answers as the API does for a role without
  /// `inventory.product.view_cost`: every cost comes back `null`, not zero.
  bool hideCost;

  /// Every request that reached the wire, as `METHOD path`.
  final List<String> hit = [];

  /// The query of the most recent request, for asserting on filters.
  Map<String, dynamic> lastQuery = const {};

  /// The decoded body of the last `POST /pos/checkout`.
  Map<String, dynamic>? checkoutBody;

  /// The decoded bodies of the last product write of each kind.
  Map<String, dynamic>? createBody;
  Map<String, dynamic>? patchBody;
  Map<String, dynamic>? adjustBody;
  Map<String, dynamic>? pricesBody;

  /// One row of `GET /products`, with the awkward salePrice the real backend
  /// serves and the `null` cost a role without `view_cost` would get.
  static const shelfItem = {
    'id': 1,
    'name': '3 F 500(20 Pcs) 500 mg',
    'barcode': null,
    'purchasePrice': 140,
    'salePrice': 154.22,
    'profitPercent': null,
    'profitRate': 10.16,
    'wholesalePrice': 146.51,
    'minimumStock': 10,
    'vatPercent': 0,
    'isActive': true,
    'unit': 'pc',
    'brand': 'edruc Ltd.',
    'category': null,
    'sku': null,
    'mrp': 320,
    'trackBatch': true,
    'deletedAt': null,
    'stock': 5,
    'addedBy': null,
    'changedBy': null,
  };

  static const deletedItem = {
    'id': 2,
    'name': 'Gone From The Shelf 10mg',
    'purchasePrice': 11,
    'salePrice': 16,
    'wholesalePrice': 15,
    'minimumStock': 6,
    'vatPercent': 0,
    'isActive': true,
    'unit': 'pc',
    'brand': 'TestCo Ltd',
    'mrp': 18,
    'trackBatch': false,
    'deletedAt': '2026-09-22T19:26:01+00:00',
    'stock': 17,
    'addedBy': 'Jamal Uddin',
    'changedBy': 'Jamal Uddin',
  };

  static const secondPageItem = {
    'id': 3,
    'name': 'Second Page Syrup 100ml',
    'purchasePrice': 50,
    'salePrice': 65,
    'wholesalePrice': 60,
    'minimumStock': 4,
    'vatPercent': 0,
    'isActive': true,
    'unit': 'bottle',
    'brand': 'Acme',
    'mrp': 80,
    'trackBatch': false,
    'deletedAt': null,
    'stock': 12,
  };

  static const stats = {
    'total': 1607,
    'active': 1607,
    'lowCount': 50,
    'low': [
      {'id': 774, 'name': 'Folive 400mcg', 'quantity': 0, 'minimum': 10},
    ],
    'expiringCount': 0,
    'expiring': <Map<String, dynamic>>[],
    'stockValue': 3462945.39,
    'canSeeCost': true,
  };

  static const history = {
    'movements': [
      {
        'id': 12542,
        'type': 'damage',
        'qtyIn': 0,
        'qtyOut': 3,
        'balanceAfter': 17,
        'movedAt': '2026-09-22T19:25:52+00:00',
        'note': 'Damaged in transit',
        'user': 'Jamal Uddin',
      },
      {
        'id': 12541,
        'type': 'opening',
        'qtyIn': 20,
        'qtyOut': 0,
        'balanceAfter': 20,
        'movedAt': '2026-09-22T19:25:41+00:00',
        'note': 'Opening stock on creation',
        'user': 'Jamal Uddin',
      },
    ],
    'prices': [
      {
        'id': 1612,
        'purchasePrice': 11,
        'salePrice': 16,
        'wholesalePrice': 15,
        'effectiveFrom': '2026-09-22T19:25:52+00:00',
        'effectiveTo': null,
      },
      {
        'id': 1611,
        'purchasePrice': 10,
        'salePrice': 15,
        'wholesalePrice': 15,
        'effectiveFrom': '2026-09-22T19:25:41+00:00',
        'effectiveTo': '2026-09-22T19:25:52+00:00',
      },
    ],
  };

  static const product = {
    'id': 1,
    'name': '3 F 500(20 Pcs) 500 mg',
    'barcode': '8941100500015',
    'unit': 'pc',
    'brand': 'edruc Ltd.',
    'salePrice': 154.22,
    'mrp': 320,
    'purchasePrice': null,
    'wholesalePrice': 146.51,
    'vatPercent': 0,
    'minimumStock': 10,
    'trackBatch': true,
    'stock': 6,
  };

  /// One row of `GET /sales`, with a due still on it.
  static const sale = {
    'id': 1778,
    'invoiceNo': 'INV-2026-001778',
    'saleDate': '2026-09-22T14:11:13+00:00',
    'total': 2366.32,
    'paid': 2008.96,
    'due': 357.36,
    'paymentStatus': 'partial',
    'status': 'completed',
    'customer': 'Sohel Alam',
    'seller': 'Nusrat Jahan',
    'branch': 'Mirpur (Main)',
    'itemCount': 4,
  };

  static const saleDetail = {
    'id': 1778,
    'invoiceNo': 'INV-2026-001778',
    'saleDate': '2026-09-22T14:11:13+00:00',
    'subtotal': 2366.32,
    'discount': 0,
    'lineDiscount': 0,
    'mrpSaving': 3133.68,
    'orderDiscount': 0,
    'vat': 0,
    'total': 2366.32,
    'paid': 2008.96,
    'due': 357.36,
    'status': 'completed',
    'paymentStatus': 'partial',
    'note': null,
    'customer': {'name': 'Sohel Alam', 'phone': '01811126705'},
    'seller': 'Nusrat Jahan',
    'branch': {'name': 'Mirpur (Main)', 'address': null, 'phone': null},
    'store': {
      'name': 'Rahman Pharmacy',
      'phone': null,
      'address': 'Mirpur 10, Dhaka',
      'currency': 'BDT',
    },
    'items': [
      {
        'id': 4355,
        'name': 'Cetzin 10 (100 pcs) 10mg',
        'unit': 'pc',
        'qty': 4,
        'unitPrice': 126.36,
        'mrp': 300,
        'discount': 0,
        'vat': 0,
        'total': 505.44,
      },
    ],
    'payments': [
      {
        'method': 'cash',
        'amount': 2008.96,
        'account': 'Cash Drawer',
        'reference': null,
      },
    ],
  };

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.uri.path;
    hit.add('${options.method} $path');
    lastQuery = Map<String, dynamic>.from(options.queryParameters);

    Object? body;
    var status = 200;

    if (path.endsWith('/pos/lookups')) {
      body = {'data': _lookups()};
    } else if (path.endsWith('/pos/search')) {
      body = {'data': [product]};
    } else if (path.endsWith('/packages/sellable')) {
      body = {
        'data': [
          {
            'id': 1,
            'name': 'Cold & Fever Pack',
            'barcode': null,
            'price': 1050,
            'vatPercent': 0,
            'isActive': true,
            'sellable': true,
            'buildable': 5,
          },
        ],
      };
    } else if (path.endsWith('/pos/checkout')) {
      checkoutBody = _bodyOf(options);
      status = 201;
      body = {
        'data': {
          'saleId': 5521,
          'invoiceNo': 'INV-2026-005521',
          'total': 154.22,
          'paid': 154.22,
          'due': 0,
          'paymentStatus': 'paid',
          'pointsEarned': 1,
          'pointsRedeemed': 0,
        },
      };
    } else if (path.endsWith('/pos/shift/open')) {
      shift = {'id': 31, 'openingCash': 2000, 'openedAt': null};
      status = 201;
      body = {'data': {'ok': true}};
    } else if (path.endsWith('/customers/search')) {
      body = {
        'data': [
          {
            'id': 4,
            'name': 'Hasan Mahmud',
            'phone': '01811111111',
            'isWalkIn': false,
            'creditLimit': 5000,
            'loyaltyPoints': 236,
            'due': 0,
          },
        ],
      };
    } else if (path.endsWith('/sales')) {
      body = {
        'data': [sale],
        'meta': {
          'total': 1,
          'page': 1,
          'perPage': 25,
          'summary': {'count': 1, 'total': 2366.32, 'due': 357.36},
          'seeAll': false,
          'mayReturn': false,
          'mayCollect': true,
        },
      };
    } else if (RegExp(r'/sales/\d+$').hasMatch(path)) {
      body = {'data': saleDetail, 'meta': {'mayVoid': false}};
    } else if (path.endsWith('/customers')) {
      body = {
        'data': [
          {
            'id': 4,
            'name': 'Hasan Mahmud',
            'phone': '01811111111',
            'email': null,
            'address': null,
            'creditLimit': 5000,
            'loyaltyPoints': 236,
            'isWalkIn': false,
            'group': null,
            'saleCount': 19,
            'due': 357.36,
            'addedBy': null,
            'changedBy': null,
          },
        ],
        'meta': {
          'mayEdit': false,
          'mayCreate': true,
          'maySeeLedger': false,
          'mayManageCredit': false,
        },
      };
    } else if (path.endsWith('/products/stats')) {
      body = {'data': stats};
    } else if (RegExp(r'/products/\d+/history$').hasMatch(path)) {
      body = {'data': history};
    } else if (RegExp(r'/products/\d+/adjust$').hasMatch(path)) {
      adjustBody = _bodyOf(options);
      status = 201;
      body = {'data': {'ok': true}};
    } else if (RegExp(r'/products/\d+/prices$').hasMatch(path)) {
      pricesBody = _bodyOf(options);
      body = {'data': {'ok': true, 'changed': true}};
    } else if (path.endsWith('/products/lookups')) {
      body = {
        'data': {
          'brands': ['Beximco', 'Square'],
          'units': [
            {'short': 'pc', 'label': 'Piece', 'labelBn': 'পিস'},
            {'short': 'box', 'label': 'Box', 'labelBn': 'বক্স'},
          ],
        },
      };
    } else if (RegExp(r'/products/\d+/restore$').hasMatch(path)) {
      body = {'data': {'ok': true, 'id': 1, 'name': shelfItem['name']}};
    } else if (RegExp(r'/products/\d+$').hasMatch(path)) {
      if (options.method == 'POST' &&
          options.headers['X-HTTP-Method-Override'] == 'DELETE') {
        body = {'data': {'ok': true, 'stockWritten': 5}};
      } else {
        patchBody = _bodyOf(options);
        body = {'data': {'id': 1, 'name': shelfItem['name']}};
      }
    } else if (path.endsWith('/products')) {
      if (options.method == 'POST') {
        createBody = _bodyOf(options);
        status = 201;
        body = {'data': {'id': 99, 'name': createBody!['name'], 'catalogueId': 7}};
      } else {
        final trashed = options.queryParameters['trashed'] != null;
        final page = int.tryParse('${options.queryParameters['page']}') ?? 1;
        // Two pages of one, so the "load more" path is exercised rather than
        // asserted away by a total that always fits on the first page.
        body = {
          'data': [
            for (final item in trashed
                ? [deletedItem]
                : page == 1
                    ? [shelfItem]
                    : [secondPageItem])
              _costed(item),
          ],
          'meta': {
            'total': trashed ? 1 : 2,
            'page': page,
            'perPage': 1,
            'showCost': !hideCost,
            'trashedCount': 1,
          },
        };
      }
    } else if (path.endsWith('/points')) {
      body = {'data': {'balance': 236, 'worth': 236, 'ledger': []}};
    } else {
      body = {'data': <String, dynamic>{}};
    }

    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  /// Dio keeps the original object on [RequestOptions.data]; only the stream
  /// carries the encoded bytes. Read both, so the double does not care which.
  static Map<String, dynamic> _bodyOf(RequestOptions options) {
    final data = options.data;
    if (data is Map<String, dynamic>) return data;
    if (data is String) return jsonDecode(data) as Map<String, dynamic>;
    return const {};
  }

  /// Strips the costs the way the API does for a weaker role.
  Map<String, dynamic> _costed(Map<String, dynamic> item) {
    if (!hideCost) return item;
    return {
      ...item,
      'purchasePrice': null,
      'wholesalePrice': null,
      // A markup is a cost by another name.
      'profitPercent': null,
      'profitRate': null,
    };
  }

  Map<String, dynamic> _lookups() => {
        'accounts': [
          {'id': 1, 'name': 'Cash Drawer', 'type': 'cash', 'isDefault': true},
          {'id': 2, 'name': 'bKash Merchant', 'type': 'mfs', 'isDefault': false},
        ],
        'customers': [
          {
            'id': 1,
            'name': 'Walk-in Customer',
            'phone': null,
            'isWalkIn': true,
            'creditLimit': 0,
          },
          {
            'id': 4,
            'name': 'Hasan Mahmud',
            'phone': '01811111111',
            'isWalkIn': false,
            'creditLimit': 5000,
          },
        ],
        'held': held,
        'shift': shift,
        'vatInclusive': false,
        'allowCredit': true,
        'loyalty': {
          'loyalty_enabled': true,
          'loyalty_earn_per': 100,
          'loyalty_earn_points': 1,
          'loyalty_value_per': 1,
          'loyalty_min_redeem': 50,
          'loyalty_max_redeem_pct': 50,
          'loyalty_round': 'down',
          'mayRedeem': true,
        },
      };

  @override
  void close({bool force = false}) {}
}
