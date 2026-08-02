import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
    required this.authenticatedBuilder,
  });

  final bool isDark;
  final VoidCallback onToggleTheme;
  final WidgetBuilder authenticatedBuilder;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Session? _session;
  late final StreamSubscription<AuthState> _subscription;
  var _registerMode = false;

  @override
  void initState() {
    super.initState();
    _session = Supabase.instance.client.auth.currentSession;
    _subscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (state) {
        if (mounted) setState(() => _session = state.session);
      },
      onError: (Object _) {
        if (mounted) setState(() => _session = null);
      },
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_session != null) return widget.authenticatedBuilder(context);
    return AuthPage(
      isDark: widget.isDark,
      registerMode: _registerMode,
      onToggleTheme: widget.onToggleTheme,
      onToggleMode: () => setState(() => _registerMode = !_registerMode),
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({
    super.key,
    required this.isDark,
    required this.registerMode,
    required this.onToggleTheme,
    required this.onToggleMode,
  });

  final bool isDark;
  final bool registerMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleMode;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  var _obscure = true;
  var _loading = false;
  String? _error;

  @override
  void didUpdateWidget(covariant AuthPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.registerMode != widget.registerMode) {
      _formKey.currentState?.reset();
      _confirmation.clear();
      _error = null;
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (widget.registerMode) {
        final response = await Supabase.instance.client.auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
        );
        if (!mounted) return;
        if (response.session == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '\u0110\u0103ng k\u00fd th\u00e0nh c\u00f4ng. H\u00e3y ki\u1ec3m tra email \u0111\u1ec3 x\u00e1c nh\u1eadn t\u00e0i kho\u1ea3n.',
              ),
            ),
          );
          widget.onToggleMode();
        }
      } else {
        await Supabase.instance.client.auth.signInWithPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = _friendlyAuthError(error));
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Kh\u00f4ng th\u1ec3 k\u1ebft n\u1ed1i Supabase. H\u00e3y ki\u1ec3m tra m\u1ea1ng r\u1ed3i th\u1eed l\u1ea1i.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
        ? null
        : 'H\u00e3y nh\u1eadp email h\u1ee3p l\u1ec7.';
  }

  @override
  Widget build(BuildContext context) {
    final registering = widget.registerMode;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: widget.isDark
                ? const [
                    Color(0xFF211C38),
                    Color(0xFF302552),
                    Color(0xFF193D42),
                  ]
                : const [
                    Color(0xFFEDE8FF),
                    Color(0xFFFFF0EB),
                    Color(0xFFE6FAF2),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned(
                top: -55,
                left: -35,
                child: _AuthBubble(size: 150, color: Color(0x557566E8)),
              ),
              const Positioned(
                right: -45,
                bottom: 35,
                child: _AuthBubble(size: 180, color: Color(0x44FF9AA2)),
              ),
              Positioned(
                right: 12,
                top: 8,
                child: IconButton.filledTonal(
                  tooltip: widget.isDark
                      ? 'Chuy\u1ec3n sang n\u1ec1n s\u00e1ng'
                      : 'Chuy\u1ec3n sang n\u1ec1n t\u1ed1i',
                  onPressed: widget.onToggleTheme,
                  icon: Icon(
                    widget.isDark
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                  ),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 66, 20, 28),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFF7566E8), Color(0xFFFF8FA3)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x337566E8),
                                blurRadius: 24,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 38,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'H\u01b0\u1edbng nghi\u1ec7p AI',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 22),
                        Card(
                          elevation: 0,
                          color: widget.isDark
                              ? const Color(0xE62C2744)
                              : const Color(0xF7FFFFFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                            side: BorderSide(
                              color: widget.isDark
                                  ? const Color(0x22FFFFFF)
                                  : const Color(0x227566E8),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    registering
                                        ? 'T\u1ea1o t\u00e0i kho\u1ea3n'
                                        : '\u0110\u0103ng nh\u1eadp',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    registering
                                        ? 'B\u1eaft \u0111\u1ea7u h\u00e0nh tr\u00ecnh t\u00ecm ng\u00e0nh h\u1ecdc ph\u00f9 h\u1ee3p.'
                                        : 'Ch\u00e0o m\u1eebng b\u1ea1n quay l\u1ea1i!',
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 22),
                                  _AuthField(
                                    controller: _email,
                                    label: 'Email',
                                    icon: Icons.alternate_email_rounded,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: _validateEmail,
                                  ),
                                  const SizedBox(height: 14),
                                  _AuthField(
                                    controller: _password,
                                    label: 'M\u1eadt kh\u1ea9u',
                                    icon: Icons.lock_outline_rounded,
                                    obscureText: _obscure,
                                    suffixIcon: IconButton(
                                      tooltip: _obscure
                                          ? 'Hi\u1ec7n m\u1eadt kh\u1ea9u'
                                          : '\u1ea8n m\u1eadt kh\u1ea9u',
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                      icon: Icon(
                                        _obscure
                                            ? Icons.visibility_rounded
                                            : Icons.visibility_off_rounded,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'H\u00e3y nh\u1eadp m\u1eadt kh\u1ea9u.';
                                      }
                                      if (registering && value.length < 6) {
                                        return 'M\u1eadt kh\u1ea9u c\u1ea7n \u00edt nh\u1ea5t 6 k\u00fd t\u1ef1.';
                                      }
                                      return null;
                                    },
                                  ),
                                  if (registering) ...[
                                    const SizedBox(height: 14),
                                    _AuthField(
                                      controller: _confirmation,
                                      label:
                                          'X\u00e1c nh\u1eadn m\u1eadt kh\u1ea9u',
                                      icon: Icons.verified_user_outlined,
                                      obscureText: _obscure,
                                      textInputAction: TextInputAction.done,
                                      onSubmitted: (_) => _submit(),
                                      validator: (value) =>
                                          value != _password.text
                                          ? 'M\u1eadt kh\u1ea9u x\u00e1c nh\u1eadn ch\u01b0a kh\u1edbp.'
                                          : null,
                                    ),
                                  ],
                                  if (_error != null) ...[
                                    const SizedBox(height: 14),
                                    _AuthError(message: _error!),
                                  ],
                                  const SizedBox(height: 22),
                                  FilledButton.icon(
                                    onPressed: _loading ? null : _submit,
                                    icon: _loading
                                        ? const SizedBox.square(
                                            dimension: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.4,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Icon(
                                            registering
                                                ? Icons.person_add_alt_1_rounded
                                                : Icons.login_rounded,
                                          ),
                                    label: Text(
                                      _loading
                                          ? '\u0110ang x\u1eed l\u00fd...'
                                          : registering
                                          ? '\u0110\u0103ng k\u00fd'
                                          : '\u0110\u0103ng nh\u1eadp',
                                    ),
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size.fromHeight(52),
                                      backgroundColor: const Color(0xFF7566E8),
                                      foregroundColor: Colors.white,
                                      textStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: _loading
                                        ? null
                                        : widget.onToggleMode,
                                    child: Text(
                                      registering
                                          ? '\u0110\u00e3 c\u00f3 t\u00e0i kho\u1ea3n? \u0110\u0103ng nh\u1eadp'
                                          : 'Ch\u01b0a c\u00f3 t\u00e0i kho\u1ea3n? \u0110\u0103ng k\u00fd',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.suffixIcon,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final FormFieldValidator<String> validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _AuthError extends StatelessWidget {
  const _AuthError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFD94D66);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: color),
          const SizedBox(width: 9),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _AuthBubble extends StatelessWidget {
  const _AuthBubble({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

String _friendlyAuthError(AuthException error) {
  final message = error.message.toLowerCase();
  if (message.contains('invalid login credentials')) {
    return 'Email ho\u1eb7c m\u1eadt kh\u1ea9u ch\u01b0a \u0111\u00fang.';
  }
  if (message.contains('email not confirmed')) {
    return 'Email ch\u01b0a \u0111\u01b0\u1ee3c x\u00e1c nh\u1eadn. H\u00e3y ki\u1ec3m tra h\u1ed9p th\u01b0.';
  }
  if (message.contains('already registered') ||
      message.contains('already exists')) {
    return 'Email n\u00e0y \u0111\u00e3 c\u00f3 t\u00e0i kho\u1ea3n.';
  }
  if (message.contains('rate limit')) {
    return 'B\u1ea1n thao t\u00e1c qu\u00e1 nhanh. H\u00e3y ch\u1edd m\u1ed9t l\u00fac r\u1ed3i th\u1eed l\u1ea1i.';
  }
  return 'X\u00e1c th\u1ef1c ch\u01b0a th\u00e0nh c\u00f4ng. H\u00e3y ki\u1ec3m tra th\u00f4ng tin v\u00e0 th\u1eed l\u1ea1i.';
}
