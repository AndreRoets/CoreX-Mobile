// Models backing the Contact → Compliance area (Consent / Drive / FICA).
// Mirrors the parsing style of [PropertyCompliance]: defensive `fromJson`
// factories, null-safe coercion helpers, const constructors.

int? _int(dynamic v) =>
    v == null ? null : (v is num ? v.toInt() : int.tryParse(v.toString()));

String _str(dynamic v) => v?.toString() ?? '';

// ─────────────────────────── CONSENT ───────────────────────────

class ConsentItem {
  final String consentType;
  final String label;
  final bool isActive;
  final String? givenAt;
  final String? givenBy;
  final String? method;

  const ConsentItem({
    required this.consentType,
    required this.label,
    this.isActive = false,
    this.givenAt,
    this.givenBy,
    this.method,
  });

  factory ConsentItem.fromJson(Map<String, dynamic> j) => ConsentItem(
        consentType: _str(j['consent_type']),
        label: _str(j['label']),
        isActive: j['is_active'] == true,
        givenAt: j['given_at']?.toString(),
        givenBy: j['given_by']?.toString(),
        method: j['method']?.toString(),
      );
}

class ConsentHistoryEntry {
  final int id;
  final String consentType;
  final String label;
  final String? method;
  final String? givenAt;
  final String? givenBy;
  final String? revokedAt;
  final String? revokedBy;
  final String? revokedReason;

  const ConsentHistoryEntry({
    required this.id,
    required this.consentType,
    required this.label,
    this.method,
    this.givenAt,
    this.givenBy,
    this.revokedAt,
    this.revokedBy,
    this.revokedReason,
  });

  factory ConsentHistoryEntry.fromJson(Map<String, dynamic> j) =>
      ConsentHistoryEntry(
        id: _int(j['id']) ?? 0,
        consentType: _str(j['consent_type']),
        label: _str(j['label']),
        method: j['method']?.toString(),
        givenAt: j['given_at']?.toString(),
        givenBy: j['given_by']?.toString(),
        revokedAt: j['revoked_at']?.toString(),
        revokedBy: j['revoked_by']?.toString(),
        revokedReason: j['revoked_reason']?.toString(),
      );
}

class ContactConsentData {
  final List<ConsentItem> consent;
  final List<ConsentHistoryEntry> history;

  const ContactConsentData({this.consent = const [], this.history = const []});

  factory ContactConsentData.fromJson(Map<String, dynamic> j) =>
      ContactConsentData(
        consent: (j['consent'] as List? ?? [])
            .whereType<Map>()
            .map((e) => ConsentItem.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        history: (j['history'] as List? ?? [])
            .whereType<Map>()
            .map((e) =>
                ConsentHistoryEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

/// Allowed `method` values for giving consent.
const List<String> kConsentMethods = [
  'electronic',
  'verbal',
  'written',
  'signed_document',
];

const Map<String, String> kConsentMethodLabels = {
  'electronic': 'Electronic',
  'verbal': 'Verbal',
  'written': 'Written',
  'signed_document': 'Signed document',
};

// ─────────────────────────── DRIVE ───────────────────────────

class DocumentType {
  final int id;
  final String slug;
  final String label;

  const DocumentType({required this.id, required this.slug, required this.label});

  factory DocumentType.fromJson(Map<String, dynamic> j) => DocumentType(
        id: _int(j['id']) ?? 0,
        slug: _str(j['slug']),
        label: _str(j['label']),
      );
}

class DriveProperty {
  final int id;
  final String address;
  final String? role;

  const DriveProperty({required this.id, required this.address, this.role});

  factory DriveProperty.fromJson(Map<String, dynamic> j) => DriveProperty(
        id: _int(j['id']) ?? 0,
        address: _str(j['address']),
        role: j['role']?.toString(),
      );
}

class DriveDoc {
  final int id;
  final String originalName;
  final String? mimeType;
  final int? size;
  final String? humanSize;
  final bool isImage;
  final String? sourceType;
  final DocumentType? documentType;
  final int? propertyId;
  final String? uploadedBy;
  final String? createdAt;

  const DriveDoc({
    required this.id,
    required this.originalName,
    this.mimeType,
    this.size,
    this.humanSize,
    this.isImage = false,
    this.sourceType,
    this.documentType,
    this.propertyId,
    this.uploadedBy,
    this.createdAt,
  });

  factory DriveDoc.fromJson(Map<String, dynamic> j) {
    final dt = j['document_type'];
    return DriveDoc(
      id: _int(j['id']) ?? 0,
      originalName: _str(j['original_name']),
      mimeType: j['mime_type']?.toString(),
      size: _int(j['size']),
      humanSize: j['human_size']?.toString(),
      isImage: j['is_image'] == true,
      sourceType: j['source_type']?.toString(),
      documentType: dt is Map
          ? DocumentType.fromJson(Map<String, dynamic>.from(dt))
          : null,
      propertyId: _int(j['property_id']),
      uploadedBy: j['uploaded_by']?.toString(),
      createdAt: j['created_at']?.toString(),
    );
  }
}

class DriveLinkedGroup {
  final DriveProperty property;
  final List<DriveDoc> documents;

  const DriveLinkedGroup({required this.property, this.documents = const []});

  factory DriveLinkedGroup.fromJson(Map<String, dynamic> j) {
    final p = j['property'];
    return DriveLinkedGroup(
      property: p is Map
          ? DriveProperty.fromJson(Map<String, dynamic>.from(p))
          : const DriveProperty(id: 0, address: ''),
      documents: (j['documents'] as List? ?? [])
          .whereType<Map>()
          .map((e) => DriveDoc.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class ContactDriveData {
  final List<DriveLinkedGroup> linkedGroups;
  final List<DriveDoc> unlinked;
  final List<DocumentType> documentTypes;
  final List<DriveProperty> properties;

  const ContactDriveData({
    this.linkedGroups = const [],
    this.unlinked = const [],
    this.documentTypes = const [],
    this.properties = const [],
  });

  bool get isEmpty => linkedGroups.isEmpty && unlinked.isEmpty;

  factory ContactDriveData.fromJson(Map<String, dynamic> j) => ContactDriveData(
        linkedGroups: (j['linked_groups'] as List? ?? [])
            .whereType<Map>()
            .map((e) => DriveLinkedGroup.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        unlinked: (j['unlinked'] as List? ?? [])
            .whereType<Map>()
            .map((e) => DriveDoc.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        documentTypes: (j['document_types'] as List? ?? [])
            .whereType<Map>()
            .map((e) => DocumentType.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        properties: (j['properties'] as List? ?? [])
            .whereType<Map>()
            .map((e) => DriveProperty.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

// ─────────────────────────── FICA ───────────────────────────

class FicaDoc {
  final int id;
  final String documentType;
  final String fileName;
  final String? status;
  final String? uploadedAt;

  const FicaDoc({
    required this.id,
    required this.documentType,
    required this.fileName,
    this.status,
    this.uploadedAt,
  });

  factory FicaDoc.fromJson(Map<String, dynamic> j) => FicaDoc(
        id: _int(j['id']) ?? 0,
        documentType: _str(j['document_type']),
        fileName: _str(j['file_name']),
        status: j['status']?.toString(),
        uploadedAt: j['uploaded_at']?.toString(),
      );
}

class FicaSubmission {
  final int id;
  final String? entityType;
  final String? status;
  final String? riskRating;
  final String? verifiedBy;
  final String? verifiedAt;
  final String? ficaExpiresAt;
  final bool hasPdf;
  final List<FicaDoc> documents;

  const FicaSubmission({
    required this.id,
    this.entityType,
    this.status,
    this.riskRating,
    this.verifiedBy,
    this.verifiedAt,
    this.ficaExpiresAt,
    this.hasPdf = false,
    this.documents = const [],
  });

  factory FicaSubmission.fromJson(Map<String, dynamic> j) => FicaSubmission(
        id: _int(j['id']) ?? 0,
        entityType: j['entity_type']?.toString(),
        status: j['status']?.toString(),
        riskRating: j['risk_rating']?.toString(),
        verifiedBy: j['verified_by']?.toString(),
        verifiedAt: j['verified_at']?.toString(),
        ficaExpiresAt: j['fica_expires_at']?.toString(),
        hasPdf: j['has_pdf'] == true,
        documents: (j['documents'] as List? ?? [])
            .whereType<Map>()
            .map((e) => FicaDoc.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class FicaLegacyDoc {
  final int id;
  final String name;
  final String? signedAt;
  final String? status;

  const FicaLegacyDoc({
    required this.id,
    required this.name,
    this.signedAt,
    this.status,
  });

  factory FicaLegacyDoc.fromJson(Map<String, dynamic> j) => FicaLegacyDoc(
        id: _int(j['id']) ?? 0,
        name: _str(j['name']),
        signedAt: j['signed_at']?.toString(),
        status: j['status']?.toString(),
      );
}

class ContactFicaData {
  final String status; // complete | expiring | incomplete
  final String statusLabel;
  final List<FicaSubmission> submissions;
  final List<FicaLegacyDoc> legacyDocuments;

  const ContactFicaData({
    this.status = 'incomplete',
    this.statusLabel = 'No FICA on File',
    this.submissions = const [],
    this.legacyDocuments = const [],
  });

  factory ContactFicaData.fromJson(Map<String, dynamic> j) => ContactFicaData(
        status: _str(j['status']).isEmpty ? 'incomplete' : _str(j['status']),
        statusLabel: _str(j['status_label']).isEmpty
            ? 'No FICA on File'
            : _str(j['status_label']),
        submissions: (j['submissions'] as List? ?? [])
            .whereType<Map>()
            .map((e) => FicaSubmission.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        legacyDocuments: (j['legacy_documents'] as List? ?? [])
            .whereType<Map>()
            .map((e) => FicaLegacyDoc.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}
