/// Cockpit data returned by `GET /api/command-center/dashboard`.
///
/// The same endpoint feeds the Today tab and the Inbox tab — one round-trip.
/// Inbox rendering reads the `inbox*` fields; legacy Today agenda reads
/// `todayEvents`/`myTasks`.
class DashboardData {
  final int mtdPoints;
  final int monthlyTarget;
  final TaskSummary taskSummary;
  final PropertyHealthSummary propHealthSummary;
  final List<CalendarEvent> todayEvents;
  final List<CalendarEvent> overdueEvents;
  final List<CommandTask> myTasks;
  final List<CommandTask> overdueTasks;
  final List<PropertyHealth> propsNeedingAttention;
  final List<CandidateDoc> candidateDocs;
  final AgentScorecard? scorecard;
  final int totalOverdue;

  // Cockpit inbox — concatenate in this order (urgency).
  final List<CommandTask> inboxOverdueTasks;
  final List<CalendarEvent> inboxOverdueEvents;
  final List<CandidateDoc> inboxCandidateDocs;
  final int inboxTotal;

  DashboardData({
    this.mtdPoints = 0,
    this.monthlyTarget = 300,
    this.taskSummary = const TaskSummary(),
    this.propHealthSummary = const PropertyHealthSummary(),
    this.todayEvents = const [],
    this.overdueEvents = const [],
    this.myTasks = const [],
    this.overdueTasks = const [],
    this.propsNeedingAttention = const [],
    this.candidateDocs = const [],
    this.scorecard,
    this.totalOverdue = 0,
    this.inboxOverdueTasks = const [],
    this.inboxOverdueEvents = const [],
    this.inboxCandidateDocs = const [],
    this.inboxTotal = 0,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      mtdPoints: json['mtd_points'] ?? 0,
      monthlyTarget: json['monthly_target'] ?? 300,
      taskSummary: TaskSummary.fromJson(json['task_summary'] ?? {}),
      propHealthSummary:
          PropertyHealthSummary.fromJson(json['prop_health_summary'] ?? {}),
      todayEvents: (json['today_events'] as List? ?? [])
          .map((e) => CalendarEvent.fromJson(e))
          .toList(),
      overdueEvents: (json['overdue_events'] as List? ?? [])
          .map((e) => CalendarEvent.fromJson(e))
          .toList(),
      myTasks: (json['my_tasks'] as List? ?? [])
          .map((e) => CommandTask.fromJson(e))
          .toList(),
      overdueTasks: (json['overdue_tasks'] as List? ?? [])
          .map((e) => CommandTask.fromJson(e))
          .toList(),
      propsNeedingAttention: (json['props_needing_attention'] as List? ?? [])
          .map((e) => PropertyHealth.fromJson(e))
          .toList(),
      candidateDocs: (json['candidate_docs'] as List? ?? [])
          .map((e) => CandidateDoc.fromJson(e))
          .toList(),
      scorecard: json['scorecard'] != null
          ? AgentScorecard.fromJson(json['scorecard'])
          : null,
      totalOverdue: json['total_overdue'] ?? 0,
      inboxOverdueTasks: (json['inbox_overdue_tasks'] as List? ?? [])
          .map((e) => CommandTask.fromJson(e))
          .toList(),
      inboxOverdueEvents: (json['inbox_overdue_events'] as List? ?? [])
          .map((e) => CalendarEvent.fromJson(e))
          .toList(),
      inboxCandidateDocs: (json['inbox_candidate_docs'] as List? ?? [])
          .map((e) => CandidateDoc.fromJson(e))
          .toList(),
      inboxTotal: json['inbox_total'] ?? 0,
    );
  }
}

class TaskSummary {
  final int today;
  final int overdue;
  final int thisWeek;
  final int open;

  const TaskSummary({this.today = 0, this.overdue = 0, this.thisWeek = 0, this.open = 0});

  factory TaskSummary.fromJson(Map<String, dynamic> json) {
    return TaskSummary(
      today: json['today'] ?? 0,
      overdue: json['overdue'] ?? 0,
      thisWeek: json['this_week'] ?? json['thisWeek'] ?? 0,
      open: json['open'] ?? 0,
    );
  }
}

class PropertyHealthSummary {
  final int critical;
  final int attention;
  final int good;

  const PropertyHealthSummary({this.critical = 0, this.attention = 0, this.good = 0});

  factory PropertyHealthSummary.fromJson(Map<String, dynamic> json) {
    return PropertyHealthSummary(
      critical: json['critical'] ?? 0,
      attention: json['attention'] ?? 0,
      good: json['good'] ?? 0,
    );
  }
}

class CalendarEvent {
  final int id;
  final String title;
  final String eventType;
  final String? category;
  final DateTime eventDate;
  final DateTime? endDate;
  final bool allDay;
  final String priority;
  final String status;
  final String? resolution;
  final String? resolutionNote;
  final String colour;
  final int? propertyId;
  final int? contactId;
  final String? propertyAddress;
  final String? contactName;
  final String? pillarTag; // server-supplied: 'property' | 'deal' | 'contact' | null
  final bool sendReminder;
  final String? description;

  CalendarEvent({
    required this.id,
    required this.title,
    this.eventType = 'manual',
    this.category,
    required this.eventDate,
    this.endDate,
    this.allDay = false,
    this.priority = 'normal',
    this.status = 'pending',
    this.resolution,
    this.resolutionNote,
    this.colour = '#6b7280',
    this.propertyId,
    this.contactId,
    this.propertyAddress,
    this.contactName,
    this.pillarTag,
    this.sendReminder = true,
    this.description,
  });

  bool get isOverdue =>
      status == 'overdue' || (status == 'pending' && eventDate.isBefore(DateTime.now()));

  String get overdueDuration {
    final diff = DateTime.now().difference(eventDate);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    return '${diff.inMinutes}m';
  }

  /// Derived pillar tag, falling back to server-computed value or the
  /// `event_type in ['deal','lease']` convention described in the cockpit spec.
  String? get effectivePillarTag {
    if (pillarTag != null && pillarTag!.isNotEmpty) return pillarTag;
    if (propertyId != null) return 'property';
    if (eventType == 'deal' || eventType == 'lease') return 'deal';
    if (contactId != null) return 'contact';
    return null;
  }

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      eventType: json['event_type'] ?? 'manual',
      category: json['category'],
      eventDate: DateTime.tryParse(json['event_date'] ?? '') ?? DateTime.now(),
      endDate: json['end_date'] != null ? DateTime.tryParse(json['end_date']) : null,
      allDay: json['all_day'] == true || json['all_day'] == 1,
      priority: json['priority'] ?? 'normal',
      status: json['status'] ?? 'pending',
      resolution: json['resolution'],
      resolutionNote: json['resolution_note'],
      colour: json['colour'] ?? _typeColour(json['event_type']),
      propertyId: json['property_id'],
      contactId: json['contact_id'],
      propertyAddress: json['property']?['display_address'] ?? json['property_address'],
      contactName: json['contact']?['name'] ?? json['contact_name'],
      pillarTag: json['pillar_tag'],
      sendReminder: json['send_reminder'] == true || json['send_reminder'] == 1,
      description: json['description'],
    );
  }

  static String _typeColour(String? type) {
    switch (type) {
      case 'deal': return '#3b82f6';
      case 'lease': return '#10b981';
      case 'compliance': return '#f59e0b';
      case 'document': return '#8b5cf6';
      case 'prospecting': return '#06b6d4';
      case 'property': return '#f97316';
      default: return '#6b7280';
    }
  }
}

class CommandTask {
  final int id;
  final String title;
  final String taskType;
  final String status;
  final String priority;
  final String? resolution;
  final String? resolutionNote;
  final int? assignedTo;
  final DateTime? dueDate;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? deletedAt;
  final int? propertyId;
  final int? contactId;
  final int? dealId;
  final String? propertyAddress;
  final String? contactName;
  final String? pillarTag;
  final String? description;
  final bool sendReminder;
  // Server-computed overdue flag (takes precedence over client-side calc when present).
  final bool? serverIsOverdue;

  CommandTask({
    required this.id,
    required this.title,
    this.taskType = 'custom',
    this.status = 'todo',
    this.priority = 'normal',
    this.resolution,
    this.resolutionNote,
    this.assignedTo,
    this.dueDate,
    this.startedAt,
    this.completedAt,
    this.deletedAt,
    this.propertyId,
    this.contactId,
    this.dealId,
    this.propertyAddress,
    this.contactName,
    this.pillarTag,
    this.description,
    this.sendReminder = true,
    this.serverIsOverdue,
  });

  bool get isOverdue =>
      serverIsOverdue ??
      (dueDate != null &&
          dueDate!.isBefore(DateTime.now()) &&
          status != 'done' &&
          status != 'dismissed');

  bool get isArchived => deletedAt != null;

  String get overdueDuration {
    if (dueDate == null) return '';
    final diff = DateTime.now().difference(dueDate!);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    return '${diff.inMinutes}m';
  }

  String? get effectivePillarTag {
    if (pillarTag != null && pillarTag!.isNotEmpty) return pillarTag;
    if (propertyId != null) return 'property';
    if (dealId != null) return 'deal';
    if (contactId != null) return 'contact';
    return null;
  }

  factory CommandTask.fromJson(Map<String, dynamic> json) {
    return CommandTask(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      taskType: json['task_type'] ?? 'custom',
      status: json['status'] ?? 'todo',
      priority: json['priority'] ?? 'normal',
      resolution: json['resolution'],
      resolutionNote: json['resolution_note'],
      assignedTo: json['assigned_to'],
      dueDate: json['due_date'] != null ? DateTime.tryParse(json['due_date']) : null,
      startedAt: json['started_at'] != null ? DateTime.tryParse(json['started_at']) : null,
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at']) : null,
      deletedAt: json['deleted_at'] != null ? DateTime.tryParse(json['deleted_at']) : null,
      propertyId: json['property_id'],
      contactId: json['contact_id'],
      dealId: json['deal_id'],
      propertyAddress: json['property']?['display_address'] ?? json['property_address'],
      contactName: json['contact']?['name'] ?? json['contact_name'],
      pillarTag: json['pillar_tag'],
      description: json['description'],
      sendReminder: json['send_reminder'] == true || json['send_reminder'] == 1,
      serverIsOverdue: json['is_overdue'] is bool ? json['is_overdue'] as bool : null,
    );
  }
}

class PropertyHealth {
  final int score;
  final String grade;
  final List<HealthFactor> factors;
  final int? propertyId;
  final String? propertyAddress;
  final String? agentName;

  PropertyHealth({
    required this.score,
    required this.grade,
    this.factors = const [],
    this.propertyId,
    this.propertyAddress,
    this.agentName,
  });

  factory PropertyHealth.fromJson(Map<String, dynamic> json) {
    return PropertyHealth(
      score: json['score'] ?? 0,
      grade: json['grade'] ?? 'attention',
      factors: (json['factors'] as List? ?? []).map((f) => HealthFactor.fromJson(f)).toList(),
      propertyId: json['property']?['id'] ?? json['property_id'],
      propertyAddress: json['property']?['display_address'] ?? json['property_address'],
      agentName: json['property']?['agent']?['name'],
    );
  }
}

class HealthFactor {
  final String label;
  final int penalty;
  final String status;

  HealthFactor({required this.label, this.penalty = 0, this.status = ''});

  factory HealthFactor.fromJson(Map<String, dynamic> json) {
    return HealthFactor(
      label: json['label'] ?? '',
      penalty: json['penalty'] ?? 0,
      status: json['status'] ?? '',
    );
  }
}

class CandidateDoc {
  final int? id;
  final int? documentId;
  final String documentName;
  final String creatorName;
  final String status;
  final String? reviewUrl;
  final DateTime? createdAt;

  CandidateDoc({
    this.id,
    this.documentId,
    this.documentName = '',
    this.creatorName = '',
    this.status = '',
    this.reviewUrl,
    this.createdAt,
  });

  factory CandidateDoc.fromJson(Map<String, dynamic> json) {
    return CandidateDoc(
      id: json['id'],
      documentId: json['document_id'] ?? json['document']?['id'],
      documentName: json['document']?['name'] ?? json['document_name'] ?? '',
      creatorName: json['creator']?['name'] ?? json['creator_name'] ?? '',
      status: json['status'] ?? '',
      reviewUrl: json['review_url'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }
}

class AgentScorecard {
  final int overallScore;
  final int tasksCompleted;
  final int tasksTotal;
  final int propertiesAttended;
  final int propertiesTotal;
  final int eventsCompleted;
  final int documentsUploaded;
  final int tasksOverdue;
  final double avgResponseHours;

  AgentScorecard({
    this.overallScore = 0,
    this.tasksCompleted = 0,
    this.tasksTotal = 0,
    this.propertiesAttended = 0,
    this.propertiesTotal = 0,
    this.eventsCompleted = 0,
    this.documentsUploaded = 0,
    this.tasksOverdue = 0,
    this.avgResponseHours = 0.0,
  });

  factory AgentScorecard.fromJson(Map<String, dynamic> json) {
    return AgentScorecard(
      overallScore: json['overall_score'] ?? 0,
      tasksCompleted: json['tasks_completed'] ?? 0,
      tasksTotal: json['tasks_total'] ?? 0,
      propertiesAttended: json['properties_attended'] ?? 0,
      propertiesTotal: json['properties_total'] ?? 0,
      eventsCompleted: json['events_completed'] ?? 0,
      documentsUploaded: json['documents_uploaded'] ?? 0,
      tasksOverdue: json['tasks_overdue'] ?? 0,
      avgResponseHours: (json['avg_response_hours'] ?? 0).toDouble(),
    );
  }
}

/// Response shape for `GET /api/command-center/tasks/archived` — tasks
/// pre-grouped by the day they were archived.
class ArchivedTasksData {
  final int total;
  final List<ArchivedGroup> groups;

  ArchivedTasksData({this.total = 0, this.groups = const []});

  factory ArchivedTasksData.fromJson(Map<String, dynamic> json) {
    return ArchivedTasksData(
      total: json['total'] ?? 0,
      groups: (json['groups'] as List? ?? [])
          .map((g) => ArchivedGroup.fromJson(g))
          .toList(),
    );
  }
}

class ArchivedGroup {
  final DateTime date;
  final List<CommandTask> tasks;

  ArchivedGroup({required this.date, this.tasks = const []});

  factory ArchivedGroup.fromJson(Map<String, dynamic> json) {
    return ArchivedGroup(
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      tasks: (json['tasks'] as List? ?? [])
          .map((t) => CommandTask.fromJson(t))
          .toList(),
    );
  }
}
