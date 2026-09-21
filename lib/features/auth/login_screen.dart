import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/env.dart';
import '../../core/network/api_exception.dart';
import '../../core/session/session_controller.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    // No retry here, ever: login is capped at 10 tries a minute and a loop
    // would lock the counter out.
    await ref.read(sessionControllerProvider.notifier).signIn(
          email: _email.text.trim(),
          password: _password.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final session = ref.watch(sessionControllerProvider);
    final busy = session.isLoading;

    return Scaffold(
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
                    Container(
                      height: 52,
                      width: 52,
                      decoration: BoxDecoration(
                        color: palette.accentSoft,
                        borderRadius: BorderRadius.circular(Radii.sheet),
                      ),
                      child: Icon(
                        Icons.storefront_outlined,
                        color: palette.accent,
                      ),
                    ),
                    const SizedBox(height: Insets.s24),
                    Text(l10n.signInTitle, style: text.headlineSmall),
                    const SizedBox(height: Insets.s4),
                    Text(l10n.signInSubtitle, style: text.bodySmall),
                    const SizedBox(height: Insets.s24),

                    if (session.hasError) ...[
                      _ErrorNotice(error: session.error!),
                      const SizedBox(height: Insets.s16),
                    ],

                    TextFormField(
                      controller: _email,
                      enabled: !busy,
                      decoration: InputDecoration(labelText: l10n.email),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.username],
                      // The server's own messages are bound below; this only
                      // catches an empty or obviously wrong address.
                      validator: (value) {
                        final v = value?.trim() ?? '';
                        if (v.isEmpty) return l10n.requiredField;
                        if (!v.contains('@')) return l10n.invalidEmail;
                        return _serverError(session, 'email');
                      },
                    ),
                    const SizedBox(height: Insets.s16),
                    TextFormField(
                      controller: _password,
                      enabled: !busy,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: l10n.password,
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
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => busy ? null : _submit(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.requiredField;
                        }
                        return _serverError(session, 'password');
                      },
                    ),
                    const SizedBox(height: Insets.s24),
                    FilledButton(
                      onPressed: busy ? null : _submit,
                      child: Text(busy ? l10n.signingIn : l10n.signIn),
                    ),
                    const SizedBox(height: Insets.s24),
                    // Which backend this build talks to. Invaluable while there
                    // is more than one, and harmless once there is not.
                    Text(
                      '${l10n.serverLabel}: ${Env.baseUrl}',
                      style: text.bodySmall,
                      textAlign: TextAlign.center,
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

  /// Binds `error.fields` from a 422 under the field it belongs to.
  String? _serverError(AsyncValue<Object?> session, String field) {
    final error = session.error;
    if (error is ValidationException) return error.first(field);
    return null;
  }
}

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);

    // A validation error is already shown under each field, so the banner only
    // carries what has nowhere else to go: wrong password, rate limit, offline.
    final message = switch (error) {
      ValidationException() => null,
      ApiException(:final message) => message,
      _ => l10n.genericError,
    };
    if (message == null) return const SizedBox.shrink();

    final isWarning = error is RateLimitedException;
    final tone = isWarning ? palette.warning : palette.danger;

    return Container(
      padding: const EdgeInsets.all(Insets.s12),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Radii.row),
        border: Border.all(color: tone.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isWarning ? Icons.timer_outlined : Icons.error_outline,
            size: 18,
            color: tone,
          ),
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
    );
  }
}
