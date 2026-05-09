class TaskNote {
  final int id;
  final String body;
  final int userId;
  final String userName;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaskNote({
    required this.id,
    required this.body,
    required this.userId,
    required this.userName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TaskNote.fromJson(Map<String, dynamic> j) => TaskNote(
        id: (j['id'] as num).toInt(),
        body: j['body']?.toString() ?? '',
        userId: (j['user_id'] as num?)?.toInt() ?? 0,
        userName: j['user_name']?.toString() ?? '',
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(j['updated_at']?.toString() ?? '') ?? DateTime.now(),
      );
}

class ChecklistItem {
  final String id;
  final String text;
  final bool done;

  ChecklistItem({required this.id, required this.text, required this.done});

  factory ChecklistItem.fromJson(Map<String, dynamic> j) => ChecklistItem(
        id: j['id']?.toString() ?? '',
        text: j['text']?.toString() ?? '',
        done: j['done'] == true,
      );

  ChecklistItem copyWith({String? text, bool? done}) =>
      ChecklistItem(id: id, text: text ?? this.text, done: done ?? this.done);
}
