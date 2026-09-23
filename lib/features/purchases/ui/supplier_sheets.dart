import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/states.dart';
import '../../../l10n/app_localizations.dart';
import '../data/purchase_models.dart';
import '../data/purchases_repository.dart';

/// Every party the shop buys from, from `meta.suppliers`, with add and edit
/// for `purchase.supplier.manage`.
class SupplierListSheet extends StatelessWidget {
  const SupplierListSheet({
    required this.suppliers,
    required this.mayManage,
    super.key,
  });

  final List<Supplier> suppliers;
  final bool mayManage;

  static Future<void> show(
    BuildContext context, {
    required List<Supplier> suppliers,
    required bool mayManage,
  }) =>
      showAppSheet<void>(
        context,
        title: AppL10n.of(context).suppliers,
        builder: (_) =>
            SupplierListSheet(suppliers: suppliers, mayManage: mayManage),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: suppliers.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(Insets.s24),
                  child: EmptyState(
                    icon: Icons.people_alt_outlined,
                    title: l10n.suppliersEmpty,
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: suppliers.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: palette.hairline),
                  itemBuilder: (context, i) {
                    final s = suppliers[i];
                    return ListTile(
                      title: Text(s.name),
                      subtitle: Text(
                        [?s.company, ?s.phone].join(' · '),
                        style: TextStyle(color: palette.muted),
                      ),
                      trailing: mayManage
                          ? const Icon(Icons.edit_outlined, size: 18)
                          : null,
                      onTap: mayManage
                          ? () {
                              final navigator = Navigator.of(context);
                              navigator.pop();
                              SupplierFormSheet.show(
                                navigator.context,
                                supplier: s,
                              );
                            }
                          : null,
                    );
                  },
                ),
        ),
        if (mayManage)
          SheetAction(
            label: l10n.addSupplier,
            icon: Icons.person_add_alt_1_outlined,
            onPressed: () {
              final navigator = Navigator.of(context);
              navigator.pop();
              SupplierFormSheet.show(navigator.context);
            },
          ),
      ],
    );
  }
}

/// `POST /suppliers` or `PATCH /suppliers/{id}`. Returns the saved supplier.
class SupplierFormSheet extends ConsumerStatefulWidget {
  const SupplierFormSheet({this.supplier, this.initialName, super.key});

  final Supplier? supplier;
  final String? initialName;

  static Future<Supplier?> show(
    BuildContext context, {
    Supplier? supplier,
    String? initialName,
  }) =>
      showAppSheet<Supplier>(
        context,
        title: supplier?.name ?? AppL10n.of(context).addSupplier,
        builder: (_) =>
            SupplierFormSheet(supplier: supplier, initialName: initialName),
      );

  @override
  ConsumerState<SupplierFormSheet> createState() => _SupplierFormSheetState();
}

class _SupplierFormSheetState extends ConsumerState<SupplierFormSheet> {
  late final _name = TextEditingController(
    text: widget.supplier?.name ?? widget.initialName ?? '',
  );
  late final _company =
      TextEditingController(text: widget.supplier?.company ?? '');
  late final _phone = TextEditingController(text: widget.supplier?.phone ?? '');
  late final _address =
      TextEditingController(text: widget.supplier?.address ?? '');
  bool _busy = false;
  Map<String, List<String>> _errors = const {};

  @override
  void dispose() {
    _name.dispose();
    _company.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  String? _text(TextEditingController c) {
    final v = c.text.trim();
    return v.isEmpty ? null : v;
  }

  String? _error(String field) {
    final m = _errors[field];
    return (m == null || m.isEmpty) ? null : m.first;
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (_busy || name.isEmpty) return;
    setState(() {
      _busy = true;
      _errors = const {};
    });
    final repository = ref.read(purchasesRepositoryProvider);
    final l10n = AppL10n.of(context);
    try {
      var id = widget.supplier?.id;
      if (id == null) {
        id = await repository.createSupplier(
          name: name,
          company: _text(_company),
          phone: _text(_phone),
          address: _text(_address),
        );
      } else {
        await repository.updateSupplier(
          id,
          name: name,
          company: _text(_company),
          phone: _text(_phone),
          address: _text(_address),
        );
      }
      ref.invalidate(purchasesProvider);
      if (!mounted) return;
      Navigator.of(context).pop(
        Supplier(
          id: id,
          name: name,
          company: _text(_company),
          phone: _text(_phone),
          address: _text(_address),
        ),
      );
      showNote(context, l10n.supplierSaved);
    } on ValidationException catch (e) {
      if (mounted) setState(() => _errors = e.fields);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(Insets.gutter),
          child: Column(
            children: [
              TextField(
                controller: _name,
                autofocus: widget.supplier == null,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.supplierName,
                  errorText: _error('name'),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: Insets.s16),
              TextField(
                controller: _company,
                decoration: InputDecoration(labelText: l10n.supplierCompany),
              ),
              const SizedBox(height: Insets.s16),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: l10n.phone,
                  errorText: _error('phone'),
                ),
              ),
              const SizedBox(height: Insets.s16),
              TextField(
                controller: _address,
                decoration: InputDecoration(labelText: l10n.customerAddress),
              ),
            ],
          ),
        ),
        SheetAction(
          label: l10n.save,
          icon: Icons.check,
          busy: _busy,
          onPressed: _name.text.trim().isEmpty ? null : _save,
        ),
      ],
    );
  }
}
