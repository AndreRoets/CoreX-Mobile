import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/env.dart';
import '../models/branding.dart';
import '../theme.dart';
import '../providers/auth_provider.dart';
import '../providers/branding_provider.dart';
import '../services/security_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _biometricSupported = false;
  bool _autoTried = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final auth = context.read<AuthProvider>();
    // Pre-login: refresh agency branding so the login screen is themed
    // before the user signs in. Failure falls back silently.
    unawaited(context.read<BrandingProvider>().loadBySlug(Env.agencySlug));
    final saved = await auth.readSavedCredentials();
    final supported = await SecurityService.instance.canUseBiometrics();
    if (!mounted) return;
    setState(() {
      _emailController.text = saved.email;
      _passwordController.text = saved.password;
      _biometricSupported = supported;
    });

    // Locked-but-authenticated user with biometrics on → auto-prompt once.
    if (!_autoTried && auth.isLocked && auth.biometricEnabled && supported) {
      _autoTried = true;
      await auth.unlockWithBiometrics();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();

    // If we're locked and the prefilled creds match what's saved, just
    // unlock locally — no need to re-hit the API.
    if (auth.isLocked) {
      auth.lockSession(); // no-op if not locked
    }

    final ok = await auth.login(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (!mounted) return;
    if (ok) {
      // Pull /v1/logged-user so post-login branding overrides pre-login.
      unawaited(
        context
            .read<BrandingProvider>()
            .loadFromLoggedUser(profile: auth.user),
      );
    }
    if (ok && auth.needsBiometricSetupPrompt) {
      await _askEnableBiometrics();
    }
  }

  Future<void> _askEnableBiometrics() async {
    final auth = context.read<AuthProvider>();
    final enable = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Enable biometric sign-in?'),
            content: const Text(
              'Use this device’s fingerprint or face unlock to sign in '
              'next time, instead of typing your password.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Not now'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Enable'),
              ),
            ],
          ),
        ) ??
        false;
    await auth.consumeBiometricSetupPrompt(enable: enable);
  }

  Future<void> _handleBiometric() async {
    final auth = context.read<AuthProvider>();
    if (auth.isLocked) {
      await auth.unlockWithBiometrics();
      return;
    }
    // Cold path (rare — token cleared but creds still in vault): biometric
    // success → re-login with stored credentials.
    final ok = await SecurityService.instance.authenticate(
      reason: 'Sign in to CoreX',
    );
    if (!ok) return;
    final saved = await auth.readSavedCredentials();
    if (saved.email.isEmpty || saved.password.isEmpty) return;
    await auth.login(saved.email, saved.password);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final branding = context.watch<BrandingProvider>().branding;
    final brand = BrandColors.of(context);
    final showBiometric = _biometricSupported && auth.biometricEnabled;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (branding.logoUrl != null) ...[
                    SizedBox(
                      height: 64,
                      child: Image.network(
                        branding.logoUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => _BrandWordmark(color: brand.defaultColor),
                      ),
                    ),
                  ] else
                    _BrandWordmark(color: brand.defaultColor),
                  const SizedBox(height: 8),
                  Text(
                    auth.isLocked ? 'Session locked' : 'Home Finders Coastal',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.username, AutofillHints.email],
                    style: TextStyle(color: AppTheme.textPrimary(context)),
                    decoration: const InputDecoration(hintText: 'Email'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Enter your email' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    style: TextStyle(color: AppTheme.textPrimary(context)),
                    decoration: const InputDecoration(hintText: 'Password'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Enter your password' : null,
                  ),
                  if (auth.error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      auth.error!,
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: auth.isLoading ? null : _handleLogin,
                    child: auth.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Login'),
                  ),
                  if (showBiometric) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: auth.isLoading ? null : _handleBiometric,
                      icon: const Icon(Icons.fingerprint_rounded),
                      label: const Text('Use biometrics'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandWordmark extends StatelessWidget {
  final Color color;
  const _BrandWordmark({required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      'CoreX OS',
      style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
    );
  }
}
