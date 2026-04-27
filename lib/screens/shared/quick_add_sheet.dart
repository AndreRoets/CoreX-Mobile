import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../theme.dart';

/// One sheet, two modes — replaces the separate create-task and create-event
/// sheets. Accepts [initialMode] so callers (Today FAB, Tasks FAB, Calendar
/// FAB) can pre-select the relevant segment.
class QuickAddSheet extends StatefulWidget {
  final String initialMode; // 'task' | 'event'

  const QuickAddSheet({super.key, this.initialMode = 'task'});

  @override
  State<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<QuickAddSheet> {
  late String _mode;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _priority = 'normal';
  bool _sendReminder = true;
  bool _submitting = false;

  // Task
  String _taskType = 'custom';
  DateTime? _dueDate;

  // Event
  String _eventType = 'manual';
  DateTime? _eventDate;
  TimeOfDay? _eventTime;
  bool _allDay = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode == 'event' ? 'event' : 'task';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) return;
    if (_mode == 'event' && _eventDate == null) return;

    setState(() => _submitting = true);
    final dash = context.read<DashboardProvider>();
    bool ok;

    if (_mode == 'task') {
      ok = await dash.createTask(
        title: _titleController.text.trim(),
        taskType: _taskType,
        priority: _priority,
        dueDate: _dueDate?.toIso8601String().split('T').first,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        sendReminder: _sendReminder,
      );
    } else {
      final time = _eventTime ?? const TimeOfDay(hour: 9, minute: 0);
      final dt = DateTime(
        _eventDate!.year, _eventDate!.month, _eventDate!.day,
        time.hour, time.minute,
      );
      ok = await dash.createEvent(
        title: _titleController.text.trim(),
        eventDate: dt.toIso8601String(),
        eventType: _eventType,
        priority: _priority,
        allDay: _allDay,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        sendReminder: _sendReminder,
      );
    }

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create $_mode'),
          backgroundColor: const Color(0xFFef4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).viewPadding.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: AppTheme.textMuted(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
              child: Row(
                children: [
                  Text('Quick Add',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary(context))),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close,
                        size: 20, color: AppTheme.textSecondary(context)),
                  ),
                ],
              ),
            ),

            // Segmented Task | Event
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface2(context),
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  children: [
                    _segment('task', 'Task'),
                    _segment('event', 'Event'),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    autofocus: true,
                    style: TextStyle(
                        fontSize: 14, color: AppTheme.textPrimary(context)),
                    decoration: _inputDecoration(
                        _mode == 'task' ? 'Task title' : 'Event title'),
                  ),
                  const SizedBox(height: 16),

                  if (_mode == 'event') _buildEventDateTime(),
                  if (_mode == 'event') const SizedBox(height: 16),

                  Text('Priority',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary(context))),
                  const SizedBox(height: 8),
                  _PriorityPills(
                      selected: _priority,
                      onChanged: (v) => setState(() => _priority = v)),
                  const SizedBox(height: 16),

                  if (_mode == 'task') ...[
                    Text('Type',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary(context))),
                    const SizedBox(height: 8),
                    _dropdown<String>(
                      value: _taskType,
                      items: const {
                        'custom': 'Custom',
                        'follow_up': 'Follow Up',
                        'document_upload': 'Document Upload',
                        'compliance': 'Compliance',
                        'review': 'Review',
                        'deal_action': 'Deal Action',
                      },
                      onChanged: (v) =>
                          setState(() => _taskType = v ?? 'custom'),
                    ),
                    const SizedBox(height: 16),
                    Text('Due Date',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary(context))),
                    const SizedBox(height: 8),
                    _datePicker(
                      value: _dueDate,
                      onPicked: (d) => setState(() => _dueDate = d),
                      allowPast: false,
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (_mode == 'event') ...[
                    Text('Type',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary(context))),
                    const SizedBox(height: 8),
                    _dropdown<String>(
                      value: _eventType,
                      items: const {
                        'manual': 'Manual',
                        'deal': 'Deal',
                        'lease': 'Lease',
                        'compliance': 'Compliance',
                        'prospecting': 'Prospecting',
                      },
                      onChanged: (v) =>
                          setState(() => _eventType = v ?? 'manual'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                            child: Text('All day',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary(context)))),
                        Switch.adaptive(
                          value: _allDay,
                          onChanged: (v) => setState(() => _allDay = v),
                          activeTrackColor: AppTheme.brand,
                        ),
                      ],
                    ),
                  ],

                  TextField(
                    controller: _descriptionController,
                    maxLines: 2,
                    style: TextStyle(
                        fontSize: 14, color: AppTheme.textPrimary(context)),
                    decoration: _inputDecoration('Description (optional)'),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                          child: Text('Remind me',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary(context)))),
                      Switch.adaptive(
                        value: _sendReminder,
                        onChanged: (v) => setState(() => _sendReminder = v),
                        activeTrackColor: AppTheme.brand,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(_mode == 'task' ? 'Add Task' : 'Add Event'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _segment(String value, String label) {
    final isActive = _mode == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _mode = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.brand : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radius - 1),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : AppTheme.textSecondary(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventDateTime() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Date',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary(context))),
              const SizedBox(height: 8),
              _datePicker(
                value: _eventDate,
                onPicked: (d) => setState(() => _eventDate = d),
                allowPast: true,
              ),
            ],
          ),
        ),
        if (!_allDay) ...[
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Time',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary(context))),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _eventTime ?? TimeOfDay.now(),
                    );
                    if (picked != null) setState(() => _eventTime = picked);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.surface2(context),
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                      border: Border.all(color: AppTheme.borderColor(context)),
                    ),
                    child: Text(
                      _eventTime != null
                          ? '${_eventTime!.hour.toString().padLeft(2, '0')}:${_eventTime!.minute.toString().padLeft(2, '0')}'
                          : 'Select',
                      style: TextStyle(
                        fontSize: 14,
                        color: _eventTime != null
                            ? AppTheme.textPrimary(context)
                            : AppTheme.textMuted(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _datePicker({
    required DateTime? value,
    required ValueChanged<DateTime> onPicked,
    required bool allowPast,
  }) {
    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? (allowPast ? now : now.add(const Duration(days: 1))),
          firstDate: allowPast ? now.subtract(const Duration(days: 30)) : now,
          lastDate: now.add(const Duration(days: 365)),
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface2(context),
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: AppTheme.borderColor(context)),
        ),
        child: Text(
          value != null ? '${value.day}/${value.month}/${value.year}' : 'Select date',
          style: TextStyle(
            fontSize: 14,
            color: value != null
                ? AppTheme.textPrimary(context)
                : AppTheme.textMuted(context),
          ),
        ),
      ),
    );
  }

  Widget _dropdown<T>({
    required T value,
    required Map<T, String> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface2(context),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        dropdownColor: AppTheme.surface2(context),
        style: TextStyle(fontSize: 14, color: AppTheme.textPrimary(context)),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16),
        ),
        items: items.entries
            .map((e) => DropdownMenuItem<T>(value: e.key, child: Text(e.value)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppTheme.surface2(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

class _PriorityPills extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _PriorityPills({required this.selected, required this.onChanged});

  static const _options = [
    {'value': 'low', 'label': 'Low', 'color': 0xFF6b7280},
    {'value': 'normal', 'label': 'Normal', 'color': 0xFF0ea5e9},
    {'value': 'high', 'label': 'High', 'color': 0xFFf59e0b},
    {'value': 'critical', 'label': 'Critical', 'color': 0xFFef4444},
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _options.map((opt) {
        final value = opt['value'] as String;
        final isActive = selected == value;
        final color = Color(opt['color'] as int);
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(value),
            child: Container(
              margin: EdgeInsets.only(right: opt != _options.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isActive ? color.withValues(alpha: 0.15) : AppTheme.surface2(context),
                borderRadius: BorderRadius.circular(AppTheme.radius),
                border: isActive ? Border.all(color: color.withValues(alpha: 0.4)) : null,
              ),
              child: Center(
                child: Text(
                  opt['label'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isActive ? color : AppTheme.textSecondary(context),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
