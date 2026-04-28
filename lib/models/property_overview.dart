class Placement {
  final String key;
  final String label;
  final String url;
  final bool live;

  const Placement({
    required this.key,
    required this.label,
    required this.url,
    required this.live,
  });

  factory Placement.fromJson(Map<String, dynamic> j) => Placement(
        key: j['key']?.toString() ?? '',
        label: j['label']?.toString() ?? '',
        url: j['url']?.toString() ?? '',
        live: j['live'] == true,
      );
}

class ContactRef {
  final int? id;
  final String name;
  final String? phone;
  final String? email;
  final String? photoUrl;

  const ContactRef({
    this.id,
    required this.name,
    this.phone,
    this.email,
    this.photoUrl,
  });

  factory ContactRef.fromJson(Map<String, dynamic> j) => ContactRef(
        id: j['id'] is int ? j['id'] as int : int.tryParse(j['id']?.toString() ?? ''),
        name: j['name']?.toString() ?? '',
        phone: j['phone']?.toString(),
        email: j['email']?.toString(),
        photoUrl: j['photo_url']?.toString(),
      );
}

class KeyDates {
  final String? listed;
  final String? expires;
  final String? loaded;
  final String? modified;

  const KeyDates({this.listed, this.expires, this.loaded, this.modified});

  factory KeyDates.fromJson(Map<String, dynamic> j) => KeyDates(
        listed: j['listed']?.toString(),
        expires: j['expires']?.toString(),
        loaded: j['loaded']?.toString(),
        modified: j['modified']?.toString(),
      );
}

class PropertyOverview {
  final int id;
  final String? title;
  final String? status;
  final String? coverImage;
  final String? suburb;
  final String? city;
  final String? priceDisplay;
  final int? daysOnMarket;
  final int? beds;
  final num? baths;
  final int? garages;
  final String? sizeM2;
  final String? erfSizeM2;
  final int? photosCount;
  final String? mandateType;
  final String? description;
  final String? livePreviewUrl;
  final String? virtualTourUrl;
  final List<Placement> placements;
  final ContactRef? agent;
  final ContactRef? owner;
  final KeyDates keyDates;

  const PropertyOverview({
    required this.id,
    this.title,
    this.status,
    this.coverImage,
    this.suburb,
    this.city,
    this.priceDisplay,
    this.daysOnMarket,
    this.beds,
    this.baths,
    this.garages,
    this.sizeM2,
    this.erfSizeM2,
    this.photosCount,
    this.mandateType,
    this.description,
    this.livePreviewUrl,
    this.virtualTourUrl,
    this.placements = const [],
    this.agent,
    this.owner,
    this.keyDates = const KeyDates(),
  });

  factory PropertyOverview.fromJson(Map<String, dynamic> j) {
    int? toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    num? toNum(dynamic v) {
      if (v == null) return null;
      if (v is num) return v;
      return num.tryParse(v.toString());
    }

    final placementsRaw = j['placements'];
    final placements = placementsRaw is List
        ? placementsRaw
            .whereType<Map>()
            .map((e) => Placement.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <Placement>[];

    final agentRaw = j['agent'];
    final ownerRaw = j['owner'];
    final kdRaw = j['key_dates'];

    return PropertyOverview(
      id: toInt(j['id']) ?? 0,
      title: j['title']?.toString(),
      status: j['status']?.toString(),
      coverImage: j['cover_image']?.toString(),
      suburb: j['suburb']?.toString(),
      city: j['city']?.toString(),
      priceDisplay: j['price_display']?.toString(),
      daysOnMarket: toInt(j['days_on_market']),
      beds: toInt(j['beds']),
      baths: toNum(j['baths']),
      garages: toInt(j['garages']),
      sizeM2: j['size_m2']?.toString(),
      erfSizeM2: j['erf_size_m2']?.toString(),
      photosCount: toInt(j['photos_count'] ?? j['photos']),
      mandateType: j['mandate_type']?.toString(),
      description: j['description']?.toString(),
      livePreviewUrl: j['live_preview_url']?.toString(),
      virtualTourUrl: j['virtual_tour_url']?.toString(),
      placements: placements,
      agent: agentRaw is Map
          ? ContactRef.fromJson(Map<String, dynamic>.from(agentRaw))
          : null,
      owner: ownerRaw is Map
          ? ContactRef.fromJson(Map<String, dynamic>.from(ownerRaw))
          : null,
      keyDates: kdRaw is Map
          ? KeyDates.fromJson(Map<String, dynamic>.from(kdRaw))
          : const KeyDates(),
    );
  }
}
