import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../providers/property_provider.dart';

class PropertyCreateScreen extends StatefulWidget {
  const PropertyCreateScreen({super.key});

  @override
  State<PropertyCreateScreen> createState() => _PropertyCreateScreenState();
}

class _PropertyCreateScreenState extends State<PropertyCreateScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  bool _saving = false;

  // Step 1 — Address
  final _streetNumber = TextEditingController();
  final _streetName = TextEditingController();
  final _complexName = TextEditingController();
  final _unitNumber = TextEditingController();
  final _suburb = TextEditingController();
  final _city = TextEditingController();

  // Step 2 — Details
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

  // Step 3 — Gallery
  static const _roomTags = [
    'Kitchen', 'Lounge', 'Bedroom 1', 'Bedroom 2', 'Bedroom 3',
    'Bathroom 1', 'Bathroom 2', 'Garden', 'Pool', 'Garage',
    'Exterior Front', 'Exterior Back', 'Other',
  ];
  final Map<String, File?> _images = {};

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

    final property = await provider.createProperty(data);

    if (property != null) {
      // Upload images
      for (final entry in _images.entries) {
        if (entry.value != null) {
          await provider.uploadImage(property.id, entry.value!, entry.key);
        }
      }
      if (mounted) Navigator.of(context).pop();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Failed to create property')),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Property')),
      body: Column(
        children: [
          // Step indicator
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
          _label('Street Number'),
          _field(_streetNumber),
          _label('Street Name'),
          _field(_streetName),
          _label('Complex Name (optional)'),
          _field(_complexName),
          _label('Unit Number (optional)'),
          _field(_unitNumber),
          _label('Suburb'),
          _field(_suburb),
          _label('City'),
          _field(_city),
          const SizedBox(height: 24),
          _nextButton(() => _goTo(1)),
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
          _label('Beds'),
          _stepper(_beds, (v) => setState(() => _beds = v)),
          _label('Baths'),
          _stepper(_baths, (v) => setState(() => _baths = v)),
          _label('Garages'),
          _stepper(_garages, (v) => setState(() => _garages = v)),
          _label('Property Type'),
          _dropdown(['Residential', 'Commercial', 'Industrial', 'Agricultural', 'Vacant Land'],
              _propertyType, (v) => setState(() => _propertyType = v)),
          _label('Category'),
          _dropdown(['House', 'Apartment', 'Townhouse', 'Simplex', 'Duplex', 'Farm', 'Plot', 'Other'],
              _category, (v) => setState(() => _category = v)),
          _label('Listing Type'),
          _dropdown(['For Sale', 'To Let'],
              _listingType, (v) => setState(() => _listingType = v)),
          _label('Price'),
          _field(_price, keyboard: TextInputType.number),
          _label('Description'),
          _field(_description, maxLines: 4),
          _label('Features'),
          _featureInput(),
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
          _nextButton(() => _goTo(2)),
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
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Property'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roomSection(String tag) {
    final file = _images[tag];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tag, style: TextStyle(
            fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context))),
          const SizedBox(height: 8),
          if (file != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  child: Image.file(file, width: 120, height: 90, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 4, right: 4,
                  child: GestureDetector(
                    onTap: () => setState(() => _images.remove(tag)),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54, shape: BoxShape.circle),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            )
          else
            OutlinedButton.icon(
              onPressed: () => _pickImage(tag),
              icon: const Icon(Icons.add_a_photo, size: 16),
              label: const Text('Add Photo'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.brand,
                side: BorderSide(color: AppTheme.darkSurface2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radius)),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickImage(String tag) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _images[tag] = File(picked.path));
    }
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
      initialValue: value,
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

  Widget _nextButton(VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity, height: 48,
      child: ElevatedButton(onPressed: onPressed, child: const Text('Next')),
    );
  }
}
