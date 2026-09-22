import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/money.dart';
import '../../../core/permissions/permission_gate.dart';
import '../../../core/permissions/permissions.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/fields.dart';
import '../../../core/widgets/states.dart';
import '../../../l10n/app_localizations.dart';
import '../data/customer_models.dart';
import '../data/customers_repository.dart';
import 'customer_form_sheet.dart';

/// The customer list.
///
/// Not paginated: the server returns up to 100 and takes `?q=`. So when the
/// window comes back full, the screen says so and points at the search box
/// rather than pretending the shop has exactly a hundred customers.
class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 320),
      () => ref.read(customerQueryProvider.notifier).set(value.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final customers = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.customersTitle)),
      floatingActionButton: customers.maybeWhen(
        data: (page) => ref
                .watch(permissionsProvider)
                .allows(P.customersCustomerCreate, alsoRequire: page.mayCreate)
            ? FloatingActionButton.extended(
                onPressed: () => CustomerFormSheet.show(
                  context,
                  mayManageCredit: page.mayManageCredit,
                ),
                icon: const Icon(Icons.person_add_alt),
                label: Text(l10n.newCustomer),
              )
            : null,
        orElse: () => null,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Insets.gutter,
              Insets.s12,
              Insets.gutter,
              Insets.s8,
            ),
            child: SearchField(
              controller: _search,
              hint: l10n.customerSearchListHint,
              onChanged: _onQueryChanged,
              onSubmitted: (value) =>
                  ref.read(customerQueryProvider.notifier).set(value.trim()),
            ),
          ),
          Expanded(
            child: AsyncView<CustomerPage>(
              value: customers,
              onRetry: () => ref.invalidate(customersProvider),
              builder: (context, page) {
                if (page.customers.isEmpty) {
                  return EmptyState(
                    title: l10n.noCustomers,
                    body: l10n.noCustomersBody,
                    icon: Icons.people_outline,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(customersProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 96),
                    itemCount: page.customers.length + (page.isCapped ? 1 : 0),
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: palette.hairline,
                      indent: Insets.gutter,
                    ),
                    itemBuilder: (context, i) {
                      if (i >= page.customers.length) {
                        return Padding(
                          padding: const EdgeInsets.all(Insets.s24),
                          child: Text(
                            l10n.customerSearchListHint,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: palette.muted),
                          ),
                        );
                      }
                      return _CustomerRow(customer: page.customers[i]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerRow extends ConsumerWidget {
  const _CustomerRow({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final money = ref.watch(moneyProvider);

    return ListTile(
      // The walk-in customer has no ledger worth opening and cannot be edited
      // into anything; it is shown so the list matches the till, nothing more.
      onTap: customer.isWalkIn
          ? null
          : () => context.go('/customers/${customer.id}'),
      leading: CircleAvatar(
        backgroundColor: palette.surfaceAlt,
        child: Icon(
          customer.isWalkIn ? Icons.person_outline : Icons.person,
          color: palette.muted,
          size: 20,
        ),
      ),
      title: Text(customer.isWalkIn ? l10n.walkInCustomer : customer.name),
      subtitle: Text(
        [
          customer.phone ?? l10n.noPhone,
          l10n.salesCount(customer.saleCount),
        ].join(' · '),
        style: text.bodySmall?.copyWith(color: palette.muted),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (customer.due > 0)
            StatusChip(
              label: '${l10n.dueLabel} ${money.format(customer.due)}',
              tone: palette.warning,
            ),
          // Null means "not told" — a role without `customers.points.view`
          // gets no figure at all, which is different from a balance of zero.
          if (customer.loyaltyPoints != null &&
              customer.loyaltyPoints! > 0) ...[
            const SizedBox(height: Insets.s4),
            Text(
              l10n.pointsBalance(customer.loyaltyPoints!.toStringAsFixed(0)),
              style: text.labelSmall?.copyWith(color: palette.accent),
            ),
          ],
        ],
      ),
    );
  }
}
