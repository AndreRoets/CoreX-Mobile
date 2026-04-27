import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/greeting_card.dart';
import '../widgets/feature_square.dart';
import '../widgets/collapse_menu.dart';
import 'main_tabs_screen.dart';
import 'properties/property_list_screen.dart';

class HomeHubScreen extends StatelessWidget {
  const HomeHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Collapse menu at top
            const CollapseMenu(),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting card
                    GreetingCard(userName: auth.userName),

                    const SizedBox(height: 24),

                    // Section header
                    Text(
                      'Quick Access',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Feature squares grid
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        FeatureSquare(
                          icon: Icons.dashboard_rounded,
                          label: 'Dashboard',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const MainTabsScreen(),
                              ),
                            );
                          },
                        ),
                        FeatureSquare(
                          icon: Icons.home_work_rounded,
                          label: 'Properties',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const PropertyListScreen(),
                              ),
                            );
                          },
                        ),
                      ],
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
