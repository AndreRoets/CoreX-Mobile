import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../providers/property_provider.dart';

class PropertyEditScreen extends StatefulWidget {
  final int propertyId;
  const PropertyEditScreen({super.key, required this.propertyId});

  @override
  State<PropertyEditScreen> createState() => _PropertyEditScreenState();
}

class _PropertyEditScreenState extends State<PropertyEditScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  bool _saving = false;
  bool _loaded = false;

  final _streetNumber = TextEditingController();
  final _streetName = TextEditingController();
  final _complexName = TextEditingController();
  final _unitNumber = TextEditingController();
  final _suburb = TextEditingController();
  final _city = TextEditingController();

  int _beds = 0;
  int _baths = 0;
  int _garages = 0;
  String? _propertyType;
  String? _category;
  String? _listingType;
  final _price = TextEditingController();
  final _description = TextEditingController();
  final List<String> _features = [];
  final _featureController = TextEditingController();

  static const _roomTags = [
    'Kitchen', 'Lounge', 'Bedroom 1', 'Bedroom 2', 'Bedroom 3',
    'Bathroom 1', 'Bathroom 2', 'Garden', 'Pool', 'Garage',
    'Exterior Front', 'Exterior Back', 'Other',
  ];

  Map<String, List<String>> _existingImages = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProperty();
    });
  }

  Future<void> _loadProperty() async {
    final provider = context.read<PropertyProvider>();
    await provider.fetchProperty(widget.propertyId);
    final p = provider.selectedProperty;
    if (p != null && mounted) {
      setState(() {
        _streetNumber.text = p.streetNumber ?? '';
        _streetName.text = p.streetName ?? '';
        _complexName.text = p.complexName ?? '';
        _unitNumber.text = p.unitNumber ?? '';
        _suburb.text = p.suburb ?? '';
        _city.text = p.city ?? '';
        _beds = p.beds ?? 0;
        _baths = p.baths ?? 0;
        _garages = p.garages ?? 0;
        _propertyType = p.propertyType;
        _category = p.category;
        _listingType = p.listingType;
        _price.text = p.price?.toString() ?? '';
        _description.text = p.description ?? '';
        _features.clear();
        _features.addAll(p.features);
        // Parse gallery categories
        if (p.galleryCategories != null) {
          final cats = p.galleryCategories!['categories'];
          if (cats is Map<String, dynamic>) {
            _existingImages = cats.map((k, v) =>
                MapEntry(k, List<String>.from(v is List ? v : [])));
          }
        }
        _loaded = true;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _streetNumber.dispose();
    _streetName.dispose();
    _complexName.dispose();
    _unitNumber.dispose();
    _suburb.dispose();
    _city.dispose();
    _price.dispose();
    _description.dispose();
    _featureController.dispose();
    super.dispose();
  }

  void _goTo(int step) {
    _pageController.animateToPage(step,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    setState(() => _currentStep = step);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final provider = context.read<PropertyProvider>();
    final data = {
      'street_number': _streetNumber.text,
      'street_name': _streetName.text,
      'complex_name': _complexName.text,
      'unit_number': _unitNumber.text,
      'suburb': _suburb.text,
      'city': _city.text,
      'beds': _beds,
      'baths': _baths,
      'garages': _garages,
      if (_propertyType != null) 'property_type': _propertyType,
      if (_category != null) 'category': _category,
      if (_listingType != null) 'listing_type': _listingType,
      if (_price.text.isNotEmpty) 'price': int.tryParse(_price.text),
      'description': _description.text,
      'features': _features,
    };

    final ok = await provider.updateProperty(widget.propertyId, data);
    if (mounted) {
      if (ok) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Failed to save')),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _uploadNewImage(String tag) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;

    setState(() => _saving = true);
    final provider = context.read<PropertyProvider>();
    final ok = await provider.uploadImage(widget.propertyId, File(picked.path), tag);
    if (ok && mounted) {
      await _loadProperty();
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PropertyProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Property')),
      body: !_loaded && provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    children: List.generate(3, (i) {
                      final active = i <= _currentStep;
                      return Expanded(
                        child: Container(
                          height: 4,
                          margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                          decoration: BoxDecoration(
                            color: active ? AppTheme.brand : AppTheme.darkSurface2,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [_stepAddress(), _stepDetails(), _stepGallery()],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _stepAddress() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Street Number'), _field(_streetNumber),
          _label('Street Name'), _field(_streetName),
          _label('Complex Name (optional)'), _field(_complexName),
          _label('Unit Number (optional)'), _field(_unitNumber),
          _label('Suburb'), _field(_suburb),
          _label('City'), _field(_city),
          const SizedBox(height: 24),
          _navButton('Next', () => _goTo(1)),
        ],
      ),
    );
  }

  Widget _stepDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Beds'), _stepper(_beds, (v) => setState(() => _beds = v)),
          _label('Baths'), _stepper(_baths, (v) => setState(() => _baths = v)),
          _label('Garages'), _stepper(_garages, (v) => setState(() => _garages = v)),
          _label('Property Type'),
          _dropdown(['Residential', 'Commercial', 'Industrial', 'Agricultural', 'Vacant Land'],
              _propertyType, (v) => setState(() => _propertyType = v)),
          _label('Category'),
          _dropdown(['House', 'Apartment', 'Townhouse', 'Simplex', 'Duplex', 'Farm', 'Plot', 'Other'],
              _category, (v) => setState(() => _category = v)),
          _label('Listing Type'),
          _dropdown(['For Sale', 'To Let'],
              _listingType, (v) => setState(() => _listingType = v)),
          _label('Price'), _field(_price, keyboard: TextInputType.number),
          _label('Description'), _field(_description, maxLines: 4),
          _label('Features'), _featureInput(),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _features.map((f) => Chip(
              label: Text(f),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () => setState(() => _features.remove(f)),
              backgroundColor: AppTheme.darkSurface2,
              labelStyle: TextStyle(color: AppTheme.textPrimary(context)),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius)),
            )).toList(),
          ),
          const SizedBox(height: 24),
          _navButton('Next', () => _goTo(2)),
        ],
      ),
    );
  }

  Widget _stepGallery() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._roomTags.map((tag) => _roomSection(tag)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roomSection(String tag) {
    final existing = _existingImages[tag] ?? [];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tag, style: TextStyle(
              fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context))),
          const SizedBox(height: 8),
          if (existing.isNotEmpty)
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: existing.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  child: Image.network(existing[i], width: 120, height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 120, height: 90, color: AppTheme.darkSurface2,
                        child: const Icon(Icons.broken_image, color: AppTheme.darkTextMuted),
                      )),
                ),
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _saving ? null : () => _uploadNewImage(tag),
            icon: const Icon(Icons.add_a_photo, size: 16),
            label: const Text('Add Photo'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.brand,
              side: const BorderSide(color: AppTheme.darkSurface2),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radius)),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Shared widgets ----

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 6),
    child: Text(text, style: TextStyle(
        fontSize: 13, fontWeight: FontWeight.w500,
        color: AppTheme.textSecondary(context))),
  );

  Widget _field(TextEditingController c, {TextInputType? keyboard, int maxLines = 1}) =>
      TextField(controller: c, keyboardType: keyboard, maxLines: maxLines);

  Widget _dropdown(List<String> items, String? value, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: items.contains(value) ? value : null,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      dropdownColor: AppTheme.darkSurface,
      decoration: const InputDecoration(),
    );
  }

  Widget _stepper(int value, ValueChanged<int> onChanged) {
    return Row(
      children: [
        IconButton(
          onPressed: value > 0 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
          color: AppTheme.brand,
        ),
        SizedBox(
          width: 32,
          child: Text('$value', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary(context))),
        ),
        IconButton(
          onPressed: () => onChanged(value + 1),
          icon: const Icon(Icons.add_circle_outline),
          color: AppTheme.brand,
        ),
      ],
    );
  }

  Widget _featureInput() {
    return TextField(
      controller: _featureController,
      decoration: InputDecoration(
        hintText: 'Type a feature and press enter',
        suffixIcon: IconButton(
          icon: const Icon(Icons.add, color: AppTheme.brand),
          onPressed: _addFeature,
        ),
      ),
      onSubmitted: (_) => _addFeature(),
    );
  }

  void _addFeature() {
    final text = _featureController.text.trim();
    if (text.isNotEmpty) {
      setState(() => _features.add(text));
      _featureController.clear();
    }
  }

  Widget _navButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity, height: 48,
      child: ElevatedButton(onPressed: onPressed, child: Text(label)),
    );
  }
}
