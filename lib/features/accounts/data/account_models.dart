import '../../../core/format/dates.dart';
import '../../../core/network/envelope.dart';

int _int(Object? v) => switch (v) {
  final int x => x,
  final num x => x.toInt(),
  final String x => int.tryParse(x) ?? 0,
  _ => 0,
};

int? _intOrNull(Object? v) => v == null ? null : _int(v);

num _num(Object? v) => switch (v) {
  final num x => x,
  final String x => num.tryParse(x) ?? 0,
  _ => 0,
};

num? _numOrNull(Object? v) => v == null ? null : _num(v);

String _str(Object? v) => v?.toString() ?? '';

String? _strOrNull(Object? v) {
  final s = v?.toString();
  return (s == null || s.isEmpty) ? null : s;
}

bool _bool(Object? v) => v == true || v == 1 || v == 'true' || v == '1';

List<T> _listOf<T>(Object? raw, T Function(Map<String, dynamic>) parse) {
  if (raw is! List) return const [];
  return raw.whereType<Map<String, dynamic>>().map(parse).toList();
}

/// A name the server may send as a plain string or as `{name: ...}` — the
/// account and category on an expense row come either way depending on the
/// endpoint's age.
String? _nameOf(Object? v) => switch (v) {
  final Map<String, dynamic> m => _strOrNull(m['name']),
  _ => _strOrNull(v),
};

/// Where money sits: the cash drawer, a bank, a bKash wallet.
class MoneyAccount {
  const MoneyAccount({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.isDefault = false,
  });

  final int id;
  final String name;

  /// `cash`, `bank` or `mfs`.
  final String type;
  final num balance;
  final bool isDefault;

  factory MoneyAccount.fromJson(Map<String, dynamic> json) => MoneyAccount(
    id: _int(json['id']),
    name: _str(json['name']),
    type: _str(json['type']),
    balance: _num(json['balance'] ?? json['currentBalance']),
    isDefault: _bool(json['isDefault']),
  );
}

/// An expense type. Every store has a Salary one, which asks for a name and a
/// month; a quick one is a tile on the accounts screen.
class ExpenseCategory {
  const ExpenseCategory({
    required this.id,
    required this.name,
    this.icon,
    this.defaultAmount,
    this.isQuick = false,
    this.isSalary = false,
    this.isActive = true,
    this.sortOrder,
  });

  final int id;
  final String name;

  /// An emoji.
  final String? icon;
  final num? defaultAmount;
  final bool isQuick;
  final bool isSalary;
  final bool isActive;
  final int? sortOrder;

  /// A tile can post in one tap only when there is an amount to post and no
  /// name to ask for. Otherwise it opens the form with this type chosen.
  bool get oneTap => !isSalary && (defaultAmount ?? 0) > 0;

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) =>
      ExpenseCategory(
        id: _int(json['id']),
        name: _str(json['name']),
        icon: _strOrNull(json['icon']),
        defaultAmount: _numOrNull(json['defaultAmount']),
        // A `quick[]` row may leave the flag out: being in that list says it.
        isQuick: _bool(json['isQuick']),
        isSalary: _bool(json['isSalary']),
        isActive: json['isActive'] == null ? true : _bool(json['isActive']),
        sortOrder: _intOrNull(json['sortOrder']),
      );
}

/// Money that left the shop.
class Expense {
  const Expense({
    required this.id,
    required this.amount,
    this.categoryId,
    this.category,
    this.icon,
    this.account,
    this.note,
    this.date,
    this.createdAt,
    this.userName,
    this.isSalary = false,
    this.employeeName,
    this.salaryMonth,
  });

  final int id;
  final num amount;
  final int? categoryId;
  final String? category;
  final String? icon;
  final String? account;
  final String? note;

  /// The day the money left, which a backdated expense sets apart from
  /// [createdAt].
  final DateTime? date;
  final DateTime? createdAt;
  final String? userName;
  final bool isSalary;
  final String? employeeName;

  /// `YYYY-MM`: the month the salary covers, not the day it was paid.
  final String? salaryMonth;

  DateTime? get when => date ?? createdAt;

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
    id: _int(json['id']),
    amount: _num(json['amount']),
    categoryId: _intOrNull(json['categoryId']),
    category: _nameOf(json['categoryName'] ?? json['category']),
    icon: _strOrNull(json['icon'] ?? json['categoryIcon']),
    account: _nameOf(json['accountName'] ?? json['account']),
    note: _strOrNull(json['note']),
    date: AppDates.parse(json['date'] ?? json['expenseDate']),
    createdAt: AppDates.parse(json['createdAt']),
    userName: _nameOf(json['userName'] ?? json['user']),
    isSalary: _bool(json['isSalary']),
    employeeName: _strOrNull(json['employeeName']),
    salaryMonth: _strOrNull(json['salaryMonth']),
  );
}

/// A line of an account's statement: a sale paid in, an expense, a transfer.
class AccountTransaction {
  const AccountTransaction({
    required this.id,
    required this.amount,
    this.type,
    this.direction,
    this.account,
    this.note,
    this.createdAt,
  });

  final int id;

  /// Signed where the server signs it; [direction] says which way otherwise.
  final num amount;
  final String? type;

  /// `in` or `out`, when sent.
  final String? direction;
  final String? account;
  final String? note;
  final DateTime? createdAt;

  /// Money leaving the account.
  bool get isOut =>
      direction == 'out' ||
      direction == 'debit' ||
      (direction == null && amount < 0);

  factory AccountTransaction.fromJson(Map<String, dynamic> json) =>
      AccountTransaction(
        id: _int(json['id']),
        amount: _num(json['amount']),
        type: _strOrNull(json['type']),
        direction: _strOrNull(json['direction'] ?? json['flow']),
        account: _nameOf(json['accountName'] ?? json['account']),
        note: _strOrNull(json['note'] ?? json['description']),
        createdAt: AppDates.parse(json['createdAt'] ?? json['date']),
      );
}

/// `GET /accounts` — the whole money screen in one call.
class AccountsOverview {
  const AccountsOverview({
    required this.accounts,
    required this.expenses,
    required this.transactions,
    required this.categories,
    required this.quick,
    required this.employees,
    required this.todayExpense,
    required this.monthExpense,
    required this.monthSalary,
    required this.meta,
  });

  final List<MoneyAccount> accounts;

  /// The latest 80.
  final List<Expense> expenses;

  /// The latest 40.
  final List<AccountTransaction> transactions;
  final List<ExpenseCategory> categories;
  final List<ExpenseCategory> quick;

  /// Every name a salary has been paid to, for the suggestion list.
  final List<String> employees;
  final num todayExpense;
  final num monthExpense;
  final num monthSalary;
  final Meta meta;

  bool? get mayManage => meta.flag('mayManage');
  bool? get mayExpense => meta.flag('mayExpense');
  bool? get mayDeleteExpense => meta.flag('mayDeleteExpense');
  bool? get mayManageCategories => meta.flag('mayManageCategories');
  bool? get mayTransfer => meta.flag('mayTransfer');

  num get totalBalance => accounts.fold<num>(0, (sum, a) => sum + a.balance);

  List<ExpenseCategory> get activeCategories =>
      categories.where((c) => c.isActive).toList();

  MoneyAccount? get defaultAccount {
    if (accounts.isEmpty) return null;
    for (final a in accounts) {
      if (a.isDefault) return a;
    }
    for (final a in accounts) {
      if (a.type == 'cash') return a;
    }
    return accounts.first;
  }

  factory AccountsOverview.fromJson(Map<String, dynamic> json, Meta meta) {
    final categories = _listOf(json['categories'], ExpenseCategory.fromJson);
    // A quick tile is a category; take the full row when the two lists agree,
    // so a tile knows about `isSalary` even if `quick[]` leaves it out.
    final byId = {for (final c in categories) c.id: c};
    final quick = _listOf(
      json['quick'],
      ExpenseCategory.fromJson,
    ).map((q) => byId[q.id] ?? q).toList();
    final employees = json['employees'] is List
        ? (json['employees'] as List).map(_nameOf).whereType<String>().toList()
        : const <String>[];

    return AccountsOverview(
      accounts: _listOf(json['accounts'], MoneyAccount.fromJson),
      expenses: _listOf(json['expenses'], Expense.fromJson),
      transactions: _listOf(json['transactions'], AccountTransaction.fromJson),
      categories: categories,
      quick: quick,
      employees: employees,
      todayExpense: _num(json['todayExpense']),
      monthExpense: _num(json['monthExpense']),
      monthSalary: _num(json['monthSalary']),
      meta: meta,
    );
  }
}

/// What `POST /expenses` answers with. The amount is the server's — a quick
/// tile sends none and gets the type's default.
class ExpenseCreated {
  const ExpenseCreated({
    required this.id,
    required this.amount,
    required this.isSalary,
  });

  final int id;
  final num amount;
  final bool isSalary;

  factory ExpenseCreated.fromJson(Map<String, dynamic> json) => ExpenseCreated(
    id: _int(json['id']),
    amount: _num(json['amount']),
    isSalary: _bool(json['isSalary']),
  );
}

/// An expense about to be recorded.
///
/// Either an existing type ([categoryId]) or a new one by name
/// ([categoryName]), which the server creates. The salary fields travel only
/// for a salary type: elsewhere they are ignored, and sending them anyway
/// would make the echo disagree with the form.
class ExpenseDraft {
  const ExpenseDraft({
    this.categoryId,
    this.categoryName,
    this.amount,
    this.accountId,
    this.note,
    this.date,
    this.isSalary = false,
    this.employeeName,
    this.salaryMonth,
  });

  final int? categoryId;
  final String? categoryName;
  final num? amount;
  final int? accountId;
  final String? note;

  /// Only when the money left on an earlier day.
  final DateTime? date;
  final bool isSalary;
  final String? employeeName;
  final DateTime? salaryMonth;

  static String month(DateTime at) =>
      '${at.year.toString().padLeft(4, '0')}-${at.month.toString().padLeft(2, '0')}';

  Map<String, dynamic> toBody() {
    final name = categoryName?.trim();
    final text = note?.trim();
    final employee = employeeName?.trim();
    return {
      if (categoryId != null)
        'categoryId': categoryId
      else if (name != null && name.isNotEmpty)
        'categoryName': name,
      'amount': ?amount,
      'accountId': ?accountId,
      if (text != null && text.isNotEmpty) 'note': text,
      if (date != null) 'date': AppDates.bucket(date!),
      if (isSalary && employee != null && employee.isNotEmpty)
        'employeeName': employee,
      if (isSalary && salaryMonth != null) 'salaryMonth': month(salaryMonth!),
    };
  }
}

/// An expense type as the form edits it.
///
/// **Every flag always travels.** `PATCH /expense-categories/{id}` reads an
/// omitted `isQuick` or `isSalary` as false, so a partial body would quietly
/// take the tile off the screen or stop Salary asking for a name.
class CategoryDraft {
  const CategoryDraft({
    required this.name,
    this.icon,
    this.defaultAmount,
    this.isQuick = false,
    this.isSalary = false,
    this.isActive = true,
    this.sortOrder,
  });

  factory CategoryDraft.of(ExpenseCategory c) => CategoryDraft(
    name: c.name,
    icon: c.icon,
    defaultAmount: c.defaultAmount,
    isQuick: c.isQuick,
    isSalary: c.isSalary,
    isActive: c.isActive,
    sortOrder: c.sortOrder,
  );

  final String name;
  final String? icon;
  final num? defaultAmount;
  final bool isQuick;
  final bool isSalary;
  final bool isActive;
  final int? sortOrder;

  Map<String, dynamic> toBody() {
    final emoji = icon?.trim();
    return {
      'name': name.trim(),
      'icon': (emoji == null || emoji.isEmpty) ? null : emoji,
      'defaultAmount': defaultAmount,
      'isQuick': isQuick,
      'isSalary': isSalary,
      'isActive': isActive,
      'sortOrder': ?sortOrder,
    };
  }
}

/// `DELETE /expense-categories/{id}`: a type with expenses behind it is
/// retired, not deleted, so the old rows keep their name.
class CategoryRemoval {
  const CategoryRemoval({
    required this.deleted,
    required this.retired,
    this.usedCount,
  });

  final bool deleted;
  final bool retired;
  final int? usedCount;

  factory CategoryRemoval.fromJson(Map<String, dynamic> json) =>
      CategoryRemoval(
        deleted: _bool(json['deleted']),
        retired: _bool(json['retired']),
        usedCount: _intOrNull(json['usedCount']),
      );
}
