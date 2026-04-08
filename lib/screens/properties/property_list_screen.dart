import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../models/property.dart';
import '../../providers/property_provider.dart';
import 'property_create_screen.dart';
import 'property_edit_screen.dart';

class PropertyListScreen extends StatefulWidget {
  const PropertyListScreen({super.key});

  @override
  State<PropertyListScreen> createState() => _PropertyListScreenState();
}

class _PropertyListScreenState extends State<PropertyListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PropertyProvider>().fetchProperties();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PropertyProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Properties')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.brand,
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PropertyCreateScreen()),
          );
          if (mounted) context.read<PropertyProvider>().fetchProperties();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: provider.isLoading && provider.properties.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.properties.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: provider.fetchProperties,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.properties.length,
                    itemBuilder: (context, index) =>
                        _PropertyCard(property: provider.properties[index]),
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.home_outlined, size: 64, color: AppTheme.textMuted(context)),
          const SizedBox(height: 16),
          Text('No properties yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary(context))),
          const SizedBox(height: 8),
          Text('Tap + to add your first property',
              style: TextStyle(color: AppTheme.textSecondary(context))),
        ],
      ),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  final Property property;
  const _PropertyCard({required this.property});

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'draft':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PropertyEditScreen(propertyId: property.id),
            ),
          );
          if (context.mounted) context.read<PropertyProvider>().fetchProperties();
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radius),
                child: property.thumbnail != null
                    ? Image.network(property.thumbnail!, width: 72, height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder())
                    : _placeholder(),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(property.address,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary(context),
                        )),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (property.beds != null) ...[
                          Icon(Icons.bed, size: 16, color: AppTheme.textSecondary(context)),
                          const SizedBox(width: 4),
                          Text('${property.beds}', style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13)),
                          const SizedBox(width: 12),
                        ],
                        if (property.baths != null) ...[
                          Icon(Icons.bathtub, size: 16, color: AppTheme.textSecondary(context)),
                          const SizedBox(width: 4),
                          Text('${property.baths}', style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13)),
                          const SizedBox(width: 12),
                        ],
                        if (property.garages != null) ...[
                          Icon(Icons.garage, size: 16, color: AppTheme.textSecondary(context)),
                          const SizedBox(width: 4),
                          Text('${property.garages}', style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Status chip + edit
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(property.status).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                    ),
                    child: Text(
                      property.status ?? 'N/A',
                      style: TextStyle(
                        color: _statusColor(property.status),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(Icons.edit, size: 18, color: AppTheme.textMuted(context)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 72, height: 72,
      decoration: BoxDecoration(
        color: AppTheme.darkSurface2,
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: const Icon(Icons.home, color: AppTheme.darkTextMuted),
    );
  }
}
