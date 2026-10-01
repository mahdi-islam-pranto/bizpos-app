import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/permissions/permissions.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/fields.dart';
import '../../../core/widgets/states.dart';
import '../../../l10n/app_localizations.dart';
import '../data/account_models.dart';
import '../data/accounts_repository.dart';
import 'accounts_screen.dart' show accountTypeLabel, refreshMoney;

/// The id the category box uses for "a new type, by name".
const int _newCategory = -1;

/// The full expense form.
///
/// A salary type asks for two more facts — who, and which month — and only a
/// salary type does: elsewhere the server ignores them, so the form does not
/// offer what would not be kept.
class ExpenseFormSheet extends ConsumerStatefulWidget {
  const ExpenseFormSheet({required this.overview, this.category, super.key});

  final AccountsOverview overview;
  final ExpenseCategory? category;

  static Future<void> show(
    BuildContext context, {
    required AccountsOverview overview,
    ExpenseCategory? category,
  }) =>
      showAppSheet<void>(
        context,
        title: AppL10n.of(context).recordExpense,
        builder: (_) => ExpenseFormSheet(overview: overview, category: category),
      );

  @override
  ConsumerState<ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends ConsumerState<ExpenseFormSheet> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  final _newName = TextEditingController();
  final _employee = TextEditingController();

  late int? _categoryId = widget.category?.id;
  late int? _accountId = widget.overview.defaultAccount?.id;
  DateTime? _date;
  late DateTime _salaryMonth = _previousMonth();
  bool _busy = false;
  bool _tried = false;

  /// August's salary handed over in September is the normal case, so the
  /// month a salary covers starts on the one before this.
  static DateTime _previousMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month - 1);
  }

  @override
  void initState() {
    super.initState();
    final amount = widget.category?.defaultAmount;
    if (amount != null && amount > 0) {
      _amount.text = ref.read(moneyProvider).plain(amount);
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    _newName.dispose();
    _employee.dispose();
    super.dispose();
  }

  ExpenseCategory? get _category {
    for (final c in widget.overview.categories) {
      if (c.id == _categoryId) return c;
    }
    return widget.category?.id == _categoryId ? widget.category : null;
  }

  bool get _isSalary => _category?.isSalary ?? false;

  String? get _categoryError {
    if (_categoryId == null) return AppL10n.of(context).requiredField;
    if (_categoryId == _newCategory && _newName.text.trim().isEmpty) {
      return AppL10n.of(context).requiredField;
    }
    return null;
  }

  /// An amount is needed unless the type has a default the server will use.
  String? get _amountError {
    final amount = AmountField.read(_amount);
    if (amount != null && amount > 0) return null;
    if (_amount.text.trim().isEmpty && (_category?.defaultAmount ?? 0) > 0) {
      return null;
    }
    return AppL10n.of(context).requiredField;
  }

  String? get _employeeError => _isSalary && _employee.text.trim().isEmpty
      ? AppL10n.of(context).requiredField
      : null;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      initialDate: _date ?? now,
    );
    if (picked == null) return;
    final today = DateTime(now.year, now.month, now.day);
    // Today is the default; only a day before it travels as `date`.
    setState(() => _date = picked.isBefore(today) ? picked : null);
  }

  Future<void> _save() async {
    setState(() => _tried = true);
    if (_categoryError != null || _amountError != null || _employeeError != null) {
      return;
    }
    setState(() => _busy = true);
    final l10n = AppL10n.of(context);
    final money = ref.read(moneyProvider);

    final draft = ExpenseDraft(
      categoryId: _categoryId == _newCategory ? null : _categoryId,
      categoryName: _categoryId == _newCategory ? _newName.text : null,
      amount: AmountField.read(_amount),
      accountId: _accountId,
      note: _note.text,
      date: _date,
      isSalary: _isSalary,
      employeeName: _employee.text,
      salaryMonth: _salaryMonth,
    );

    try {
      final created = await ref.read(accountsRepositoryProvider).createExpense(draft);
      refreshMoney(ref);
      if (!mounted) return;
      Navigator.of(context).pop();
      showNote(
        context,
        l10n.expenseRecorded(
          _category?.name ?? _newName.text.trim(),
          money.format(created.amount),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showApiError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final money = ref.watch(moneyProvider);
    final locale = ref.watch(meProvider)?.user.locale ?? 'en';
    final o = widget.overview;
    final categories = o.activeCategories;
    final mayNewType = ref.watch(permissionsProvider).has(P.accountsExpenseCreate);

    final typed = _employee.text.trim().toLowerCase();
    final suggestions = o.employees
        .where((n) => typed.isEmpty || n.toLowerCase().contains(typed))
        .where((n) => n.toLowerCase() != typed)
        .take(6)
        .toList();

    final months = [
      for (var i = -1; i < 12; i++)
        DateTime(DateTime.now().year, DateTime.now().month - i),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Insets.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _categoryId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.expenseType,
                    errorText: _tried ? _categoryError : null,
                  ),
                  items: [
                    for (final c in categories)
                      DropdownMenuItem(
                        value: c.id,
                        child: Text('${c.icon ?? ''} ${c.name}'.trim()),
                      ),
                    if (mayNewType)
                      DropdownMenuItem(
                        value: _newCategory,
                        child: Text(l10n.newExpenseType),
                      ),
                  ],
                  onChanged: (id) => setState(() {
                    _categoryId = id;
                    final c = _category;
                    if (c != null &&
                        (c.defaultAmount ?? 0) > 0 &&
                        _amount.text.trim().isEmpty) {
                      _amount.text = money.plain(c.defaultAmount);
                    }
                  }),
                ),
                if (_categoryId == _newCategory) ...[
                  const SizedBox(height: Insets.s12),
                  TextField(
                    controller: _newName,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: l10n.expenseTypeName,
                      helperText: l10n.newTypeHelp,
                      errorText: _tried ? _categoryError : null,
                    ),
                  ),
                ],
                const SizedBox(height: Insets.s12),
                AmountField(
                  controller: _amount,
                  label: l10n.amount,
                  prefix: '${money.sign} ',
                  onChanged: (_) => setState(() {}),
                  errorText: _tried ? _amountError : null,
                ),
                if (_isSalary) ...[
                  const SizedBox(height: Insets.s12),
                  TextField(
                    controller: _employee,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: l10n.employeeName,
                      helperText: l10n.employeeNameHelp,
                      errorText: _tried ? _employeeError : null,
                    ),
                  ),
                  if (suggestions.isNotEmpty) ...[
                    const SizedBox(height: Insets.s8),
                    Wrap(
                      spacing: Insets.s8,
                      runSpacing: Insets.s4,
                      children: [
                        for (final name in suggestions)
                          ActionChip(
                            label: Text(name),
                            onPressed: () => setState(() {
                              _employee.text = name;
                            }),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: Insets.s12),
                  DropdownButtonFormField<DateTime>(
                    initialValue: months.firstWhere(
                      (m) =>
                          m.year == _salaryMonth.year &&
                          m.month == _salaryMonth.month,
                      orElse: () => months[1],
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.salaryMonth,
                      helperText: l10n.salaryMonthHelp,
                    ),
                    items: [
                      for (final m in months)
                        DropdownMenuItem(
                          value: m,
                          child: Text(
                            DateFormat('MMMM y', locale == 'bn' ? 'bn_BD' : 'en_US')
                                .format(m),
                          ),
                        ),
                    ],
                    onChanged: (m) {
                      if (m != null) setState(() => _salaryMonth = m);
                    },
                  ),
                ],
                if (o.accounts.isNotEmpty) ...[
                  const SizedBox(height: Insets.s12),
                  DropdownButtonFormField<int>(
                    initialValue: _accountId,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: l10n.paidFrom),
                    items: [
                      for (final a in o.accounts)
                        DropdownMenuItem(
                          value: a.id,
                          child: Text(
                            '${a.name} · ${money.format(a.balance)}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (id) => setState(() => _accountId = id),
                  ),
                ],
                const SizedBox(height: Insets.s12),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(Radii.row),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.dateLabel,
                      helperText: _date == null ? null : l10n.backdatedHelp,
                      suffixIcon: const Icon(Icons.event_outlined),
                    ),
                    child: Text(
                      _date == null
                          ? l10n.today
                          : AppDates.day(_date, locale: locale),
                      style: text.bodyLarge?.copyWith(
                        color: _date == null ? null : palette.warning,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Insets.s12),
                TextField(
                  controller: _note,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(labelText: l10n.note),
                ),
              ],
            ),
          ),
        ),
        SheetAction(
          label: l10n.recordExpense,
          icon: Icons.check,
          busy: _busy,
          onPressed: _save,
        ),
      ],
    );
  }
}

/// Moving money between two of the shop's own accounts — a bank deposit, most
/// days.
class TransferSheet extends ConsumerStatefulWidget {
  const TransferSheet({required this.overview, super.key});

  final AccountsOverview overview;

  static Future<void> show(
    BuildContext context, {
    required AccountsOverview overview,
  }) =>
      showAppSheet<void>(
        context,
        title: AppL10n.of(context).transfer,
        builder: (_) => TransferSheet(overview: overview),
      );

  @override
  ConsumerState<TransferSheet> createState() => _TransferSheetState();
}

class _TransferSheetState extends ConsumerState<TransferSheet> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  late int? _from = widget.overview.defaultAccount?.id;
  int? _to;
  bool _busy = false;
  bool _tried = false;

  @override
  void initState() {
    super.initState();
    final others = widget.overview.accounts.where((a) => a.id != _from);
    _to = others.isEmpty ? null : others.first.id;
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = AmountField.read(_amount);
    setState(() => _tried = true);
    if (_from == null || _to == null || _from == _to) return;
    if (amount == null || amount <= 0) return;

    setState(() => _busy = true);
    final l10n = AppL10n.of(context);
    try {
      await ref.read(accountsRepositoryProvider).transfer(
            fromAccountId: _from!,
            toAccountId: _to!,
            amount: amount,
            note: _note.text,
          );
      refreshMoney(ref);
      if (!mounted) return;
      Navigator.of(context).pop();
      showNote(context, l10n.transferDone);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showApiError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final money = ref.watch(moneyProvider);
    final accounts = widget.overview.accounts;
    final amount = AmountField.read(_amount);

    DropdownMenuItem<int> item(MoneyAccount a) => DropdownMenuItem(
          value: a.id,
          child: Text(
            '${a.name} · ${money.format(a.balance)}',
            overflow: TextOverflow.ellipsis,
          ),
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Insets.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _from,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l10n.fromAccount),
                  items: [for (final a in accounts) item(a)],
                  onChanged: (id) => setState(() => _from = id),
                ),
                const SizedBox(height: Insets.s12),
                DropdownButtonFormField<int>(
                  initialValue: _to,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.toAccount,
                    errorText: _tried && _from == _to
                        ? l10n.sameAccount
                        : (_tried && _to == null ? l10n.requiredField : null),
                  ),
                  items: [for (final a in accounts) item(a)],
                  onChanged: (id) => setState(() => _to = id),
                ),
                const SizedBox(height: Insets.s12),
                AmountField(
                  controller: _amount,
                  label: l10n.amount,
                  prefix: '${money.sign} ',
                  onChanged: (_) => setState(() {}),
                  errorText: _tried && (amount == null || amount <= 0)
                      ? l10n.requiredField
                      : null,
                ),
                const SizedBox(height: Insets.s12),
                TextField(
                  controller: _note,
                  decoration: InputDecoration(labelText: l10n.note),
                ),
              ],
            ),
          ),
        ),
        SheetAction(
          label: l10n.transfer,
          icon: Icons.swap_horiz,
          busy: _busy,
          onPressed: _save,
        ),
      ],
    );
  }
}

/// A new place for money to sit.
class AccountFormSheet extends ConsumerStatefulWidget {
  const AccountFormSheet({super.key});

  static Future<void> show(BuildContext context) => showAppSheet<void>(
        context,
        title: AppL10n.of(context).addAccount,
        builder: (_) => const AccountFormSheet(),
      );

  @override
  ConsumerState<AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends ConsumerState<AccountFormSheet> {
  final _name = TextEditingController();
  final _opening = TextEditingController();
  String _type = 'bank';
  bool _busy = false;
  bool _tried = false;

  @override
  void dispose() {
    _name.dispose();
    _opening.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _tried = true);
    if (_name.text.trim().isEmpty) return;
    setState(() => _busy = true);
    final l10n = AppL10n.of(context);
    try {
      await ref.read(accountsRepositoryProvider).createAccount(
            name: _name.text,
            type: _type,
            openingBalance: AmountField.read(_opening),
          );
      refreshMoney(ref);
      if (!mounted) return;
      Navigator.of(context).pop();
      showNote(context, l10n.accountAdded);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showApiError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final money = ref.watch(moneyProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Insets.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<String>(
                  segments: [
                    for (final t in const ['cash', 'bank', 'mfs'])
                      ButtonSegment(
                        value: t,
                        label: Text(accountTypeLabel(l10n, t)),
                      ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) => setState(() => _type = s.first),
                ),
                const SizedBox(height: Insets.s12),
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: l10n.accountName,
                    hintText: l10n.accountNameHint,
                    errorText: _tried && _name.text.trim().isEmpty
                        ? l10n.requiredField
                        : null,
                  ),
                ),
                const SizedBox(height: Insets.s12),
                AmountField(
                  controller: _opening,
                  label: l10n.openingBalance,
                  prefix: '${money.sign} ',
                ),
              ],
            ),
          ),
        ),
        SheetAction(
          label: l10n.save,
          icon: Icons.check,
          busy: _busy,
          onPressed: _save,
        ),
      ],
    );
  }
}

/// The shop's expense types: which are tiles, what they cost by default, and
/// which one is Salary.
class CategoriesSheet extends ConsumerWidget {
  const CategoriesSheet({super.key});

  static Future<void> show(BuildContext context) => showAppSheet<void>(
        context,
        title: AppL10n.of(context).expenseTypes,
        builder: (_) => const CategoriesSheet(),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final money = ref.watch(moneyProvider);
    final overview = ref.watch(accountsOverviewProvider);

    return AsyncView<AccountsOverview>(
      value: overview,
      onRetry: () => ref.invalidate(accountsOverviewProvider),
      builder: (context, o) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: o.categories.isEmpty
                ? EmptyState(title: l10n.noExpenseTypes)
                : ListView(
                    shrinkWrap: true,
                    children: [
                      for (final c in o.categories)
                        ListTile(
                          leading: Text(
                            c.icon ?? '💸',
                            style: const TextStyle(fontSize: 22),
                          ),
                          title: Text(
                            c.name,
                            style: c.isActive
                                ? null
                                : TextStyle(color: palette.muted),
                          ),
                          subtitle: Text(
                            [
                              if ((c.defaultAmount ?? 0) > 0)
                                money.format(c.defaultAmount),
                              if (c.isQuick) l10n.quickTile,
                              if (c.isSalary) l10n.salaryType,
                              if (!c.isActive) l10n.retired,
                            ].join(' · '),
                            style: text.bodySmall?.copyWith(color: palette.muted),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => CategoryFormSheet.show(context, category: c),
                        ),
                    ],
                  ),
          ),
          SheetAction(
            label: l10n.newExpenseType,
            icon: Icons.add,
            onPressed: () => CategoryFormSheet.show(context),
          ),
        ],
      ),
    );
  }
}

class CategoryFormSheet extends ConsumerStatefulWidget {
  const CategoryFormSheet({this.category, super.key});

  final ExpenseCategory? category;

  static Future<void> show(BuildContext context, {ExpenseCategory? category}) {
    final l10n = AppL10n.of(context);
    return showAppSheet<void>(
      context,
      title: category == null ? l10n.newExpenseType : l10n.editExpenseType,
      builder: (_) => CategoryFormSheet(category: category),
    );
  }

  @override
  ConsumerState<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<CategoryFormSheet> {
  late final CategoryDraft _start = widget.category == null
      ? const CategoryDraft(name: '', isQuick: true)
      : CategoryDraft.of(widget.category!);
  late final _name = TextEditingController(text: _start.name);
  late final _icon = TextEditingController(text: _start.icon ?? '');
  late final _amount = TextEditingController(
    text: (_start.defaultAmount ?? 0) > 0
        ? ref.read(moneyProvider).plain(_start.defaultAmount)
        : '',
  );
  late bool _isQuick = _start.isQuick;
  late bool _isSalary = _start.isSalary;
  late bool _isActive = _start.isActive;
  bool _busy = false;
  bool _tried = false;

  @override
  void dispose() {
    _name.dispose();
    _icon.dispose();
    _amount.dispose();
    super.dispose();
  }

  CategoryDraft get _draft => CategoryDraft(
        name: _name.text,
        icon: _icon.text,
        defaultAmount: AmountField.read(_amount),
        isQuick: _isQuick,
        isSalary: _isSalary,
        isActive: _isActive,
        sortOrder: _start.sortOrder,
      );

  Future<void> _save() async {
    setState(() => _tried = true);
    if (_name.text.trim().isEmpty) return;
    setState(() => _busy = true);
    final l10n = AppL10n.of(context);
    final repository = ref.read(accountsRepositoryProvider);
    try {
      final id = widget.category?.id;
      if (id == null) {
        await repository.createCategory(_draft);
      } else {
        await repository.updateCategory(id, _draft);
      }
      refreshMoney(ref);
      if (!mounted) return;
      Navigator.of(context).pop();
      showNote(context, l10n.expenseTypeSaved);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showApiError(context, e);
      }
    }
  }

  Future<void> _delete() async {
    final l10n = AppL10n.of(context);
    final sure = await confirmSheet(
      context,
      title: l10n.deleteExpenseType,
      message: l10n.deleteExpenseTypeBody,
      confirmLabel: l10n.delete,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (!sure || !mounted) return;
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(accountsRepositoryProvider)
          .deleteCategory(widget.category!.id);
      refreshMoney(ref);
      if (!mounted) return;
      Navigator.of(context).pop();
      showNote(
        context,
        result.retired
            ? l10n.expenseTypeRetired(result.usedCount ?? 0)
            : l10n.expenseTypeDeleted,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showApiError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final money = ref.watch(moneyProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Insets.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 72,
                      child: TextField(
                        controller: _icon,
                        textAlign: TextAlign.center,
                        maxLength: 4,
                        decoration: InputDecoration(
                          labelText: l10n.iconLabel,
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(width: Insets.s12),
                    Expanded(
                      child: TextField(
                        controller: _name,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: l10n.expenseTypeName,
                          errorText: _tried && _name.text.trim().isEmpty
                              ? l10n.requiredField
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Insets.s12),
                AmountField(
                  controller: _amount,
                  label: l10n.defaultAmount,
                  prefix: '${money.sign} ',
                  helperText: l10n.defaultAmountHelp,
                ),
                const SizedBox(height: Insets.s8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.quickTile),
                  subtitle: Text(l10n.quickTileHelp),
                  value: _isQuick,
                  onChanged: (v) => setState(() => _isQuick = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.salaryType),
                  subtitle: Text(l10n.salaryTypeHelp),
                  value: _isSalary,
                  onChanged: (v) => setState(() => _isSalary = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.inUse),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
                if (widget.category != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: palette.danger,
                      ),
                      onPressed: _busy ? null : _delete,
                      icon: const Icon(Icons.delete_outline),
                      label: Text(l10n.deleteExpenseType),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SheetAction(
          label: l10n.save,
          icon: Icons.check,
          busy: _busy,
          onPressed: _save,
        ),
      ],
    );
  }
}
