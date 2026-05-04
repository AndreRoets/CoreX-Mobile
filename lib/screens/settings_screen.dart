import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/security_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _biometricSupported = false;

  @override
  void initState() {
    super.initState();
    SecurityService.instance.canUseBiometrics().then((v) {
      if (mounted) setState(() => _biometricSupported = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final auth = context.watch<AuthProvider>();
    final isDark = themeProvider.isDark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary(context)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appearance',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary(context),
              ),
            ),
            const SizedBox(height: 12),
            _SettingsCard(
              context: context,
              children: [
                _SettingsTile(
                  icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  label: 'Dark Mode',
                  trailing: Switch.adaptive(
                    value: isDark,
                    activeTrackColor: AppTheme.brand,
                    activeThumbColor: Colors.white,
                    onChanged: (_) => themeProvider.toggle(),
                  ),
                  context: context,
                ),
              ],
            ),

            const SizedBox(height: 24),
            Text(
              'Security',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary(context),
              ),
            ),
            const SizedBox(height: 12),
            _SettingsCard(
              context: context,
              children: [
                _SettingsTile(
                  icon: Icons.fingerprint_rounded,
                  label: _biometricSupported
                      ? 'Biometric sign-in'
                      : 'Biometrics not available',
                  trailing: Switch.adaptive(
                    value: auth.biometricEnabled,
                    activeTrackColor: AppTheme.brand,
                    activeThumbColor: Colors.white,
                    onChanged: _biometricSupported
                        ? (v) => context
                            .read<AuthProvider>()
                            .setBiometricEnabled(v)
                        : null,
                  ),
                  context: context,
                ),
              ],
            ),

            const SizedBox(height: 24),
            Text(
              'About',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary(context),
              ),
            ),
            const SizedBox(height: 12),
            _SettingsCard(
              context: context,
              children: [
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  label: 'Version',
                  trailing: Text(
                    '1.0.0',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textMuted(context),
                    ),
                  ),
                  context: context,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  final BuildContext context;

  const _SettingsCard({required this.children, required this.context});

  @override
  Widget build(BuildContext ctx) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;
  final BuildContext context;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.trailing,
    required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.brand),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary(context),
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
