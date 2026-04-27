import 'package:flutter/material.dart';

/// One row in `GET /api/notifications`.
class NotificationItem {
  final int id;
  final String type;
  final String eventKey;
  final String pillar;
  final String title;
  final String body;
  final NotificationSubject? subject;
  final String? actionUrl;
  final String severity; // info | warning | overdue
  final DateTime? readAt;
  final DateTime createdAt;
  final Map<String, dynamic> data;

  NotificationItem({
    required this.id,
    required this.type,
    required this.eventKey,
    required this.pillar,
    required this.title,
    required this.body,
    required this.severity,
    required this.createdAt,
    this.subject,
    this.actionUrl,
    this.readAt,
    this.data = const {},
  });

  bool get isRead => readAt != null;

  factory NotificationItem.fromJson(Map<String, dynamic> j) => NotificationItem(
        id: (j['id'] as num).toInt(),
        type: j['type']?.toString() ?? '',
        eventKey: j['event_key']?.toString() ?? '',
        pillar: j['pillar']?.toString() ?? '',
        title: j['title']?.toString() ?? '',
        body: j['body']?.toString() ?? '',
        subject: j['subject'] is Map
            ? NotificationSubject.fromJson(
                Map<String, dynamic>.from(j['subject']))
            : null,
        actionUrl: j['action_url']?.toString(),
        severity: j['severity']?.toString() ?? 'info',
        readAt: _parseDate(j['read_at']),
        createdAt: _parseDate(j['created_at']) ?? DateTime.now(),
        data: j['data'] is Map
            ? Map<String, dynamic>.from(j['data'])
            : <String, dynamic>{},
      );
}

class NotificationSubject {
  final String type;
  final dynamic id;
  final String? label;
  NotificationSubject({required this.type, required this.id, this.label});

  factory NotificationSubject.fromJson(Map<String, dynamic> j) =>
      NotificationSubject(
        type: j['type']?.toString() ?? '',
        id: j['id'],
        label: j['label']?.toString(),
      );
}

/// `GET /api/notifications/overdue`
class OverdueSnapshot {
  final OverdueCounts counts;
  final List<OverdueItem> items;

  OverdueSnapshot({required this.counts, required this.items});

  factory OverdueSnapshot.empty() =>
      OverdueSnapshot(counts: OverdueCounts.empty(), items: const []);

  factory OverdueSnapshot.fromJson(Map<String, dynamic> j) => OverdueSnapshot(
        counts: OverdueCounts.fromJson(
            Map<String, dynamic>.from(j['counts'] ?? {})),
        items: (j['items'] as List? ?? [])
            .whereType<Map>()
            .map((e) => OverdueItem.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class OverdueCounts {
  final int properties;
  final int contacts;
  final int deals;
  final int tasks;
  final int events;
  final int total;

  const OverdueCounts({
    required this.properties,
    required this.contacts,
    required this.deals,
    required this.tasks,
    required this.events,
    required this.total,
  });

  factory OverdueCounts.empty() => const OverdueCounts(
      properties: 0, contacts: 0, deals: 0, tasks: 0, events: 0, total: 0);

  factory OverdueCounts.fromJson(Map<String, dynamic> j) => OverdueCounts(
        properties: _int(j['properties']),
        contacts: _int(j['contacts']),
        deals: _int(j['deals']),
        tasks: _int(j['tasks']),
        events: _int(j['events']),
        total: _int(j['total']),
      );
}

class OverdueItem {
  final String eventKey;
  final String pillar;
  final NotificationSubject? subject;
  final double ageHours;
  final String severity;
  final String? actionUrl;
  final String title;
  final String body;
  final DateTime? thresholdHitAt;

  OverdueItem({
    required this.eventKey,
    required this.pillar,
    required this.severity,
    required this.title,
    required this.body,
    required this.ageHours,
    this.subject,
    this.actionUrl,
    this.thresholdHitAt,
  });

  factory OverdueItem.fromJson(Map<String, dynamic> j) => OverdueItem(
        eventKey: j['event_key']?.toString() ?? '',
        pillar: j['pillar']?.toString() ?? '',
        subject: j['subject'] is Map
            ? NotificationSubject.fromJson(
                Map<String, dynamic>.from(j['subject']))
            : null,
        ageHours: (j['age_hours'] is num)
            ? (j['age_hours'] as num).toDouble()
            : double.tryParse(j['age_hours']?.toString() ?? '') ?? 0,
        severity: j['severity']?.toString() ?? 'overdue',
        actionUrl: j['action_url']?.toString(),
        title: j['title']?.toString() ?? '',
        body: j['body']?.toString() ?? '',
        thresholdHitAt: _parseDate(j['threshold_hit_at']),
      );
}

/// `GET /api/notification-preferences`
class NotificationPreferencesData {
  final MasterChannels master;
  final bool agencyControlled;
  final List<PreferenceGroup> groups;

  NotificationPreferencesData({
    required this.master,
    required this.agencyControlled,
    required this.groups,
  });

  factory NotificationPreferencesData.fromJson(Map<String, dynamic> j) =>
      NotificationPreferencesData(
        master: MasterChannels.fromJson(
            Map<String, dynamic>.from(j['master'] ?? {})),
        agencyControlled: j['agency_controlled'] == true,
        groups: (j['groups'] as List? ?? [])
            .whereType<Map>()
            .map((e) => PreferenceGroup.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'master': master.toJson(),
        'agency_controlled': agencyControlled,
        'groups': groups.map((g) => g.toJson()).toList(),
      };
}

class MasterChannels {
  bool inApp;
  bool email;
  bool push;

  MasterChannels({required this.inApp, required this.email, required this.push});

  factory MasterChannels.fromJson(Map<String, dynamic> j) => MasterChannels(
        inApp: j['in_app'] != false,
        email: j['email'] != false,
        push: j['push'] != false,
      );

  Map<String, dynamic> toJson() =>
      {'in_app': inApp, 'email': email, 'push': push};

  MasterChannels copy() =>
      MasterChannels(inApp: inApp, email: email, push: push);
}

class PreferenceGroup {
  final String pillar; // property | contact | deal | agent
  final String label;
  final List<NotificationPreference> items;

  PreferenceGroup(
      {required this.pillar, required this.label, required this.items});

  factory PreferenceGroup.fromJson(Map<String, dynamic> j) => PreferenceGroup(
        pillar: j['pillar']?.toString() ?? '',
        label: j['label']?.toString() ?? '',
        items: (j['items'] as List? ?? [])
            .whereType<Map>()
            .map((e) =>
                NotificationPreference.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'pillar': pillar,
        'label': label,
        'items': items.map((i) => i.toJson()).toList(),
      };
}

class NotificationPreference {
  final String key;
  final String label;
  final String description;
  final String group;
  final String thresholdUnit; // hours | days | none
  int? threshold;
  final int? thresholdMin;
  final int? thresholdMax;
  bool enabled;
  bool channelInApp;
  bool channelEmail;
  bool channelPush;
  final bool isAdapter;

  NotificationPreference({
    required this.key,
    required this.label,
    required this.description,
    required this.group,
    required this.thresholdUnit,
    required this.enabled,
    required this.channelInApp,
    required this.channelEmail,
    required this.channelPush,
    this.threshold,
    this.thresholdMin,
    this.thresholdMax,
    this.isAdapter = false,
  });

  factory NotificationPreference.fromJson(Map<String, dynamic> j) =>
      NotificationPreference(
        key: j['key']?.toString() ?? '',
        label: j['label']?.toString() ?? '',
        description: j['description']?.toString() ?? '',
        group: j['group']?.toString() ?? '',
        thresholdUnit: j['threshold_unit']?.toString() ?? 'none',
        threshold: _intOrNull(j['threshold']),
        thresholdMin: _intOrNull(j['threshold_min']),
        thresholdMax: _intOrNull(j['threshold_max']),
        enabled: j['enabled'] == true,
        channelInApp: j['channel_in_app'] == true,
        channelEmail: j['channel_email'] == true,
        channelPush: j['channel_push'] == true,
        isAdapter: j['is_adapter'] == true,
      );

  Map<String, dynamic> toJson() => {
        'key': key,
        'enabled': enabled,
        if (thresholdUnit != 'none' && threshold != null) 'threshold': threshold,
        'channel_in_app': channelInApp,
        'channel_email': channelEmail,
        'channel_push': channelPush,
      };
}

Color severityColor(String severity) {
  switch (severity) {
    case 'overdue':
      return const Color(0xFFef4444);
    case 'warning':
      return const Color(0xFFf59e0b);
    default:
      return const Color(0xFF0EA5E9);
  }
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}

int _int(dynamic v) {
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? 0;
}

int? _intOrNull(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}
