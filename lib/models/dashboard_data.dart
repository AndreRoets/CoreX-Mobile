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
  final List<CommandTask> overduePopupTasks;
  final List<CalendarEvent> overduePopupEvents;

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
    this.overduePopupTasks = const [],
    this.overduePopupEvents = const [],
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      mtdPoints: json['mtd_points'] ?? 0,
      monthlyTarget: json['monthly_target'] ?? 300,
      taskSummary: TaskSummary.fromJson(json['task_summary'] ?? {}),
      propHealthSummary: PropertyHealthSummary.fromJson(json['prop_health_summary'] ?? {}),
      todayEvents: (json['today_events'] as List? ?? []).map((e) => CalendarEvent.fromJson(e)).toList(),
      overdueEvents: (json['overdue_events'] as List? ?? []).map((e) => CalendarEvent.fromJson(e)).toList(),
      myTasks: (json['my_tasks'] as List? ?? []).map((e) => CommandTask.fromJson(e)).toList(),
      overdueTasks: (json['overdue_tasks'] as List? ?? []).map((e) => CommandTask.fromJson(e)).toList(),
      propsNeedingAttention: (json['props_needing_attention'] as List? ?? []).map((e) => PropertyHealth.fromJson(e)).toList(),
      candidateDocs: (json['candidate_docs'] as List? ?? []).map((e) => CandidateDoc.fromJson(e)).toList(),
      scorecard: json['scorecard'] != null ? AgentScorecard.fromJson(json['scorecard']) : null,
      totalOverdue: json['total_overdue'] ?? 0,
      overduePopupTasks: (json['overdue_popup_tasks'] as List? ?? []).map((e) => CommandTask.fromJson(e)).toList(),
      overduePopupEvents: (json['overdue_popup_events'] as List? ?? []).map((e) => CalendarEvent.fromJson(e)).toList(),
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
    this.sendReminder = true,
    this.description,
  });

  bool get isOverdue => status == 'overdue' || (status == 'pending' && eventDate.isBefore(DateTime.now()));

  String get overdueDuration {
    final diff = DateTime.now().difference(eventDate);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    return '${diff.inMinutes}m';
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
  final DateTime? completedAt;
  final int? propertyId;
  final int? contactId;
  final int? dealId;
  final String? propertyAddress;
  final String? description;
  final bool sendReminder;

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
    this.completedAt,
    this.propertyId,
    this.contactId,
    this.dealId,
    this.propertyAddress,
    this.description,
    this.sendReminder = true,
  });

  bool get isOverdue => dueDate != null && dueDate!.isBefore(DateTime.now()) && status != 'done' && status != 'dismissed';

  String get overdueDuration {
    if (dueDate == null) return '';
    final diff = DateTime.now().difference(dueDate!);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    return '${diff.inMinutes}m';
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
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at']) : null,
      propertyId: json['property_id'],
      contactId: json['contact_id'],
      dealId: json['deal_id'],
      propertyAddress: json['property']?['display_address'] ?? json['property_address'],
      description: json['description'],
      sendReminder: json['send_reminder'] == true || json['send_reminder'] == 1,
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
  final int? documentId;
  final String documentName;
  final String creatorName;
  final String status;

  CandidateDoc({this.documentId, this.documentName = '', this.creatorName = '', this.status = ''});

  factory CandidateDoc.fromJson(Map<String, dynamic> json) {
    return CandidateDoc(
      documentId: json['document_id'] ?? json['document']?['id'],
      documentName: json['document']?['name'] ?? json['document_name'] ?? '',
      creatorName: json['creator']?['name'] ?? json['creator_name'] ?? '',
      status: json['status'] ?? '',
    );
  }
}

class AgentScorecard {
  final int overallScore;
  final int tasksCompleted;
  final int tasksTotal;
  final int propertiesAttended;
  final int propertiesTotal;

  AgentScorecard({
    this.overallScore = 0,
    this.tasksCompleted = 0,
    this.tasksTotal = 0,
    this.propertiesAttended = 0,
    this.propertiesTotal = 0,
  });

  factory AgentScorecard.fromJson(Map<String, dynamic> json) {
    return AgentScorecard(
      overallScore: json['overall_score'] ?? 0,
      tasksCompleted: json['tasks_completed'] ?? 0,
      tasksTotal: json['tasks_total'] ?? 0,
      propertiesAttended: json['properties_attended'] ?? 0,
      propertiesTotal: json['properties_total'] ?? 0,
    );
  }
}
