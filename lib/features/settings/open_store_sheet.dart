import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/session/session_controller.dart';
import '../../core/session/signup_models.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/states.dart';
import '../auth/register_screen.dart';
import '../../l10n/app_localizations.dart';

/// `GET /stores` — the shops this account may work in, with the one the
/// platform has closed named separately.
final ownedStoresProvider = FutureProvider.autoDispose<StoreList>((ref) {
  ref.watch(sessionScopeProvider);
  return ref.watch(authApiProvider).stores();
});

/// `POST /stores`, then `POST /auth/switch-store` into it.
///
/// Open to anyone signed in, whatever they are in the current shop: the person
/// doing this may be a cashier here, or — on the morning a trial ended — in no
/// shop at all. No password travels; the account already proved itself by
/// signing in, which is why a known email is sent here rather than being
/// allowed to sign up again.
class OpenStoreSheet extends ConsumerStatefulWidget {
  const OpenStoreSheet({super.key});

  static Future<void> show(BuildContext context) => showAppSheet<void>(
        context,
        title: AppL10n.of(context).openAnotherShop,
        builder: (_) => const OpenStoreSheet(),
      );

  @override
  ConsumerState<OpenStoreSheet> createState() => _OpenStoreSheetState();
}

class _OpenStoreSheetState extends ConsumerState<OpenStoreSheet> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _branch = TextEditingController();
  int? _storeTypeId;
  bool _busy = false;
  Map<String, List<String>> _fieldErrors = const {};

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _branch.dispose();
    super.dispose();
  }

  String? _server(String field) {
    final messages = _fieldErrors[field];
    return (messages == null || messages.isEmpty) ? null : messages.first;
  }

  String? _optional(TextEditingController c) {
    final v = c.text.trim();
    return v.isEmpty ? null : v;
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _fieldErrors = const {});
    if (!_form.currentState!.validate()) return;

    setState(() => _busy = true);
    final l10n = AppL10n.of(context);
    final name = _name.text.trim();
    try {
      await ref.read(sessionControllerProvider.notifier).openStore(
            name: name,
            storeTypeId: _storeTypeId!,
            phone: _phone.text.trim(),
            address: _optional(_address),
            branchName: _optional(_branch),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      showNote(context, l10n.shopOpened(name));
    } on ValidationException catch (e) {
      if (mounted) {
        setState(() => _fieldErrors = e.fields);
        _form.currentState!.validate();
      }
    } on ConflictException catch (e) {
      // `duplicate_store`: nearly always a button pressed twice.
      if (mounted) {
        showApiError(
          context,
          ConflictException(
            e.messageFor(Localizations.localeOf(context).languageCode),
          ),
        );
      }
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final options = ref.watch(signupOptionsProvider);

    return Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(Insets.gutter),
              children: [
                if ((options.value?.trialDays ?? 0) > 0) ...[
                  Text(
                    l10n.openShopTrialNote(options.value!.trialDays),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: palette.muted),
                  ),
                  const SizedBox(height: Insets.s16),
                ],
                TextFormField(
                  controller: _name,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(labelText: l10n.shopName),
                  validator: (v) => (v ?? '').trim().isEmpty
                      ? l10n.requiredField
                      : _server('name'),
                ),
                const SizedBox(height: Insets.s16),
                options.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => ErrorView(
                    error: e,
                    onRetry: () => ref.invalidate(signupOptionsProvider),
                  ),
                  data: (data) => StoreTypeField(
                    types: data.storeTypes,
                    value: _storeTypeId,
                    enabled: !_busy,
                    serverError: _server('storeTypeId'),
                    onChanged: (id) => setState(() => _storeTypeId = id),
                  ),
                ),
                const SizedBox(height: Insets.s16),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: l10n.phone,
                    helperText: l10n.shopPhoneHelp,
                  ),
                  validator: (v) {
                    final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                    if (digits.isEmpty) return l10n.requiredField;
                    if (digits.length < 10) return l10n.invalidPhone;
                    return _server('phone');
                  },
                ),
                const SizedBox(height: Insets.s16),
                TextFormField(
                  controller: _address,
                  decoration: InputDecoration(
                    labelText: l10n.shopAddressOptional,
                  ),
                ),
                const SizedBox(height: Insets.s16),
                TextFormField(
                  controller: _branch,
                  decoration: InputDecoration(
                    labelText: l10n.branchNameOptional,
                    hintText: l10n.branchNameHint,
                  ),
                ),
              ],
            ),
          ),
          SheetAction(
            label: l10n.openShopAction,
            icon: Icons.add_business_outlined,
            busy: _busy,
            onPressed: options.hasValue ? _save : null,
          ),
        ],
      ),
    );
  }
}
