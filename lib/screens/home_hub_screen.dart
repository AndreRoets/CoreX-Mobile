import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/greeting_card.dart';
import '../widgets/collapse_menu.dart';
import '../widgets/wide_banner.dart';
import '../widgets/ui/section_header.dart';
import 'main_tabs_screen.dart';
import 'real_estate_hub_screen.dart';

class HomeHubScreen extends StatelessWidget {
  const HomeHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const CollapseMenu(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GreetingCard(userName: auth.userName),
                    const SizedBox(height: 28),
                    const SectionHeader(label: 'Quick Access'),
                    const SizedBox(height: 14),
                    WideBanner(
                      icon: Icons.dashboard_rounded,
                      label: 'Dashboard',
                      subtitle: 'Cockpit · Today',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const MainTabsScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    WideBanner(
                      icon: Icons.apartment_rounded,
                      label: 'Real Estate',
                      subtitle: 'Properties · Matches',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const RealEstateHubScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
