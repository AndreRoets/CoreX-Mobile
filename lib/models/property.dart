class Property {
  final int id;
  final String address;
  final int? beds;
  final int? baths;
  final int? garages;
  final String? status;
  final String? propertyType;
  final String? category;
  final String? listingType;
  final int? price;
  final String? priceDisplay;
  final String? thumbnail;
  final String? updatedAt;
  // Detail-only fields
  final String? streetNumber;
  final String? streetName;
  final String? suburb;
  final String? city;
  final String? complexName;
  final String? unitNumber;
  final String? sizeM2;
  final String? erfSizeM2;
  final String? mandateType;
  final String? description;
  final List<String> features;
  final List<String> galleryImages;
  final Map<String, dynamic>? galleryCategories;
  /// Ordered list of tags currently valid on this property (derived from
  /// the spaces the agent has added). Mirrors `/gallery/tags`'s
  /// `available_tags` so the detail screen can render gallery groups
  /// without an extra round-trip.
  final List<String> galleryTags;

  Property({
    required this.id,
    required this.address,
    this.beds,
    this.baths,
    this.garages,
    this.status,
    this.propertyType,
    this.category,
    this.listingType,
    this.price,
    this.priceDisplay,
    this.thumbnail,
    this.updatedAt,
    this.streetNumber,
    this.streetName,
    this.suburb,
    this.city,
    this.complexName,
    this.unitNumber,
    this.sizeM2,
    this.erfSizeM2,
    this.mandateType,
    this.description,
    this.features = const [],
    this.galleryImages = const [],
    this.galleryCategories,
    this.galleryTags = const [],
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'] as int,
      address: json['address'] as String? ?? '',
      beds: json['beds'] as int?,
      baths: json['baths'] as int?,
      garages: json['garages'] as int?,
      status: json['status'] as String?,
      propertyType: json['property_type'] as String?,
      category: json['category'] as String?,
      listingType: json['listing_type'] as String?,
      price: json['price'] as int?,
      priceDisplay: json['price_display'] as String?,
      thumbnail: json['thumbnail'] as String?,
      updatedAt: json['updated_at'] as String?,
      streetNumber: json['street_number'] as String?,
      streetName: json['street_name'] as String?,
      suburb: json['suburb'] as String?,
      city: json['city'] as String?,
      complexName: json['complex_name'] as String?,
      unitNumber: json['unit_number'] as String?,
      sizeM2: json['size_m2']?.toString(),
      erfSizeM2: json['erf_size_m2']?.toString(),
      mandateType: json['mandate_type'] as String?,
      description: json['description'] as String?,
      features: json['features'] != null
          ? List<String>.from(json['features'])
          : const [],
      galleryImages: json['gallery_images'] != null
          ? List<String>.from(json['gallery_images'])
          : const [],
      galleryCategories: json['gallery_categories'] as Map<String, dynamic>?,
      galleryTags: json['gallery_tags'] != null
          ? List<String>.from(json['gallery_tags'])
          : const [],
    );
  }
}
