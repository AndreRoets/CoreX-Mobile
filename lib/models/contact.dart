class ContactType {
  final int id;
  final String name;
  const ContactType({required this.id, required this.name});

  factory ContactType.fromJson(Map<String, dynamic> j) => ContactType(
        id: (j['id'] as num).toInt(),
        name: j['name']?.toString() ?? '',
      );
}

class ContactMatch {
  final int id;
  final String? name;
  final String? listingType;
  final String? status;
  final String? suburb;
  final int? priceMin;
  final int? priceMax;
  final String? category;
  final String? propertyType;

  const ContactMatch({
    required this.id,
    this.name,
    this.listingType,
    this.status,
    this.suburb,
    this.priceMin,
    this.priceMax,
    this.category,
    this.propertyType,
  });

  factory ContactMatch.fromJson(Map<String, dynamic> j) {
    int? n(dynamic v) => v == null ? null : (v is num ? v.toInt() : int.tryParse(v.toString()));
    return ContactMatch(
      id: (j['id'] as num).toInt(),
      name: j['name']?.toString(),
      listingType: j['listing_type']?.toString(),
      status: j['status']?.toString(),
      suburb: j['suburb']?.toString(),
      priceMin: n(j['price_min']),
      priceMax: n(j['price_max']),
      category: j['category']?.toString(),
      propertyType: j['property_type']?.toString(),
    );
  }
}

class ContactLinkedProperty {
  final int id;
  final String? address;
  final String? role;

  const ContactLinkedProperty({required this.id, this.address, this.role});

  factory ContactLinkedProperty.fromJson(Map<String, dynamic> j) =>
      ContactLinkedProperty(
        id: (j['id'] as num).toInt(),
        address: j['address']?.toString() ?? j['title']?.toString(),
        role: j['role']?.toString() ?? j['link_role']?.toString(),
      );
}

class Contact {
  final int id;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? email;
  final String? idNumber;
  final int? contactTypeId;
  final String? contactTypeName;
  final String? notes;
  final int whatsappCount;
  final String? lastContactedAt;
  final List<ContactMatch> matches;
  final List<ContactLinkedProperty> linkedProperties;

  const Contact({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.email,
    this.idNumber,
    this.contactTypeId,
    this.contactTypeName,
    this.notes,
    this.whatsappCount = 0,
    this.lastContactedAt,
    this.matches = const [],
    this.linkedProperties = const [],
  });

  String get fullName {
    final f = '$firstName $lastName'.trim();
    return f.isEmpty ? 'Unnamed contact' : f;
  }

  factory Contact.fromJson(Map<String, dynamic> j) {
    int? n(dynamic v) => v == null ? null : (v is num ? v.toInt() : int.tryParse(v.toString()));

    String? typeName;
    final type = j['contact_type'] ?? j['type'];
    if (type is Map) {
      typeName = type['name']?.toString();
    } else if (type is String) {
      typeName = type;
    }
    typeName ??= j['contact_type_name']?.toString();

    final matches = (j['matches'] as List? ?? [])
        .whereType<Map>()
        .map((e) => ContactMatch.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final linkedRaw = j['linked_properties'] ?? j['properties'] ?? [];
    final linked = (linkedRaw as List? ?? [])
        .whereType<Map>()
        .map((e) => ContactLinkedProperty.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return Contact(
      id: (j['id'] as num).toInt(),
      firstName: j['first_name']?.toString() ?? '',
      lastName: j['last_name']?.toString() ?? '',
      phone: j['phone']?.toString(),
      email: j['email']?.toString(),
      idNumber: j['id_number']?.toString(),
      contactTypeId: n(j['contact_type_id']),
      contactTypeName: typeName,
      notes: j['notes']?.toString(),
      whatsappCount: n(j['whatsapp_count']) ?? 0,
      lastContactedAt: j['last_contacted_at']?.toString(),
      matches: matches,
      linkedProperties: linked,
    );
  }
}
