import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/branding.dart';
import '../../providers/branding_provider.dart';
import '../../services/client_auth_service.dart';
import '../../theme.dart';
import '../../widgets/ui/glow_background.dart';
import '../../widgets/ui/glow_button.dart';
import '../login_screen.dart';
import 'client/client_agent_qr_scanner_screen.dart';
import 'client/client_email_screen.dart';

// Top-level entry: two centered buttons — User vs Client. Picking one
// navigates to the full sign-in flow for that path. Last choice is
// remembered so it's offered first next launch (visually highlighted),
// but the user can still pick the other path on every launch.
class LoginChoiceScreen extends StatefulWidget {
  const LoginChoiceScreen({super.key});

  @override
  State<LoginChoiceScreen> createState() => _LoginChoiceScreenState();
}

class _LoginChoiceScreenState extends State<LoginChoiceScreen> {
  final _api = ClientAuthService();

  Future<void> _go(String path, Widget screen) async {
    await _api.setLastPath(path);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final branding = context.watch<BrandingProvider>().branding;
    final brand = BrandColors.of(context);

    return Scaffold(
      body: GlowBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _LogoMark(
                      logoUrl: branding.logoUrl,
                      tint: brand.button,
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'CoreX OS',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'SIGN IN TO CONTINUE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.0,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                    const SizedBox(height: 40),
                    GlowButton(
                      icon: Icons.work_outline_rounded,
                      onPressed: () => _go('user', const LoginScreen()),
                      child: const Text('Log in as User'),
                    ),
                    const SizedBox(height: 14),
                    SoftButton(
                      icon: Icons.person_outline_rounded,
                      onPressed: () => _go('client', const ClientEmailScreen()),
                      child: const Text('Log in as Client'),
                    ),
                    const SizedBox(height: 24),
                    TextButton.icon(
                      onPressed: () => _go(
                        'client',
                        const ClientAgentQrScannerScreen(),
                      ),
                      icon: Icon(Icons.qr_code_scanner_rounded,
                          size: 18, color: AppTheme.textSecondary(context)),
                      label: Text(
                        'Scan agent QR',
                        style: TextStyle(
                          color: AppTheme.textSecondary(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

class _CorexAssetLogo extends StatelessWidget {
  const _CorexAssetLogo();

  @override
  Widget build(BuildContext context) =>
      Image.asset('assets/images/corex_logo.png', fit: BoxFit.contain);
}

class _LogoMark extends StatelessWidget {
  final String? logoUrl;
  final Color tint;

  const _LogoMark({required this.logoUrl, required this.tint});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.brandGlow(tint, intensity: 0.28, blur: 36),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: logoUrl != null
            ? Image.network(
                logoUrl!,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const _CorexAssetLogo(),
              )
            : const _CorexAssetLogo(),
      ),
    );
  }
}
