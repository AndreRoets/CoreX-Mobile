import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../utils/display_text.dart';
import '../widgets/ui/content_width.dart';
import '../main.dart';
import '../models/branding.dart';
import '../theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'agent_details_screen.dart';
import 'delete_account_screen.dart';
import '../widgets/corex/corex_bottom_nav.dart';
import '../widgets/ui/section_header.dart';
import '../widgets/ui/status_chip.dart';

/// The Me tab: who you're signed in as, a door to the editable agent details
/// ([AgentDetailsScreen]), and the sign-out / delete actions. Kept short on
/// purpose so Sign out is never a form's worth of scrolling away.
class ProfileScreen extends StatelessWidget {
  /// True when opened from the "Me" tab, which keeps the bottom nav visible so
  /// the user can hop straight to another tab. Pushes from the drawer or the
  /// home avatar leave it off and rely on the back button.
  final bool showNav;

  /// Test seam, handed on to [AgentDetailsScreen]; production uses a fresh
  /// [ApiService].
  final ApiService? api;

  const ProfileScreen({super.key, this.showNav = false, this.api});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final brand = BrandColors.of(context);
    final email = user?['email']?.toString() ?? '';
    // The session payload now carries a server-cased `role_label`; older
    // backends only send the `role` slug, which gets title-cased instead.
    final roleLabel = user?['role_label']?.toString().trim().isNotEmpty == true
        ? user!['role_label'].toString().trim()
        : titleCaseLabel(user?['role']?.toString());

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      bottomNavigationBar: showNav
          ? CorexBottomNav(
              active: CorexNavTab.me,
              onTap: (tab) => corexNavigateTo(context, tab, CorexNavTab.me),
            )
          : null,
      body: ContentSafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: brand.defaultColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: AppTheme.brandGlow(brand.button, intensity: 0.3),
                  ),
                  child: Center(
                    child: Text(
                      _initials(auth.userName),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: Branding.onColor(brand.defaultColor),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                auth.userName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: AppTheme.textPrimary(context),
                ),
              ),
              if (roleLabel.isNotEmpty) ...[
                const SizedBox(height: 6),
                Center(
                  child: StatusChip(
                    key: const ValueKey('profile-role-label'),
                    label: roleLabel,
                    color: brand.button,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                email,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary(context),
                ),
              ),
              const SizedBox(height: 32),
              const SectionHeader(label: 'Account'),
              const SizedBox(height: 12),
              _InfoCard(items: [
                _InfoRow(label: 'Name', value: auth.userName),
                _InfoRow(label: 'Email', value: email.isEmpty ? '-' : email),
                _InfoRow(
                    label: 'Role',
                    value: roleLabel.isEmpty ? '-' : roleLabel),
              ]),
              const SizedBox(height: 16),
              _AgentDetailsTile(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AgentDetailsScreen(api: api),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _SignOutButton(onPressed: () => logoutAndReset(context)),
              const SizedBox(height: 8),
              // App Store guideline 5.1.1(v): account deletion has to be
              // reachable from inside the app. It sits under Sign out —
              // separate, quieter, and unmistakably its own action — so it
              // can't be mistaken for the everyday way to leave.
              _DeleteAccountButton(
                onPressed: () => startAccountDeletion(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2 && parts.first.isNotEmpty && parts.last.isNotEmpty) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

/// Card-styled row that opens the agent details form. Same surface as the
/// Account card above it so the two read as one group.
class _AgentDetailsTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AgentDetailsTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final brand = BrandColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('profile-agent-details'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: AppTheme.cardGradient(context),
            borderRadius: BorderRadius.circular(AppTheme.radius),
            boxShadow: AppTheme.softShadow(context),
          ),
          child: Row(
            children: [
              Icon(TablerIcons.id_badge_2, size: 22, color: brand.icon),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Agent details',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'FFC number, cell, WhatsApp, social links and your '
                      'public agent page',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMuted(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(TablerIcons.chevron_right,
                  size: 20, color: AppTheme.textMuted(context)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});
}

class _SignOutButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _SignOutButton({required this.onPressed});

  static const _danger = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(TablerIcons.logout, size: 20, color: _danger),
        label: const Text(
          'Sign out',
          style: TextStyle(
            color: _danger,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: _danger.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radius),
          ),
        ),
      ),
    );
  }
}

/// Deliberately a plain text button, not a second outlined block: it has to be
/// clearly findable (App Review looks for it) without competing with Sign out,
/// which is the action people actually want ninety-nine times out of a hundred.
class _DeleteAccountButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _DeleteAccountButton({required this.onPressed});

  static const _danger = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(TablerIcons.trash, size: 18, color: _danger),
        label: const Text(
          'Delete my account',
          style: TextStyle(
            color: _danger,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<_InfoRow> items;
  const _InfoCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient(context),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        boxShadow: AppTheme.softShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(
                    height: 1, color: AppTheme.borderColor(context)),
              ),
            Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    items[i].label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted(context),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    items[i].value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
