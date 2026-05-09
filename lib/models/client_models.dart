// Models for the Client-side auth + portal flow.
// Wraps /api/v1/client-auth/* and /api/v1/client/* payloads.

class ClientLookupResult {
  final bool exists;
  final bool requiresOtp;
  final bool requiresPassword;
  final bool mustChangePassword;
  final String? message;
  final List<ClientAgency> agencies;

  ClientLookupResult({
    required this.exists,
    required this.requiresOtp,
    required this.requiresPassword,
    required this.mustChangePassword,
    this.message,
    required this.agencies,
  });

  factory ClientLookupResult.fromJson(Map<String, dynamic> json) =>
      ClientLookupResult(
        exists: json['exists'] == true,
        requiresOtp: json['requires_otp'] == true,
        requiresPassword: json['requires_password'] == true,
        mustChangePassword: json['must_change_password'] == true,
        message: json['message']?.toString(),
        agencies: (json['agencies'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => ClientAgency.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class ClientAgency {
  final int id;
  final String name;
  final String slug;
  final bool isPreferred;
  final bool isLocked;

  ClientAgency({
    required this.id,
    required this.name,
    required this.slug,
    this.isPreferred = false,
    this.isLocked = false,
  });

  factory ClientAgency.fromJson(Map<String, dynamic> json) => ClientAgency(
        id: (json['id'] as num).toInt(),
        name: json['name']?.toString() ?? '',
        slug: json['slug']?.toString() ?? '',
        isPreferred: json['is_preferred'] == true,
        isLocked: json['is_locked'] == true,
      );
}

class ClientProfile {
  final int id;
  final String email;
  final bool hasPassword;
  final bool passwordMustChange;
  final int? preferredAgencyId;
  final int? lockedToAgencyId;
  final int? currentAgencyId;
  final String? lastLoginAt;

  ClientProfile({
    required this.id,
    required this.email,
    required this.hasPassword,
    required this.passwordMustChange,
    this.preferredAgencyId,
    this.lockedToAgencyId,
    this.currentAgencyId,
    this.lastLoginAt,
  });

  factory ClientProfile.fromJson(Map<String, dynamic> json) => ClientProfile(
        id: (json['id'] as num).toInt(),
        email: json['email']?.toString() ?? '',
        hasPassword: json['has_password'] == true,
        passwordMustChange: json['password_must_change'] == true,
        preferredAgencyId: _asInt(json['preferred_agency_id']),
        lockedToAgencyId: _asInt(json['locked_to_agency_id']),
        currentAgencyId: _asInt(json['current_agency_id']),
        lastLoginAt: json['last_login_at']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'has_password': hasPassword,
        'password_must_change': passwordMustChange,
        'preferred_agency_id': preferredAgencyId,
        'locked_to_agency_id': lockedToAgencyId,
        'current_agency_id': currentAgencyId,
        'last_login_at': lastLoginAt,
      };
}

class ClientContact {
  final int id;
  final String? firstName;
  final String? lastName;
  final String fullName;
  final String? email;
  final String? phone;
  final int? agencyId;

  ClientContact({
    required this.id,
    this.firstName,
    this.lastName,
    required this.fullName,
    this.email,
    this.phone,
    this.agencyId,
  });

  factory ClientContact.fromJson(Map<String, dynamic> json) => ClientContact(
        id: (json['id'] as num).toInt(),
        firstName: json['first_name']?.toString(),
        lastName: json['last_name']?.toString(),
        fullName: json['full_name']?.toString() ?? '',
        email: json['email']?.toString(),
        phone: json['phone']?.toString(),
        agencyId: _asInt(json['agency_id']),
      );
}

class ClientLoginResponse {
  final String token;
  final List<ClientAgency> agencies;
  final ClientProfile client;

  ClientLoginResponse({
    required this.token,
    required this.agencies,
    required this.client,
  });

  factory ClientLoginResponse.fromJson(Map<String, dynamic> json) =>
      ClientLoginResponse(
        token: json['token']?.toString() ?? '',
        agencies: (json['agencies'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => ClientAgency.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        client: ClientProfile.fromJson(
            Map<String, dynamic>.from(json['client'] as Map)),
      );
}

class ClientMatchResultThumb {
  final int id;
  final String address;
  final String? suburb;
  final int? beds;
  final int? baths;
  final num? price;
  final String? thumbnail;

  ClientMatchResultThumb({
    required this.id,
    required this.address,
    this.suburb,
    this.beds,
    this.baths,
    this.price,
    this.thumbnail,
  });

  factory ClientMatchResultThumb.fromJson(Map<String, dynamic> json) =>
      ClientMatchResultThumb(
        id: (json['id'] as num).toInt(),
        address: json['address']?.toString() ?? '',
        suburb: json['suburb']?.toString(),
        beds: _asInt(json['beds']),
        baths: _asInt(json['baths']),
        price: json['price'] is num ? json['price'] as num : null,
        thumbnail: json['thumbnail']?.toString(),
      );
}

class ClientMatch {
  final int id;
  final String status;
  final String? listingType;
  final String? createdAt;
  final int resultCount;
  final List<ClientMatchResultThumb> results;

  ClientMatch({
    required this.id,
    required this.status,
    this.listingType,
    this.createdAt,
    required this.resultCount,
    required this.results,
  });

  factory ClientMatch.fromJson(Map<String, dynamic> json) => ClientMatch(
        id: (json['id'] as num).toInt(),
        status: json['status']?.toString() ?? '',
        listingType: json['listing_type']?.toString(),
        createdAt: json['created_at']?.toString(),
        resultCount: _asInt(json['result_count']) ?? 0,
        results: (json['results'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => ClientMatchResultThumb.fromJson(
                Map<String, dynamic>.from(e)))
            .toList(),
      );
}

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}
