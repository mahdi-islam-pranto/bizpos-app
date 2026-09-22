import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/money.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/permissions/permission_gate.dart';
import '../../../core/permissions/permissions.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/fields.dart';
import '../../../l10n/app_localizations.dart';
import '../data/customer_models.dart';
import '../data/customers_repository.dart';

/// Adding or editing a customer.
///
/// The credit limit is shown **only** with `customers.credit.manage`, and only
/// then is it sent. Without the permission the server drops the field without
/// complaint, so a form that offered it would let somebody set a limit, see the
/// sheet close on success, and find nothing changed.
class CustomerFormSheet extends ConsumerStatefulWidget {
  const CustomerFormSheet({this.customer, this.mayManageCredit, super.key});

  /// Null to create.
  final Customer? customer;

  /// The list's `meta.mayManageCredit`, combined with the permission.
  final bool? mayManageCredit;

  static Future<bool> show(
    BuildContext context, {
    Customer? customer,
    bool? mayManageCredit,
  }) async =>
      await showAppSheet<bool>(
        context,
        title: customer == null
            ? AppL10n.of(context).newCustomer
            : AppL10n.of(context).editCustomer,
        builder: (_) => CustomerFormSheet(
          customer: customer,
          mayManageCredit: mayManageCredit,
        ),
      ) ??
      false;

  @override
  ConsumerState<CustomerFormSheet> createState() => _CustomerFormSheetState();
}

class _CustomerFormSheetState extends ConsumerState<CustomerFormSheet> {
  late final _name = TextEditingController(text: widget.customer?.name ?? '');
  late final _phone = TextEditingController(text: widget.customer?.phone ?? '');
  late final _email = TextEditingController(text: widget.customer?.email ?? '');
  late final _address =
      TextEditingController(text: widget.customer?.address ?? '');
  late final _credit = TextEditingController(
    text: widget.customer?.creditLimit == null ||
            widget.customer!.creditLimit == 0
        ? ''
        : widget.customer!.creditLimit!.toString(),
  );

  Map<String, List<String>> _fieldErrors = const {};
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _credit.dispose();
    super.dispose();
  }

  String? _trimmed(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  Future<void> _save({required bool mayManageCredit}) async {
    final name = _name.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _busy = true;
      _fieldErrors = const {};
    });

    final repository = ref.read(customersRepositoryProvider);
    try {
      if (widget.customer == null) {
        await repository.create(
          name: name,
          phone: _trimmed(_phone),
          email: _trimmed(_email),
          address: _trimmed(_address),
          creditLimit: mayManageCredit ? AmountField.read(_credit) : null,
        );
      } else {
        await repository.update(
          widget.customer!.id,
          name: name,
          phone: _trimmed(_phone),
          email: _trimmed(_email),
          address: _trimmed(_address),
          creditLimit: mayManageCredit ? AmountField.read(_credit) : null,
        );
      }
      if (!mounted) return;
      ref.invalidate(customersProvider);
      showNote(context, AppL10n.of(context).customerSaved);
      Navigator.of(context).pop(true);
    } on ValidationException catch (e) {
      // The server names the offending fields, so they are bound under the
      // inputs rather than thrown into a snack bar the person cannot act on.
      if (mounted) setState(() => _fieldErrors = e.fields);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final money = ref.watch(moneyProvider);
    final mayManageCredit = ref
        .watch(permissionsProvider)
        .allows(P.customersCreditManage, alsoRequire: widget.mayManageCredit);

    String? errorFor(String field) {
      final messages = _fieldErrors[field];
      return (messages == null || messages.isEmpty) ? null : messages.first;
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(Insets.gutter),
            child: Column(
              children: [
                TextField(
                  controller: _name,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n.customerName,
                    errorText: errorFor('name'),
                  ),
                ),
                const SizedBox(height: Insets.s16),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: l10n.customerPhone,
                    errorText: errorFor('phone'),
                  ),
                ),
                const SizedBox(height: Insets.s16),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: l10n.customerEmail,
                    errorText: errorFor('email'),
                  ),
                ),
                const SizedBox(height: Insets.s16),
                TextField(
                  controller: _address,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: l10n.customerAddress,
                    errorText: errorFor('address'),
                  ),
                ),
                if (mayManageCredit) ...[
                  const SizedBox(height: Insets.s16),
                  AmountField(
                    controller: _credit,
                    label: l10n.creditLimit,
                    prefix: money.sign,
                    helperText: l10n.creditLimitHelp,
                    errorText: errorFor('creditLimit'),
                  ),
                ],
              ],
            ),
          ),
          SheetAction(
            label: l10n.save,
            icon: Icons.check,
            busy: _busy,
            onPressed: () => _save(mayManageCredit: mayManageCredit),
          ),
        ],
      ),
    );
  }
}

/// Moving a customer's loyalty balance by hand.
///
/// Signed and never zero. Taking the balance below zero is `422 negative`, and
/// the server's own sentence is what gets shown.
class AdjustPointsSheet extends ConsumerStatefulWidget {
  const AdjustPointsSheet({required this.customer, super.key});

  final Customer customer;

  static Future<bool> show(BuildContext context, Customer customer) async =>
      await showAppSheet<bool>(
        context,
        title: AppL10n.of(context).adjustPoints,
        subtitle: customer.name,
        builder: (_) => AdjustPointsSheet(customer: customer),
      ) ??
      false;

  @override
  ConsumerState<AdjustPointsSheet> createState() => _AdjustPointsSheetState();
}

class _AdjustPointsSheetState extends ConsumerState<AdjustPointsSheet> {
  final _points = TextEditingController();
  final _note = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _points.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final points = num.tryParse(_points.text.trim());
    final note = _note.text.trim();
    if (points == null || points == 0 || note.isEmpty) return;

    setState(() => _busy = true);
    try {
      final balance = await ref
          .read(customersRepositoryProvider)
          .adjustPoints(widget.customer.id, points: points, note: note);
      if (!mounted) return;
      ref.invalidate(customerPointsProvider(widget.customer.id));
      ref.invalidate(customersProvider);
      showNote(
        context,
        AppL10n.of(context).pointsAdjusted(balance.toStringAsFixed(0)),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(Insets.gutter),
            child: Column(
              children: [
                TextField(
                  controller: _points,
                  autofocus: true,
                  // Signed: a minus sign is the whole point of this field.
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.points,
                    helperText: l10n.adjustPointsHelp,
                  ),
                ),
                const SizedBox(height: Insets.s16),
                TextField(
                  controller: _note,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(labelText: l10n.pointsNote),
                  onSubmitted: (_) => _save(),
                ),
              ],
            ),
          ),
          SheetAction(
            label: l10n.save,
            icon: Icons.check,
            busy: _busy,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
