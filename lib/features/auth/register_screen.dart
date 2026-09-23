import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/session/session_controller.dart';
import '../../core/session/signup_models.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';

/// `GET /public/store-types`, for the sign-up form and for opening a second
/// shop from inside. Needs no token.
final signupOptionsProvider = FutureProvider<SignupOptions>(
  (ref) => ref.watch(authApiProvider).signupOptions(),
);

/// A shop signing itself up: `POST /auth/register`.
///
/// One screen, no second step. The reply carries a working token, so a
/// successful sign-up lands in the new shop's till, and nothing needs setting
/// up first — the server provisions the branch, the cash and bKash accounts,
/// the walk-in customer and the settings the till reads.
///
/// The two `409`s point in different directions. A known **email** is an
/// account that has to prove itself before it gets a second shop, so it is
/// sent to sign in (and then to "Open another shop" inside). A known **phone**
/// belonging to somebody else is a question for the platform, so its message
/// is shown as it is.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _shop = TextEditingController();
  final _owner = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _address = TextEditingController();
  final _branch = TextEditingController();

  int? _storeTypeId;
  bool _obscure = true;
  bool _busy = false;

  Map<String, List<String>> _fieldErrors = const {};
  Object? _error;

  @override
  void dispose() {
    for (final c in [
      _shop,
      _owner,
      _email,
      _phone,
      _password,
      _address,
      _branch,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _optional(TextEditingController c) {
    final v = c.text.trim();
    return v.isEmpty ? null : v;
  }

  String? _server(String field) {
    final messages = _fieldErrors[field];
    return (messages == null || messages.isEmpty) ? null : messages.first;
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _fieldErrors = const {};
      _error = null;
    });
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _busy = true);
    try {
      // On success the session changes and the router takes this screen away.
      await ref.read(sessionControllerProvider.notifier).register(
            name: _shop.text.trim(),
            storeTypeId: _storeTypeId!,
            ownerName: _owner.text.trim(),
            email: _email.text.trim(),
            phone: _phone.text.trim(),
            password: _password.text,
            address: _optional(_address),
            branchName: _optional(_branch),
          );
    } on ValidationException catch (e) {
      if (mounted) {
        setState(() => _fieldErrors = e.fields);
        _form.currentState!.validate();
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final options = ref.watch(signupOptionsProvider);
    final locale = Localizations.localeOf(context).languageCode;

    final conflict = _error is ConflictException
        ? _error! as ConflictException
        : null;
    final signInInstead = conflict?.code == 'sign_in_to_add_store';

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/login')),
        title: Text(l10n.registerTitle),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Insets.s24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l10n.registerSubtitle, style: text.bodyMedium),
                    if ((options.value?.trialDays ?? 0) > 0) ...[
                      const SizedBox(height: Insets.s8),
                      Text(
                        l10n.registerTrialNote(options.value!.trialDays),
                        style: text.bodySmall?.copyWith(color: palette.muted),
                      ),
                    ],
                    const SizedBox(height: Insets.s24),

                    if (_error != null) ...[
                      _Notice(
                        message: switch (_error) {
                          final ConflictException c => c.messageFor(locale),
                          final ApiException e => e.message,
                          _ => l10n.genericError,
                        },
                        action: signInInstead
                            ? TextButton(
                                onPressed: () => context.go(
                                  Uri(
                                    path: '/login',
                                    queryParameters: {
                                      'email': _email.text.trim(),
                                    },
                                  ).toString(),
                                ),
                                child: Text(l10n.signInInstead),
                              )
                            : null,
                      ),
                      const SizedBox(height: Insets.s16),
                    ],

                    Text(l10n.registerShopSection, style: text.titleSmall),
                    const SizedBox(height: Insets.s12),
                    TextFormField(
                      controller: _shop,
                      enabled: !_busy,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(labelText: l10n.shopName),
                      validator: (v) => (v ?? '').trim().isEmpty
                          ? l10n.requiredField
                          : _server('name'),
                    ),
                    const SizedBox(height: Insets.s16),
                    options.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => _Notice(
                        message: e is ApiException ? e.message : l10n.genericError,
                        action: TextButton(
                          onPressed: () =>
                              ref.invalidate(signupOptionsProvider),
                          child: Text(l10n.retry),
                        ),
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
                      controller: _address,
                      enabled: !_busy,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l10n.shopAddressOptional,
                      ),
                    ),
                    const SizedBox(height: Insets.s16),
                    TextFormField(
                      controller: _branch,
                      enabled: !_busy,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l10n.branchNameOptional,
                        hintText: l10n.branchNameHint,
                      ),
                    ),

                    const SizedBox(height: Insets.s24),
                    Text(l10n.registerOwnerSection, style: text.titleSmall),
                    const SizedBox(height: Insets.s12),
                    TextFormField(
                      controller: _owner,
                      enabled: !_busy,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      decoration: InputDecoration(labelText: l10n.ownerName),
                      validator: (v) => (v ?? '').trim().isEmpty
                          ? l10n.requiredField
                          : _server('ownerName'),
                    ),
                    const SizedBox(height: Insets.s16),
                    TextFormField(
                      controller: _phone,
                      enabled: !_busy,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      decoration: InputDecoration(
                        labelText: l10n.phone,
                        helperText: l10n.shopPhoneHelp,
                      ),
                      validator: (v) {
                        final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                        if (digits.isEmpty) return l10n.requiredField;
                        if (digits.length < 10) return l10n.invalidPhone;
                        if (conflict?.on == 'phone') {
                          return conflict!.messageFor(locale);
                        }
                        return _server('phone');
                      },
                    ),
                    const SizedBox(height: Insets.s16),
                    TextFormField(
                      controller: _email,
                      enabled: !_busy,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(labelText: l10n.email),
                      validator: (v) {
                        final value = (v ?? '').trim();
                        if (value.isEmpty) return l10n.requiredField;
                        if (!value.contains('@')) return l10n.invalidEmail;
                        return _server('email');
                      },
                    ),
                    const SizedBox(height: Insets.s16),
                    TextFormField(
                      controller: _password,
                      enabled: !_busy,
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: l10n.password,
                        helperText: l10n.passwordRule,
                        suffixIcon: IconButton(
                          tooltip: _obscure
                              ? l10n.showPassword
                              : l10n.hidePassword,
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) {
                        if ((v ?? '').length < 6) return l10n.passwordRule;
                        return _server('password');
                      },
                    ),
                    const SizedBox(height: Insets.s24),
                    FilledButton(
                      onPressed: _busy || !options.hasValue ? null : _submit,
                      child: Text(
                        _busy ? l10n.registering : l10n.registerAction,
                      ),
                    ),
                    const SizedBox(height: Insets.s12),
                    TextButton(
                      onPressed: _busy ? null : () => context.go('/login'),
                      child: Text(l10n.haveAccount),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The kind of shop. Shared with "Open another shop".
class StoreTypeField extends StatelessWidget {
  const StoreTypeField({
    required this.types,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.serverError,
    super.key,
  });

  final List<StoreType> types;
  final int? value;
  final ValueChanged<int?> onChanged;
  final bool enabled;
  final String? serverError;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return DropdownButtonFormField<int>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l10n.storeTypeLabel,
        helperText: l10n.storeTypeHelp,
      ),
      items: [
        for (final type in types)
          DropdownMenuItem(value: type.id, child: Text(type.name)),
      ],
      onChanged: enabled ? onChanged : null,
      validator: (v) => v == null ? l10n.requiredField : serverError,
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message, this.action});

  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tone = palette.warning;

    return Container(
      padding: const EdgeInsets.all(Insets.s12),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Radii.row),
        border: Border.all(color: tone.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 18, color: tone),
              const SizedBox(width: Insets.s8),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: palette.text),
                ),
              ),
            ],
          ),
          if (action != null)
            Align(alignment: AlignmentDirectional.centerEnd, child: action),
        ],
      ),
    );
  }
}
