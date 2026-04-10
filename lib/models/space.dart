class SpacesCatalog {
  final List<String> allSpaceTypes;
  final List<String> halfUnitSpaces;
  final Map<String, Map<String, List<String>>> spaceFeatures;
  final Map<String, List<String>> defaultSpaceFeatures;
  final Map<String, FeatureCategory> featureCategories;

  SpacesCatalog({
    required this.allSpaceTypes,
    required this.halfUnitSpaces,
    required this.spaceFeatures,
    required this.defaultSpaceFeatures,
    required this.featureCategories,
  });

  static Map<String, List<String>> _toStrListMap(dynamic m) {
    if (m is! Map) return {};
    return m.map((k, v) => MapEntry(
          k.toString(),
          (v is List) ? v.map((e) => e.toString()).toList() : <String>[],
        ));
  }

  factory SpacesCatalog.fromJson(Map<String, dynamic> json) {
    final sf = <String, Map<String, List<String>>>{};
    final rawSf = json['space_features'];
    if (rawSf is Map) {
      rawSf.forEach((k, v) {
        sf[k.toString()] = _toStrListMap(v);
      });
    }

    final fc = <String, FeatureCategory>{};
    final rawFc = json['feature_categories'];
    if (rawFc is Map) {
      rawFc.forEach((k, v) {
        if (v is Map) {
          fc[k.toString()] = FeatureCategory(
            label: v['label']?.toString() ?? k.toString(),
            features: (v['features'] is List)
                ? (v['features'] as List).map((e) => e.toString()).toList()
                : const [],
          );
        }
      });
    }

    return SpacesCatalog(
      allSpaceTypes: (json['all_space_types'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      halfUnitSpaces: (json['half_unit_spaces'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      spaceFeatures: sf,
      defaultSpaceFeatures: _toStrListMap(json['default_space_features']),
      featureCategories: fc,
    );
  }

  Map<String, dynamic> toJson() => {
        'all_space_types': allSpaceTypes,
        'half_unit_spaces': halfUnitSpaces,
        'space_features': spaceFeatures,
        'default_space_features': defaultSpaceFeatures,
        'feature_categories': featureCategories.map(
            (k, v) => MapEntry(k, {'label': v.label, 'features': v.features})),
      };

  /// Returns the feature groups for a given space type, falling back to
  /// [defaultSpaceFeatures] when the type isn't explicitly keyed.
  Map<String, List<String>> featuresForType(String type) {
    final specific = spaceFeatures[type];
    if (specific != null && specific.isNotEmpty) return specific;
    return defaultSpaceFeatures;
  }
}

class FeatureCategory {
  final String label;
  final List<String> features;
  FeatureCategory({required this.label, required this.features});
}

class PropertySpaceUnit {
  String label;
  List<String> features;

  PropertySpaceUnit({required this.label, required this.features});

  factory PropertySpaceUnit.fromJson(Map<String, dynamic> json) =>
      PropertySpaceUnit(
        label: json['label']?.toString() ?? '',
        features: (json['features'] is List)
            ? (json['features'] as List).map((e) => e.toString()).toList()
            : <String>[],
      );

  Map<String, dynamic> toJson() => {'label': label, 'features': features};
}

class PropertySpace {
  String type;
  double count;
  List<String> featuresAll;
  String descriptionAll;
  List<PropertySpaceUnit> units;

  PropertySpace({
    required this.type,
    required this.count,
    required this.featuresAll,
    required this.descriptionAll,
    required this.units,
  });

  factory PropertySpace.fromJson(Map<String, dynamic> json) => PropertySpace(
        type: json['type']?.toString() ?? '',
        count: (json['count'] is num) ? (json['count'] as num).toDouble() : 0,
        featuresAll: (json['featuresAll'] is List)
            ? (json['featuresAll'] as List).map((e) => e.toString()).toList()
            : <String>[],
        descriptionAll: json['descriptionAll']?.toString() ?? '',
        units: (json['units'] is List)
            ? (json['units'] as List)
                .map((e) =>
                    PropertySpaceUnit.fromJson(Map<String, dynamic>.from(e)))
                .toList()
            : <PropertySpaceUnit>[],
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'count': count,
        'featuresAll': featuresAll,
        'descriptionAll': descriptionAll,
        'units': units.map((u) => u.toJson()).toList(),
      };
}

class PropertySpacesData {
  List<PropertySpace> spaces;
  Map<String, List<String>> features;
  int? beds;
  int? baths;
  int? garages;

  PropertySpacesData({
    required this.spaces,
    required this.features,
    this.beds,
    this.baths,
    this.garages,
  });

  factory PropertySpacesData.fromJson(Map<String, dynamic> json) {
    final sjRaw = json['spaces_json'];
    final sj = sjRaw is Map ? Map<String, dynamic>.from(sjRaw) : <String, dynamic>{};
    final spacesRaw = sj['spaces'];
    final featuresRaw = sj['features'];
    return PropertySpacesData(
      spaces: (spacesRaw is List)
          ? spacesRaw
              .map((e) => PropertySpace.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : <PropertySpace>[],
      features: (featuresRaw is Map)
          ? featuresRaw.map((k, v) => MapEntry(
                k.toString(),
                (v is List) ? v.map((e) => e.toString()).toList() : <String>[],
              ))
          : <String, List<String>>{},
      beds: (json['beds'] is num) ? (json['beds'] as num).toInt() : null,
      baths: (json['baths'] is num) ? (json['baths'] as num).toInt() : null,
      garages: (json['garages'] is num) ? (json['garages'] as num).toInt() : null,
    );
  }

  Map<String, dynamic> toPayload() => {
        'spaces': spaces.map((s) => s.toJson()).toList(),
        'features': features,
      };
}
