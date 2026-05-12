import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/client_session_provider.dart';
import '../../theme.dart';
import '../../widgets/client/client_collapse_menu.dart';
import '../../widgets/feature_square.dart';
import '../../widgets/greeting_card.dart';
import 'client_matches_list_screen.dart';

class ClientHomeScreen extends StatelessWidget {
  const ClientHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<ClientSessionProvider>();
    final name = session.contact?.fullName.isNotEmpty == true
        ? session.contact!.fullName
        : (session.client?.email.split('@').first ?? 'there');

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ClientCollapseMenu(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GreetingCard(userName: name),
                    const SizedBox(height: 24),
                    Text(
                      'Quick Access',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        FeatureSquare(
                          icon: Icons.favorite_rounded,
                          label: 'Core Matches',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const ClientMatchesListScreen(),
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
