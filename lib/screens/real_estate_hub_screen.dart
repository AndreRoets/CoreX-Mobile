import 'package:flutter/material.dart';
import '../widgets/wide_banner.dart';
import '../widgets/ui/section_header.dart';
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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(label: 'Browse'),
              const SizedBox(height: 14),
              WideBanner(
                icon: Icons.home_work_rounded,
                label: 'Properties',
                subtitle: 'Listings · Mandates',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const PropertyListScreen()),
                ),
              ),
              const SizedBox(height: 12),
              WideBanner(
                icon: Icons.people_alt_rounded,
                label: 'Contacts',
                subtitle: 'Buyers · Sellers · Leads',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const ContactsListScreen()),
                ),
              ),
              const SizedBox(height: 12),
              WideBanner(
                icon: Icons.favorite_rounded,
                label: 'Core Matches',
                subtitle: 'Buyer ↔ property fit',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const CoreMatchesListScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
