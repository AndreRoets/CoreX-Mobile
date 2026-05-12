import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/client_session_provider.dart';
import '../../providers/theme_provider.dart';
import '../../screens/auth/client/client_agency_picker_screen.dart';
import '../../screens/client/client_settings_screen.dart';
import '../../theme.dart';

class ClientCollapseMenu extends StatefulWidget {
  const ClientCollapseMenu({super.key});

  @override
  State<ClientCollapseMenu> createState() => _ClientCollapseMenuState();
}

class _ClientCollapseMenuState extends State<ClientCollapseMenu>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isOpen = !_isOpen);
    if (_isOpen) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<ClientSessionProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark;

    final name = session.contact?.fullName.isNotEmpty == true
        ? session.contact!.fullName
        : (session.client?.email ?? 'Client');
    final email = session.client?.email ?? '';
    final agency = session.currentAgency;
    final canSwitch = session.agencies.length > 1 &&
        session.client?.lockedToAgencyId == null;

    return Column(
      children: [
        GestureDetector(
          onTap: _toggle,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                AnimatedRotation(
                  turns: _isOpen ? 0.25 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.menu_rounded,
                    size: 24,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: canSwitch
                        ? () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const ClientAgencyPickerScreen(
                                        initialPick: false),
                              ),
                            )
                        : null,
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            agency?.name ?? 'CoreX',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary(context),
                            ),
                          ),
                        ),
                        if (canSwitch)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.expand_more,
                              size: 20,
                              color: AppTheme.textPrimary(context),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppTheme.brandDark,
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                  ),
                  child: Center(
                    child: Text(
                      _initials(name),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizeTransition(
          sizeFactor: _animation,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppTheme.surface(context),
              borderRadius: BorderRadius.circular(AppTheme.radius),
              border: Border.all(color: AppTheme.borderColor(context)),
            ),
            child: Column(
              children: [
                _MenuItem(
                  icon: Icons.person_rounded,
                  label: name,
                  subtitle: email,
                  onTap: _toggle,
                ),
                Divider(height: 1, color: AppTheme.borderColor(context)),
                _MenuItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  onTap: () {
                    _toggle();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ClientSettingsScreen(),
                      ),
                    );
                  },
                ),
                Divider(height: 1, color: AppTheme.borderColor(context)),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        isDark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        size: 20,
                        color: AppTheme.brand,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isDark ? 'Dark Mode' : 'Light Mode',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary(context),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => themeProvider.toggle(),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 48,
                          height: 28,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.brand
                                : AppTheme.darkTextMuted
                                    .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: AnimatedAlign(
                            duration: const Duration(milliseconds: 300),
                            alignment: isDark
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Icon(
                                isDark
                                    ? Icons.nightlight_round
                                    : Icons.wb_sunny_rounded,
                                size: 14,
                                color: isDark
                                    ? AppTheme.brand
                                    : const Color(0xFFF59E0B),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: AppTheme.borderColor(context)),
                _MenuItem(
                  icon: Icons.logout_rounded,
                  label: 'Sign Out',
                  iconColor: const Color(0xFFEF4444),
                  onTap: () {
                    _toggle();
                    session.signOut();
                  },
                ),
              ],
            ),
          ),
        ),
      ],
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

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radius),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor ?? AppTheme.brand),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppTheme.textMuted(context),
            ),
          ],
        ),
      ),
    );
  }
}
