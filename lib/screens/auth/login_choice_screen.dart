import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/branding.dart';
import '../../providers/branding_provider.dart';
import '../../services/client_auth_service.dart';
import '../../theme.dart';
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (branding.logoUrl != null)
                  SizedBox(
                    height: 64,
                    child: Image.network(
                      branding.logoUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          _Wordmark(color: brand.defaultColor),
                    ),
                  )
                else
                  _Wordmark(color: brand.defaultColor),
                const SizedBox(height: 12),
                Text(
                  'Sign in to continue',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 48),
                _ChoiceButton(
                  label: 'User',
                  icon: Icons.work_outline,
                  onPressed: () => _go('user', const LoginScreen()),
                ),
                const SizedBox(height: 16),
                _ChoiceButton(
                  label: 'Client',
                  icon: Icons.person_outline,
                  onPressed: () => _go('client', const ClientEmailScreen()),
                ),
                const SizedBox(height: 16),
                _ChoiceButton(
                  label: 'Scan agent QR',
                  icon: Icons.qr_code_scanner,
                  onPressed: () => _go(
                    'client',
                    const ClientAgentQrScannerScreen(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _ChoiceButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  final Color color;
  const _Wordmark({required this.color});

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
