import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/feature_square.dart';
import 'contacts/contacts_list_screen.dart';
import 'core_matches/core_matches_list_screen.dart';
import 'properties/property_list_screen.dart';

class RealEstateHubScreen extends StatelessWidget {
  const RealEstateHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Real Estate')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Real Estate',
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
                    icon: Icons.home_work_rounded,
                    label: 'Properties',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const PropertyListScreen()),
                    ),
                  ),
                  FeatureSquare(
                    icon: Icons.people_alt_rounded,
                    label: 'Contacts',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const ContactsListScreen()),
                    ),
                  ),
                  FeatureSquare(
                    icon: Icons.favorite_rounded,
                    label: 'Core Matches',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const CoreMatchesListScreen()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
