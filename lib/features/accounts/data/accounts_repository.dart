import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/session/session_controller.dart';
import 'account_models.dart';

/// `docs/MOBILE-API-NEW.md` section 5.7 and section 6, "Accounts and
/// expenses".
///
/// The calls that move money — an expense, a transfer — deliberately do not
/// use the scope cancel token, for the same reason a checkout does not: once
/// it has left the phone, cancelling only stops the app from hearing whether
/// the money moved. None of them is ever retried.
class AccountsRepository {
  AccountsRepository(this._client, this._cancel);

  final ApiClient _client;
  final CancelToken _cancel;

  Future<AccountsOverview> overview() async {
    final response = await _client.get(
      ApiPaths.accounts,
      parse: parseObject((json) => json),
      cancelToken: _cancel,
    );
    return AccountsOverview.fromJson(response.data, response.meta);
  }

  Future<int> createAccount({
    required String name,
    required String type,
    num? openingBalance,
  }) async {
    final response = await _client.post(
      ApiPaths.accounts,
      parse: parseObject((json) => json),
      body: {
        'name': name.trim(),
        'type': type,
        'openingBalance': ?openingBalance,
      },
      cancelToken: _cancel,
    );
    final id = response.data['id'];
    return id is num ? id.toInt() : 0;
  }

  Future<void> transfer({
    required int fromAccountId,
    required int toAccountId,
    required num amount,
    String? note,
  }) {
    final text = note?.trim();
    return _client.post(
      ApiPaths.accountsTransfer,
      parse: parseNothing,
      body: {
        'fromAccountId': fromAccountId,
        'toAccountId': toAccountId,
        'amount': amount,
        if (text != null && text.isNotEmpty) 'note': text,
      },
    );
  }

  Future<ExpenseCreated> createExpense(ExpenseDraft draft) async {
    final response = await _client.post(
      ApiPaths.expenses,
      parse: parseObject(ExpenseCreated.fromJson),
      body: draft.toBody(),
    );
    return response.data;
  }

  /// A quick tile: the type alone, so the amount is its default and the money
  /// leaves the cash drawer.
  Future<ExpenseCreated> quickExpense(int categoryId) =>
      createExpense(ExpenseDraft(categoryId: categoryId));

  /// The money goes back into the account it left.
  Future<void> deleteExpense(int id) =>
      _client.delete(ApiPaths.expense(id), parse: parseNothing);

  Future<int> createCategory(CategoryDraft draft) async {
    final response = await _client.post(
      ApiPaths.expenseCategories,
      parse: parseObject((json) => json),
      body: draft.toBody(),
      cancelToken: _cancel,
    );
    final id = response.data['id'];
    return id is num ? id.toInt() : 0;
  }

  Future<void> updateCategory(int id, CategoryDraft draft) => _client.patch(
    ApiPaths.expenseCategory(id),
    parse: parseNothing,
    body: draft.toBody(),
    cancelToken: _cancel,
  );

  Future<CategoryRemoval> deleteCategory(int id) async {
    final response = await _client.delete(
      ApiPaths.expenseCategory(id),
      parse: (data) => data is Map<String, dynamic>
          ? CategoryRemoval.fromJson(data)
          : const CategoryRemoval(deleted: true, retired: false),
      cancelToken: _cancel,
    );
    return response.data;
  }
}

final accountsRepositoryProvider = Provider<AccountsRepository>((ref) {
  ref.watch(sessionScopeProvider);
  return AccountsRepository(
    ref.watch(apiClientProvider),
    ref.watch(scopeCancelTokenProvider),
  );
});

final accountsOverviewProvider = FutureProvider.autoDispose<AccountsOverview>((
  ref,
) {
  ref.watch(sessionScopeProvider);
  return ref.watch(accountsRepositoryProvider).overview();
});
