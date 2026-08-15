import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:haptic_kit/haptic_kit.dart';

import '../../core/layout/breakpoints.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../state/auth_provider.dart';
import '../../state/haptics_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../core/l10n/enum_labels.dart';

/// Combined sign-in / create-account screen.
///
/// One screen with a toggle rather than two: the fields overlap almost
/// entirely, and switching shouldn't lose what's already typed.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, this.startOnSignUp = false});

  final bool startOnSignUp;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  late bool _signUp = widget.startOnSignUp;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final AuthNotifier auth = ref.read(authProvider.notifier);
    try {
      if (_signUp) {
        await auth.signUp(
          name: _name.text,
          email: _email.text,
          password: _password.text,
          confirmPassword: _confirm.text,
        );
      } else {
        await auth.signIn(email: _email.text, password: _password.text);
      }

      unawaited(
        ref.read(hapticsProvider).notification(HapticNotificationStyle.success),
      );
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(Routes.home);
      }
    } on AuthException catch (e) {
      unawaited(
        ref.read(hapticsProvider).notification(HapticNotificationStyle.error),
      );
      if (mounted) {
        setState(() => _error = e.error.messageIn(AppL10n.of(context)));
      }
    }
  }

  /// Takes the shopper into the shop without an account.
  Future<void> _browseAsGuest() async {
    await ref.read(guestModeProvider.notifier).browseAsGuest();
    if (mounted) context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AuthState auth = ref.watch(authProvider);
    final bool wide = Breakpoints.of(context).isAtLeastMedium;

    // This screen is the app's front door until the gate is cleared. Reached
    // from Profile afterwards, it's an ordinary pushed page with a back arrow.
    final bool isGate = !ref.watch(pastAuthGateProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_signUp ? 'Create account' : 'Sign in')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: wide ? 460 : double.infinity),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            children: <Widget>[
              Icon(
                Icons.auto_awesome_rounded,
                size: 40,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 14),
              Text(
                _signUp ? 'Join Nova' : 'Welcome back',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                _signUp
                    ? 'An account keeps your orders and details together.'
                    : 'Sign in to pick up where you left off.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 26),

              Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    if (_signUp) ...<Widget>[
                      TextFormField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        autofillHints: const <String>[AutofillHints.name],
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (String? v) => (v?.trim().isEmpty ?? true)
                            ? AuthError.nameRequired.messageIn(
                                AppL10n.of(context),
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const <String>[AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.alternate_email_rounded),
                      ),
                      validator: (String? v) =>
                          AuthNotifier.isValidEmail(v ?? '')
                          ? null
                          : AuthError.emailInvalid.messageIn(
                              AppL10n.of(context),
                            ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      textInputAction: _signUp
                          ? TextInputAction.next
                          : TextInputAction.done,
                      autofillHints: <String>[
                        _signUp
                            ? AutofillHints.newPassword
                            : AutofillHints.password,
                      ],
                      onFieldSubmitted: (_) {
                        if (!_signUp) _submit();
                      },
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          tooltip: _obscure ? 'Show' : 'Hide',
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (String? v) {
                        if (!_signUp) {
                          return (v?.isEmpty ?? true)
                              ? 'Enter your password'
                              : null;
                        }
                        return AuthNotifier.validatePassword(
                          v ?? '',
                        )?.messageIn(AppL10n.of(context));
                      },
                    ),
                    if (_signUp) ...<Widget>[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirm,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(
                          labelText: 'Confirm password',
                          prefixIcon: Icon(Icons.lock_reset_rounded),
                        ),
                        validator: (String? v) => v == _password.text
                            ? null
                            : AuthError.passwordMismatch.messageIn(
                                AppL10n.of(context),
                              ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'At least 8 characters.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (_error != null) ...<Widget>[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.error_outline_rounded,
                        size: 18,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _error!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 22),
              FilledButton(
                onPressed: auth.busy ? null : _submit,
                child: auth.busy
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : Text(_signUp ? 'Create account' : 'Sign in'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: auth.busy
                    ? null
                    : () => setState(() {
                        _signUp = !_signUp;
                        _error = null;
                      }),
                child: Text(
                  _signUp
                      ? 'Already have an account? Sign in'
                      : 'New to Nova? Create an account',
                ),
              ),

              // Only on the way in. Once you're past the gate there's nothing
              // left to skip, and Profile already offers to sign you out.
              if (isGate) ...<Widget>[
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'or',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: auth.busy ? null : _browseAsGuest,
                  icon: const Icon(Icons.storefront_outlined, size: 19),
                  label: const Text('Browse as guest'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Everything works without an account. You can sign in later '
                  'from Profile.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],

              const SizedBox(height: 24),
              const _LocalAccountNotice(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Says plainly what this is. People reuse passwords, and they deserve to know
/// there's no service behind this one.
class _LocalAccountNotice extends StatelessWidget {
  const _LocalAccountNotice();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.45,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'This account exists only on this device — there is no server, '
              'no email verification and no password recovery. Please don’t '
              'reuse a password you use anywhere real.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
