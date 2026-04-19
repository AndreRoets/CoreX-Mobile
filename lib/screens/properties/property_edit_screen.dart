import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/gallery_tags.dart';
import '../../models/property_options.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import '../../providers/property_provider.dart';
import 'gallery_upload_sheet.dart';
import 'property_option_dropdown.dart';
import 'spaces_editor_section.dart';

class PropertyEditScreen extends StatefulWidget {
  final int propertyId;
  const PropertyEditScreen({super.key, required this.propertyId});

  @override
  State<PropertyEditScreen> createState() => _PropertyEditScreenState();
}

class _PropertyEditScreenState extends State<PropertyEditScreen> {
  final _pageController = PageController();
  final _spacesKey = GlobalKey<SpacesEditorSectionState>();
  int _currentStep = 0;
  bool _saving = false;
  bool _savingSpaces = false;
  bool _loaded = false;

  final _streetNumber = TextEditingController();
  final _streetName = TextEditingController();
  final _complexName = TextEditingController();
  final _unitNumber = TextEditingController();
  final _suburb = TextEditingController();
  final _city = TextEditingController();
  final _province = TextEditingController();
  final _region = TextEditingController();
  final _district = TextEditingController();

  final _title = TextEditingController();
  String? _propertyType;
  String? _category;
  String? _listingType;
  String? _status;
  String? _mandateType;
  final _price = TextEditingController();
  final _excerpt = TextEditingController();
  final _description = TextEditingController();
  // Rental
  final _rentalAmount = TextEditingController();
  final _depositAmount = TextEditingController();
  final _leaseStart = TextEditingController();
  final _leaseEnd = TextEditingController();

  /// Snapshot of every field's initial value, captured the moment the
  /// property loads. Used to detect dirtiness and to compute the PATCH
  /// payload (only changed keys are sent on save).
  Map<String, dynamic> _initialValues = {};

  Map<String, String> _fieldErrors = {};

  PropertyOptions? _options;
  String? _optionsError;

  /// Existing gallery thumbnails keyed by tag. Mirrors the backend's
  /// `gallery_categories.categories` map. A key of `Unsorted` holds
  /// untagged photos.
  Map<String, List<String>> _existingImages = {};

  /// Live gallery tags for the property. Fetched directly from
  /// `/gallery/tags` so we don't depend on the detail endpoint actually
  /// including the `gallery_tags` field.
  GalleryTagsData? _liveTags;
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProperty();
      _loadOptions();
    });
  }

  Future<void> _loadOptions({bool forceRefresh = false}) async {
    try {
      final opts = await _api.getPropertyOptions(forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() {
        _options = opts;
        _optionsError = null;
        _applyOptionDefaults();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _optionsError =
          'Could not load dropdown options — pull to retry');
    }
  }

  /// Fill any unset dropdown with its server-specified default. Called
  /// after both `_loadProperty` and `_loadOptions` have landed, so the
  /// property's stored values take precedence over defaults.
  void _applyOptionDefaults() {
    final o = _options;
    if (o == null) return;
    _category ??= o.categories.defaultSubmit;
    _propertyType ??= o.propertyTypes.defaultSubmit;
    _status ??= o.statuses.defaultSubmit;
    _mandateType ??= o.mandateTypes.defaultSubmit;
    // Listing types have no is_default flag — spec says default to "sale".
    if (_listingType == null && o.listingTypes.isNotEmpty) {
      final sale = o.listingTypes.where((x) => x.submit == 'sale');
      _listingType =
          sale.isNotEmpty ? sale.first.submit : o.listingTypes.first.submit;
    }
  }

  Future<void> _loadGalleryTags() async {
    try {
      final tags = await _api.getGalleryTags(widget.propertyId);
      if (!mounted) return;
      setState(() => _liveTags = tags);
    } catch (_) {
      // Fall back to whatever was on the property detail — not fatal.
    }
  }

  Future<void> _loadProperty() async {
    final provider = context.read<PropertyProvider>();
    await provider.fetchProperty(widget.propertyId);
    // Fetch the tag list directly — the detail endpoint may not yet expose
    // `gallery_tags`, so we don't want to rely on it alone.
    await _loadGalleryTags();
    final p = provider.selectedProperty;
    if (p != null && mounted) {
      setState(() {
        _streetNumber.text = p.streetNumber ?? '';
        _streetName.text = p.streetName ?? '';
        _complexName.text = p.complexName ?? '';
        _unitNumber.text = p.unitNumber ?? '';
        _suburb.text = p.suburb ?? '';
        _city.text = p.city ?? '';
        _province.text = p.province ?? '';
        _region.text = p.region ?? '';
        _district.text = p.district ?? '';
        _title.text = p.title ?? '';
        _propertyType = p.propertyType;
        _category = p.category;
        _listingType = p.listingType;
        _status = p.status;
        _mandateType = p.mandateType;
        _price.text = p.price?.toString() ?? '';
        _excerpt.text = p.excerpt ?? '';
        _description.text = p.description ?? '';
        _rentalAmount.text = p.rentalAmount?.toString() ?? '';
        _depositAmount.text = p.depositAmount?.toString() ?? '';
        _leaseStart.text = p.leaseStartDate ?? '';
        _leaseEnd.text = p.leaseEndDate ?? '';
        // Options may have loaded first — fill in any gaps with defaults
        // without clobbering the property's stored values.
        _applyOptionDefaults();
        // Snapshot for dirty diff (after all values are set above).
        _initialValues = _captureSnapshot();
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
    _province.dispose();
    _region.dispose();
    _district.dispose();
    _title.dispose();
    _price.dispose();
    _excerpt.dispose();
    _description.dispose();
    _rentalAmount.dispose();
    _depositAmount.dispose();
    _leaseStart.dispose();
    _leaseEnd.dispose();
    super.dispose();
  }

  // ---- Field error helpers (mirror create screen) ----

  void _clearFieldError(String field) {
    if (_fieldErrors.containsKey(field)) {
      setState(() => _fieldErrors.remove(field));
    }
  }

  String? _errorFor(String field) => _fieldErrors[field];

  Widget _inlineFieldError(String message) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          message,
          style: TextStyle(fontSize: 11, color: Colors.red.shade400),
        ),
      );

  Widget _errorField({
    required TextEditingController controller,
    required String errorField,
    TextInputType? keyboard,
    int maxLines = 1,
    int? maxLength,
    String? hintText,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      maxLength: maxLength,
      decoration: InputDecoration(
        hintText: hintText,
        errorText: _errorFor(errorField),
        errorMaxLines: 2,
      ),
      onChanged: (_) => _clearFieldError(errorField),
    );
  }

  // ---- Dirty diff ----

  /// Snapshot of every editable field's submitted value as of the last
  /// successful load. Used to detect dirtiness and to compute the PATCH
  /// payload — only changed keys land in the body sent to the server.
  Map<String, dynamic> _captureSnapshot() {
    return _buildPayload(includeAll: true);
  }

  Map<String, dynamic> _buildPayload({bool includeAll = false}) {
    String? trimOrNull(TextEditingController c) {
      final t = c.text.trim();
      return t.isEmpty ? null : t;
    }

    int? intOrNull(TextEditingController c) {
      final t = c.text.trim();
      if (t.isEmpty) return null;
      return int.tryParse(t.replaceAll(RegExp(r'[^0-9-]'), ''));
    }

    final isRental = _listingType == 'rental';
    final all = <String, dynamic>{
      'title': trimOrNull(_title),
      'property_type': _propertyType,
      'listing_type': _listingType,
      'status': _status,
      'suburb': trimOrNull(_suburb),
      'price': intOrNull(_price),
      'street_number': trimOrNull(_streetNumber),
      'street_name': trimOrNull(_streetName),
      'complex_name': trimOrNull(_complexName),
      'unit_number': trimOrNull(_unitNumber),
      'city': trimOrNull(_city),
      'province': trimOrNull(_province),
      'region': trimOrNull(_region),
      'district': trimOrNull(_district),
      'category': _category,
      'mandate_type': _mandateType,
      'excerpt': trimOrNull(_excerpt),
      'description': trimOrNull(_description),
      'rental_amount': isRental ? intOrNull(_rentalAmount) : null,
      'deposit_amount': isRental ? intOrNull(_depositAmount) : null,
      'lease_start_date': isRental ? trimOrNull(_leaseStart) : null,
      'lease_end_date': isRental ? trimOrNull(_leaseEnd) : null,
    };

    if (includeAll) return all;

    // PATCH-style: only send keys whose value differs from the snapshot.
    final diff = <String, dynamic>{};
    all.forEach((k, v) {
      if (_initialValues[k] != v) diff[k] = v;
    });
    return diff;
  }

  bool get _isDirty => _buildPayload().isNotEmpty;

  void _goTo(int step) {
    _pageController.animateToPage(step,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    setState(() => _currentStep = step);
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    // Flush any unsaved space edits first — the Spaces step has its own
    // Save button, but if the user skipped it we still want their changes
    // to persist when they tap "Save Changes" here.
    final spacesOk = await _spacesKey.currentState?.saveIfDirty() ?? true;
    if (!mounted) return;
    if (!spacesOk) {
      setState(() => _saving = false);
      return;
    }

    final provider = context.read<PropertyProvider>();
    // PATCH-style: only send keys whose value has changed since load.
    final data = _buildPayload();
    if (data.isEmpty) {
      // Nothing to save on the property fields themselves; spaces may
      // already have been flushed above. Just close.
      setState(() => _saving = false);
      Navigator.of(context).pop();
      return;
    }

    final ok = await provider.updateProperty(widget.propertyId, data);
    if (mounted) {
      if (ok) {
        // Refresh snapshot so dirty becomes false again.
        setState(() {
          _fieldErrors = {};
          _initialValues = _captureSnapshot();
        });
        Navigator.of(context).pop();
      } else {
        setState(() {
          _fieldErrors = Map<String, String>.from(provider.fieldErrors);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Failed to save')),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _openUploadSheet({String? initialTag}) async {
    final uploaded = await GalleryUploadSheet.show(
      context,
      propertyId: widget.propertyId,
      initialTag: initialTag,
    );
    // Always refetch after the sheet closes — even a partial upload changes
    // tag_counts, and the spaces editor may have been invalidated from
    // under us while the sheet was open.
    if ((uploaded ?? false) && mounted) {
      await _loadProperty();
    }
  }

  /// System/AppBar back: step backwards through the wizard instead of
  /// exiting. Returns `false` from the [PopScope] callback when we
  /// consumed the back press, `true` (i.e. allow the pop) only when
  /// already on the first step.
  bool _handleBack() {
    if (_currentStep > 0) {
      _goTo(_currentStep - 1);
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PropertyProvider>();

    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Property'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Previous step',
            onPressed: () {
              if (_currentStep > 0) {
                _goTo(_currentStep - 1);
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Close',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        body: !_loaded && provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    children: List.generate(4, (i) {
                      final active = i <= _currentStep;
                      return Expanded(
                        child: Container(
                          height: 4,
                          margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
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
                    children: [
                      _stepAddress(),
                      _stepDetails(),
                      _stepSpaces(),
                      _stepGallery(),
                    ],
                  ),
                ),
              ],
            ),
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
          _label('Suburb'),
          _errorField(controller: _suburb, errorField: 'suburb'),
          _label('City'), _field(_city),
          _label('Province (optional)'), _field(_province),
          _label('District (optional)'), _field(_district),
          _label('Region (optional)'), _field(_region),
          const SizedBox(height: 24),
          _navButton('Next', () => _goTo(1)),
        ],
      ),
    );
  }

  Widget _stepDetails() {
    final o = _options ?? PropertyOptions.empty;
    final isRental = _listingType == 'rental';
    return RefreshIndicator(
      onRefresh: () => _loadOptions(forceRefresh: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_optionsError != null) _optionsErrorBanner(),
            _label('Listing Type'),
            _listingTypeSegmented(o),
            if (_errorFor('listing_type') != null)
              _inlineFieldError(_errorFor('listing_type')!),
            _label('Title'),
            _errorField(
              controller: _title,
              errorField: 'title',
              hintText: 'e.g. Stunning 4 Bed House in Uvongo',
            ),
            _label('Property Type'),
            PropertyOptionDropdown(
              options: o.propertyTypes,
              value: _propertyType,
              onChanged: (v) {
                setState(() => _propertyType = v);
                _clearFieldError('property_type');
              },
            ),
            if (_errorFor('property_type') != null)
              _inlineFieldError(_errorFor('property_type')!),
            _label('Property Status'),
            PropertyOptionDropdown(
              options: o.statuses,
              value: _status,
              onChanged: (v) {
                setState(() => _status = v);
                _clearFieldError('status');
              },
            ),
            if (_errorFor('status') != null)
              _inlineFieldError(_errorFor('status')!),
            _label('Price (R)'),
            _errorField(
              controller: _price,
              errorField: 'price',
              keyboard: TextInputType.number,
            ),
            _label('Category'),
            PropertyOptionDropdown(
              options: o.categories,
              value: _category,
              onChanged: (v) => setState(() => _category = v),
            ),
            _label('Mandate Type'),
            PropertyOptionDropdown(
              options: o.mandateTypes,
              value: _mandateType,
              onChanged: (v) => setState(() => _mandateType = v),
            ),
            _label('Excerpt (max 500 chars)'),
            _errorField(
              controller: _excerpt,
              errorField: 'excerpt',
              maxLines: 2,
              maxLength: 500,
            ),
            _label('Description'),
            _errorField(
              controller: _description,
              errorField: 'description',
              maxLines: 4,
            ),
            if (isRental) ...[
              const SizedBox(height: 16),
              Text(
                'Rental Details',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary(context)),
              ),
              _label('Rental Amount (R / month)'),
              _errorField(
                controller: _rentalAmount,
                errorField: 'rental_amount',
                keyboard: TextInputType.number,
              ),
              _label('Deposit Amount (R)'),
              _errorField(
                controller: _depositAmount,
                errorField: 'deposit_amount',
                keyboard: TextInputType.number,
              ),
              _label('Lease Start Date'),
              _dateField(_leaseStart, 'lease_start_date'),
              _label('Lease End Date'),
              _dateField(_leaseEnd, 'lease_end_date'),
            ],
            const SizedBox(height: 24),
            _navButton('Next', () => _goTo(2)),
          ],
        ),
      ),
    );
  }

  /// Listing Type rendered as a chip-based segmented control fed by
  /// `options.listingTypes`. Falls back to sale/rental when options
  /// haven't loaded yet so the field is usable offline.
  Widget _listingTypeSegmented(PropertyOptions o) {
    final items = o.listingTypes.isNotEmpty
        ? o.listingTypes
        : const [
            PropertyOption(display: 'For Sale', submit: 'sale'),
            PropertyOption(display: 'For Rental', submit: 'rental'),
          ];
    return Wrap(
      spacing: 8,
      children: items.map((opt) {
        final isSelected = _listingType == opt.submit;
        return ChoiceChip(
          label: Text(opt.display),
          selected: isSelected,
          onSelected: (_) {
            setState(() {
              _listingType = opt.submit;
              if (opt.submit != 'rental') {
                _rentalAmount.clear();
                _depositAmount.clear();
                _leaseStart.clear();
                _leaseEnd.clear();
              }
            });
            _clearFieldError('listing_type');
          },
          backgroundColor: AppTheme.darkSurface2,
          selectedColor: AppTheme.brand,
          labelStyle: TextStyle(
            color:
                isSelected ? Colors.white : AppTheme.textPrimary(context),
            fontWeight: FontWeight.w600,
          ),
          side: BorderSide.none,
        );
      }).toList(),
    );
  }

  Widget _dateField(TextEditingController c, String errorField) {
    return TextField(
      controller: c,
      readOnly: true,
      onTap: () async {
        DateTime? initial;
        if (c.text.isNotEmpty) {
          try {
            initial = DateTime.parse(c.text);
          } catch (_) {}
        }
        final picked = await showDatePicker(
          context: context,
          initialDate: initial ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          final iso =
              '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
          setState(() => c.text = iso);
          _clearFieldError(errorField);
        }
      },
      decoration: InputDecoration(
        hintText: 'YYYY-MM-DD',
        errorText: _errorFor(errorField),
        suffixIcon: const Icon(Icons.calendar_today, size: 18),
      ),
    );
  }

  Widget _optionsErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 18, color: Colors.orange.shade400),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _optionsError ?? '',
              style: TextStyle(
                  fontSize: 12, color: Colors.orange.shade400),
            ),
          ),
          TextButton(
            onPressed: () => _loadOptions(forceRefresh: true),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _stepSpaces() {
    return Column(
      children: [
        Expanded(
          child: SpacesEditorSection(
            key: _spacesKey,
            propertyId: widget.propertyId,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _savingSpaces ? null : _saveSpacesAndNext,
              child: _savingSpaces
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Next: Gallery'),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveSpacesAndNext() async {
    setState(() => _savingSpaces = true);
    final ok = await _spacesKey.currentState?.saveIfDirty() ?? true;
    if (!mounted) return;
    // Spaces just changed — the tag list may now include new entries.
    // Refresh before advancing so the Gallery step is accurate.
    if (ok) await _loadGalleryTags();
    if (!mounted) return;
    setState(() => _savingSpaces = false);
    if (ok) _goTo(3);
  }

  Widget _stepGallery() {
    // Groups to render = the property's live gallery_tags, in order, then any
    // extra keys in gallery_categories (e.g. "Unsorted") that aren't in the
    // tag list — that bucket holds untagged photos and any stale tags from
    // before a space was removed.
    final p = context.watch<PropertyProvider>().selectedProperty;
    // Prefer the dedicated /gallery/tags response; fall back to whatever
    // the detail endpoint carried.
    final liveTags = _liveTags?.availableTags.isNotEmpty == true
        ? _liveTags!.availableTags
        : (p?.galleryTags ?? const <String>[]);
    final extraKeys = _existingImages.keys
        .where((k) => !liveTags.contains(k))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Gallery',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary(context))),
              ),
              TextButton.icon(
                onPressed: _saving ? null : () => _openUploadSheet(),
                icon: const Icon(Icons.add_a_photo, size: 16),
                label: const Text('Upload'),
                style:
                    TextButton.styleFrom(foregroundColor: AppTheme.brand),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (liveTags.isEmpty && extraKeys.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'No photos yet. Add spaces first to unlock tags, or tap Upload to add untagged photos.',
                style: TextStyle(color: AppTheme.textSecondary(context)),
              ),
            )
          else ...[
            ...liveTags.map((tag) => _gallerySection(tag, isLive: true)),
            ...extraKeys.map((tag) => _gallerySection(tag, isLive: false)),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton(
              // Always allow Save here — even if no field-level diff, the
              // user might have queued space edits we still need to flush.
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_isDirty ? 'Save Changes' : 'Done'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gallerySection(String tag, {required bool isLive}) {
    final existing = _existingImages[tag] ?? const <String>[];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$tag  ·  ${existing.length}',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary(context)),
                ),
              ),
              if (isLive)
                TextButton.icon(
                  onPressed: _saving
                      ? null
                      : () => _openUploadSheet(initialTag: tag),
                  icon: const Icon(Icons.add_a_photo, size: 14),
                  label: const Text('Add Photo'),
                  style: TextButton.styleFrom(
                      foregroundColor: AppTheme.brand,
                      padding: const EdgeInsets.symmetric(horizontal: 8)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          if (existing.isEmpty)
            Text(
              'No photos in this group yet.',
              style: TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary(context)),
            )
          else
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

  Widget _navButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity, height: 48,
      child: ElevatedButton(onPressed: onPressed, child: Text(label)),
    );
  }
}
