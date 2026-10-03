import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/session/session_controller.dart';
import 'report_models.dart';

/// The four reports of section 6, "Reports". Each is its own call behind its
/// own permission, so each tab is its own provider: a 403 on one leaves the
/// others standing.
class ReportsRepository {
  ReportsRepository(this._client, this._cancel);

  final ApiClient _client;
  final CancelToken _cancel;

  Future<SalesReport> sales({int days = 30}) async {
    final response = await _client.get(
      ApiPaths.reportSales,
      parse: parseObject(SalesReport.fromJson),
      query: {'days': days},
      cancelToken: _cancel,
    );
    return response.data;
  }

  Future<ProfitReport> profit({int days = 30}) async {
    final response = await _client.get(
      ApiPaths.reportProfit,
      parse: parseObject(ProfitReport.fromJson),
      query: {'days': days},
      cancelToken: _cancel,
    );
    return response.data;
  }

  Future<StockReport> stock() async {
    final response = await _client.get(
      ApiPaths.reportStock,
      parse: parseObject(StockReport.fromJson),
      cancelToken: _cancel,
    );
    return response.data;
  }

  /// Up to 100, most owed first as the server sorts them.
  Future<List<DueRow>> dues() async {
    final response = await _client.get(
      ApiPaths.reportDues,
      parse: parseListOf(DueRow.fromJson),
      cancelToken: _cancel,
    );
    return response.data;
  }
}

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  ref.watch(sessionScopeProvider);
  return ReportsRepository(
    ref.watch(apiClientProvider),
    ref.watch(scopeCancelTokenProvider),
  );
});

/// Keyed on the window in days.
final salesReportProvider = FutureProvider.autoDispose.family<SalesReport, int>(
  (ref, days) {
    ref.watch(sessionScopeProvider);
    return ref.watch(reportsRepositoryProvider).sales(days: days);
  },
);

final profitReportProvider = FutureProvider.autoDispose
    .family<ProfitReport, int>((ref, days) {
      ref.watch(sessionScopeProvider);
      return ref.watch(reportsRepositoryProvider).profit(days: days);
    });

final stockReportProvider = FutureProvider.autoDispose<StockReport>((ref) {
  ref.watch(sessionScopeProvider);
  return ref.watch(reportsRepositoryProvider).stock();
});

final duesReportProvider = FutureProvider.autoDispose<List<DueRow>>((ref) {
  ref.watch(sessionScopeProvider);
  return ref.watch(reportsRepositoryProvider).dues();
});
