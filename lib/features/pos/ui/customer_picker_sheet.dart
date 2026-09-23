import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/money.dart';
import '../../../core/permissions/permission_gate.dart';
import '../../../core/permissions/permissions.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/fields.dart';
import '../../../core/widgets/states.dart';
import '../../../l10n/app_localizations.dart';
import '../data/pos_models.dart';
import '../data/pos_repository.dart';

/// Picks the customer for a sale, and adds one on the spot.
///
/// `GET /customers/search` wants two characters and answers with at most eight,
/// phone first — which is exactly the shape of the question a cashier asks
/// ("zero one seven one..."). Under the results sits a quick-add, because the
/// most common answer at a counter is "they're new".
class CustomerPickerSheet extends ConsumerStatefulWidget {
  const CustomerPickerSheet({required this.lookups, this.selected, super.key});

  final PosLookups lookups;
  final PosCustomer? selected;

  /// Returns the chosen customer, or `_walkIn` to mean "nobody in particular".
  static Future<PosCustomer?> show(
    BuildContext context, {
    required PosLookups lookups,
    PosCustomer? selected,
  }) =>
      showAppSheet<PosCustomer?>(
        context,
        title: AppL10n.of(context).chooseCustomer,
        builder: (_) => CustomerPickerSheet(
          lookups: lookups,
          selected: selected,
        ),
      );

  @override
  ConsumerState<CustomerPickerSheet> createState() =>
      _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends ConsumerState<CustomerPickerSheet> {
  final _search = TextEditingController();
  Timer? _debounce;

  /// Empty means "show the recent list"; two characters or more is a search.
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  /// Typing a phone number is a burst of keystrokes; one request per digit
  /// would be eleven requests for one customer.
  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();

    if (query.length < 2) {
      if (_query.isNotEmpty) setState(() => _query = '');
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted && query != _query) setState(() => _query = query);
    });
  }

  /// Hands the chosen customer back, with their points filled in.
  ///
  /// The recent list comes from `GET /pos/lookups`, which does not carry
  /// `loyaltyPoints`; only `GET /customers/search` does. Without this, picking
  /// a regular off the recent list quietly hid the redemption that the very
  /// same person, found by typing their phone, would have been offered.
  Future<void> _pick(PosCustomer customer) async {
    if (customer.isWalkIn ||
        customer.loyaltyPoints != null ||
        !ref.read(permissionsProvider).has(P.customersPointsView)) {
      Navigator.of(context).pop(customer);
      return;
    }

    final navigator = Navigator.of(context);
    num? balance;
    try {
      balance = await ref.read(posRepositoryProvider).pointsBalance(customer.id);
    } catch (_) {
      // Not knowing the balance is not a reason to refuse the sale: the picker
      // returns the customer as it found them and the redeem row stays away.
    }
    if (!mounted) return;
    navigator.pop(
      balance == null
          ? customer
          : PosCustomer(
              id: customer.id,
              name: customer.name,
              phone: customer.phone,
              isWalkIn: customer.isWalkIn,
              creditLimit: customer.creditLimit,
              loyaltyPoints: balance,
              due: customer.due,
            ),
    );
  }

  Future<void> _quickAdd() async {
    final added = await QuickAddCustomerSheet.show(
      context,
      // Whatever is in the search box is usually the phone they just read out.
      seed: _search.text.trim(),
    );
    if (added != null && mounted) Navigator.of(context).pop(added);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final money = ref.watch(moneyProvider);
    final recent = widget.lookups.customers;
    final results =
        _query.isEmpty ? null : ref.watch(posCustomerSearchProvider(_query));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(Insets.gutter),
          child: SearchField(
            controller: _search,
            hint: l10n.customerSearchHint,
            autofocus: true,
            onChanged: _onQueryChanged,
          ),
        ),
        Flexible(
          child: results == null
              ? _RecentList(
                  customers: recent,
                  selected: widget.selected,
                  money: money,
                  onPick: _pick,
                )
              : AsyncView<List<PosCustomer>>(
                  value: results,
                  loading: const Padding(
                    padding: EdgeInsets.all(Insets.s32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  onRetry: () =>
                      ref.invalidate(posCustomerSearchProvider(_query)),
                  builder: (context, found) => found.isEmpty
                      ? EmptyState(
                          title: l10n.posNoResults,
                          icon: Icons.person_search_outlined,
                        )
                      : _RecentList(
                          customers: found,
                          selected: widget.selected,
                          money: money,
                          onPick: _pick,
                        ),
                ),
        ),
        Divider(color: palette.hairline, height: 1),
        SafeArea(
          top: false,
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.person_outline, color: palette.muted),
                title: Text(l10n.walkInCustomer),
                // Popping the walk-in customer means "no named customer" —
                // which is what clears credit and points from the cart.
                onTap: () => Navigator.of(context).pop(
                  widget.lookups.walkIn ??
                      const PosCustomer(id: 0, name: '', isWalkIn: true),
                ),
              ),
              PermissionGate(
                perm: P.customersCustomerCreate,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Insets.gutter,
                    0,
                    Insets.gutter,
                    Insets.gutter,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _quickAdd,
                      icon: const Icon(Icons.person_add_alt),
                      label: Text(l10n.quickAddCustomer),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecentList extends StatelessWidget {
  const _RecentList({
    required this.customers,
    required this.selected,
    required this.money,
    required this.onPick,
  });

  final List<PosCustomer> customers;
  final PosCustomer? selected;
  final Money money;
  final ValueChanged<PosCustomer> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;

    final named = customers.where((c) => !c.isWalkIn).toList();
    if (named.isEmpty) {
      return EmptyState(title: l10n.noCustomers, icon: Icons.people_outline);
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: named.length,
      itemBuilder: (context, i) {
        final customer = named[i];
        final isSelected = selected?.id == customer.id;

        return ListTile(
          selected: isSelected,
          selectedTileColor: palette.accentSoft,
          leading: CircleAvatar(
            backgroundColor: palette.surfaceAlt,
            child: Text(
              customer.name.isEmpty ? '?' : customer.name.characters.first,
              style: TextStyle(color: palette.text),
            ),
          ),
          title: Text(customer.name),
          subtitle: Text(customer.phone ?? l10n.noPhone),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Both are nullable on purpose: a due of null is "not told", a
              // due of zero is "owes nothing", and a cashier without
              // `customers.points.view` gets null points rather than a zero
              // that would read as "no points".
              if (customer.due != null && customer.due! > 0)
                StatusChip(
                  label: '${l10n.dueLabel} ${money.format(customer.due)}',
                  tone: palette.warning,
                ),
              if (customer.loyaltyPoints != null &&
                  customer.loyaltyPoints! > 0) ...[
                const SizedBox(height: Insets.s4),
                Text(
                  l10n.pointsBalance(
                    customer.loyaltyPoints!.toStringAsFixed(0),
                  ),
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: palette.muted),
                ),
              ],
            ],
          ),
          onTap: () => onPick(customer),
        );
      },
    );
  }
}

/// `POST /customers/quick` — a name and a phone, nothing else.
///
/// The interesting case is `created: false`: the phone was already on file, so
/// the server hands back *that* customer. Saying so out loud matters, because
/// the sale is about to be attached to a ledger the cashier did not create.
class QuickAddCustomerSheet extends ConsumerStatefulWidget {
  const QuickAddCustomerSheet({this.seed, super.key});

  final String? seed;

  static Future<PosCustomer?> show(BuildContext context, {String? seed}) =>
      showAppSheet<PosCustomer>(
        context,
        title: AppL10n.of(context).quickAddCustomer,
        builder: (_) => QuickAddCustomerSheet(seed: seed),
      );

  @override
  ConsumerState<QuickAddCustomerSheet> createState() =>
      _QuickAddCustomerSheetState();
}

class _QuickAddCustomerSheetState extends ConsumerState<QuickAddCustomerSheet> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final seed = widget.seed ?? '';
    // A seed made of digits is a phone number; anything else is a name.
    final isPhone = seed.isNotEmpty && RegExp(r'^[\d+\- ]+$').hasMatch(seed);
    _name = TextEditingController(text: isPhone ? '' : seed);
    _phone = TextEditingController(text: isPhone ? seed : '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    if (name.isEmpty || phone.isEmpty) return;

    setState(() => _busy = true);
    try {
      final result = await ref
          .read(posRepositoryProvider)
          .quickCustomer(name: name, phone: phone);

      if (!mounted) return;
      final l10n = AppL10n.of(context);
      showNote(
        context,
        result.created
            ? l10n.customerAdded(result.name)
            : l10n.customerExists(result.name),
      );
      Navigator.of(context).pop(result.toCustomer());
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
                  controller: _name,
                  autofocus: _name.text.isEmpty,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(labelText: l10n.customerName),
                ),
                const SizedBox(height: Insets.s16),
                TextField(
                  controller: _phone,
                  autofocus: _name.text.isNotEmpty,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(labelText: l10n.customerPhone),
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
