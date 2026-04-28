import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../models/property.dart';
import '../../providers/property_provider.dart';
import 'property_create_screen.dart';
import 'property_edit_screen.dart';
import 'property_overview_screen.dart';

class PropertyListScreen extends StatefulWidget {
  const PropertyListScreen({super.key});

  @override
  State<PropertyListScreen> createState() => _PropertyListScreenState();
}

class _PropertyListScreenState extends State<PropertyListScreen> {
  final _searchController = TextEditingController();
  String _search = '';

  // Filter state — null means "any".
  String? _suburbFilter;
  String? _listingTypeFilter;
  String? _statusFilter;
  int? _minPrice;
  int? _maxPrice;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PropertyProvider>().fetchProperties();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get _activeFilterCount {
    var n = 0;
    if (_suburbFilter != null) n++;
    if (_listingTypeFilter != null) n++;
    if (_statusFilter != null) n++;
    if (_minPrice != null || _maxPrice != null) n++;
    return n;
  }

  List<Property> _applyFilters(List<Property> input) {
    final q = _search.trim().toLowerCase();
    return input.where((p) {
      if (q.isNotEmpty && !p.address.toLowerCase().contains(q)) {
        return false;
      }
      if (_suburbFilter != null && p.suburb != _suburbFilter) {
        return false;
      }
      if (_listingTypeFilter != null && p.listingType != _listingTypeFilter) {
        return false;
      }
      if (_statusFilter != null && p.status != _statusFilter) {
        return false;
      }
      if (_minPrice != null && (p.price == null || p.price! < _minPrice!)) {
        return false;
      }
      if (_maxPrice != null && (p.price == null || p.price! > _maxPrice!)) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Unique, sorted non-null values of [selector] across the currently-loaded
  /// properties. Used to populate filter chips dynamically — no dependency
  /// on the options endpoint, works with whatever the list actually has.
  List<String> _uniqueValues(
      List<Property> input, String? Function(Property) selector) {
    final set = <String>{};
    for (final p in input) {
      final v = selector(p);
      if (v != null && v.isNotEmpty) set.add(v);
    }
    final list = set.toList()..sort();
    return list;
  }

  void _clearFilters() {
    setState(() {
      _suburbFilter = null;
      _listingTypeFilter = null;
      _statusFilter = null;
      _minPrice = null;
      _maxPrice = null;
    });
  }

  Future<void> _openFilterSheet(List<Property> all) async {
    // Capture the currently-loaded list so the sheet's chip options are
    // stable while the sheet is open.
    final suburbs = _uniqueValues(all, (p) => p.suburb);
    final listingTypes = _uniqueValues(all, (p) => p.listingType);
    final statuses = _uniqueValues(all, (p) => p.status);

    // Seed the sheet with the current state and commit on Apply.
    String? suburb = _suburbFilter;
    String? listingType = _listingTypeFilter;
    String? status = _statusFilter;
    final minCtrl = TextEditingController(
        text: _minPrice != null ? _minPrice.toString() : '');
    final maxCtrl = TextEditingController(
        text: _maxPrice != null ? _maxPrice.toString() : '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(builder: (ctx, setSheet) {
          return DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (_, scrollCtrl) => Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Filters',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary(context),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setSheet(() {
                            suburb = null;
                            listingType = null;
                            status = null;
                            minCtrl.clear();
                            maxCtrl.clear();
                          });
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollCtrl,
                      children: [
                        if (suburbs.isNotEmpty) ...[
                          _sectionLabel('Suburb'),
                          _chipGroup(
                            options: suburbs,
                            selected: suburb,
                            onSelected: (v) => setSheet(() => suburb = v),
                          ),
                          const SizedBox(height: 16),
                        ],
                        _sectionLabel('Price'),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: minCtrl,
                                keyboardType: TextInputType.number,
                                decoration:
                                    const InputDecoration(labelText: 'Min'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: maxCtrl,
                                keyboardType: TextInputType.number,
                                decoration:
                                    const InputDecoration(labelText: 'Max'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (listingTypes.isNotEmpty) ...[
                          _sectionLabel('Listing Type'),
                          _chipGroup(
                            options: listingTypes,
                            selected: listingType,
                            onSelected: (v) =>
                                setSheet(() => listingType = v),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (statuses.isNotEmpty) ...[
                          _sectionLabel('Status'),
                          _chipGroup(
                            options: statuses,
                            selected: status,
                            onSelected: (v) => setSheet(() => status = v),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _suburbFilter = suburb;
                          _listingTypeFilter = listingType;
                          _statusFilter = status;
                          _minPrice = int.tryParse(minCtrl.text.trim());
                          _maxPrice = int.tryParse(maxCtrl.text.trim());
                        });
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 6),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary(context),
          ),
        ),
      );

  Widget _chipGroup({
    required List<String> options,
    required String? selected,
    required ValueChanged<String?> onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final isSelected = o == selected;
        return ChoiceChip(
          label: Text(o),
          selected: isSelected,
          onSelected: (_) => onSelected(isSelected ? null : o),
          backgroundColor: AppTheme.surface2(context),
          selectedColor: AppTheme.brand,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textPrimary(context),
          ),
          side: BorderSide.none,
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PropertyProvider>();
    final all = provider.properties;
    final filtered = _applyFilters(all);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Properties'),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                tooltip: 'Filters',
                onPressed: () => _openFilterSheet(all),
              ),
              if (_activeFilterCount > 0)
                Positioned(
                  top: 8,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1),
                    decoration: const BoxDecoration(
                      color: AppTheme.brand,
                      shape: BoxShape.circle,
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$_activeFilterCount',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search by address',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _search = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.surface(context),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  borderSide: BorderSide(color: AppTheme.borderColor(context)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  borderSide: BorderSide(color: AppTheme.borderColor(context)),
                ),
              ),
            ),
          ),
          if (_activeFilterCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Text(
                    '${filtered.length} of ${all.length} match',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary(context),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.close, size: 14),
                    label: const Text('Clear filters'),
                    style:
                        TextButton.styleFrom(foregroundColor: AppTheme.brand),
                    onPressed: _clearFilters,
                  ),
                ],
              ),
            ),
          Expanded(
            child: provider.isLoading && all.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : all.isEmpty
                    ? _buildEmpty()
                    : filtered.isEmpty
                        ? _buildNoMatches()
                        : RefreshIndicator(
                            onRefresh: provider.fetchProperties,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) =>
                                  _PropertyCard(property: filtered[index]),
                            ),
                          ),
          ),
        ],
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

  Widget _buildNoMatches() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off,
              size: 48, color: AppTheme.textMuted(context)),
          const SizedBox(height: 12),
          Text(
            'No properties match',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary(context)),
          ),
          const SizedBox(height: 4),
          Text(
            'Try a different search or clear the filters',
            style: TextStyle(
                fontSize: 12, color: AppTheme.textSecondary(context)),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              _searchController.clear();
              setState(() => _search = '');
              _clearFilters();
            },
            child: const Text('Clear all'),
          ),
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
          // Listed properties open the read-first Overview; drafts (or
          // anything without a status set yet) jump straight to Edit so the
          // agent can finish capturing.
          final isDraft = (property.status ?? '').toLowerCase() == 'draft' ||
              (property.status ?? '').isEmpty;
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => isDraft
                  ? PropertyEditScreen(propertyId: property.id)
                  : PropertyOverviewScreen(propertyId: property.id),
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
                        errorBuilder: (_, __, ___) => _placeholder(context))
                    : _placeholder(context),
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

  Widget _placeholder(BuildContext context) {
    return Container(
      width: 72, height: 72,
      decoration: BoxDecoration(
        color: AppTheme.surface2(context),
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Icon(Icons.home, color: AppTheme.textMuted(context)),
    );
  }
}
