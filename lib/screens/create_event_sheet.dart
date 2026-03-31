import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/dashboard_provider.dart';

class CreateEventSheet extends StatefulWidget {
  const CreateEventSheet({super.key});

  @override
  State<CreateEventSheet> createState() => _CreateEventSheetState();
}

class _CreateEventSheetState extends State<CreateEventSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _priority = 'normal';
  String _eventType = 'manual';
  DateTime? _eventDate;
  TimeOfDay? _eventTime;
  bool _allDay = false;
  bool _sendReminder = true;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: AppTheme.brand, surface: AppTheme.surface)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _eventDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _eventTime ?? TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: AppTheme.brand, surface: AppTheme.surface)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _eventTime = picked);
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty || _eventDate == null) return;
    setState(() => _submitting = true);

    final date = _eventDate!;
    final time = _eventTime ?? const TimeOfDay(hour: 9, minute: 0);
    final dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    final success = await context.read<DashboardProvider>().createEvent(
      title: _titleController.text.trim(),
      eventDate: dateTime.toIso8601String(),
      eventType: _eventType,
      priority: _priority,
      allDay: _allDay,
      description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
      sendReminder: _sendReminder,
    );

    if (mounted) {
      if (success) {
        Navigator.pop(context);
      } else {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create event'), backgroundColor: Color(0xFFef4444)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).viewPadding.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 8), decoration: BoxDecoration(color: AppTheme.textMuted, borderRadius: BorderRadius.circular(2)))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
              child: Row(
                children: [
                  const Text('New Event', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, size: 20, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.border),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  TextField(
                    controller: _titleController,
                    autofocus: true,
                    style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                    decoration: _inputDecoration('Event title'),
                  ),
                  const SizedBox(height: 16),

                  // Date & Time
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: _pickDate,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(color: AppTheme.surface2, borderRadius: BorderRadius.circular(AppTheme.radius), border: Border.all(color: AppTheme.border)),
                                child: Text(
                                  _eventDate != null ? '${_eventDate!.day}/${_eventDate!.month}/${_eventDate!.year}' : 'Select',
                                  style: TextStyle(fontSize: 14, color: _eventDate != null ? AppTheme.textPrimary : AppTheme.textMuted),
                                ),
                              ),
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
                              const Text('Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: _pickTime,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(color: AppTheme.surface2, borderRadius: BorderRadius.circular(AppTheme.radius), border: Border.all(color: AppTheme.border)),
                                  child: Text(
                                    _eventTime != null ? '${_eventTime!.hour.toString().padLeft(2, '0')}:${_eventTime!.minute.toString().padLeft(2, '0')}' : 'Select',
                                    style: TextStyle(fontSize: 14, color: _eventTime != null ? AppTheme.textPrimary : AppTheme.textMuted),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Type
                  const Text('Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(color: AppTheme.surface2, borderRadius: BorderRadius.circular(AppTheme.radius), border: Border.all(color: AppTheme.border)),
                    child: DropdownButtonFormField<String>(
                      initialValue: _eventType,
                      dropdownColor: AppTheme.surface2,
                      style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                      decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16)),
                      items: const [
                        DropdownMenuItem(value: 'manual', child: Text('Manual')),
                        DropdownMenuItem(value: 'deal', child: Text('Deal')),
                        DropdownMenuItem(value: 'lease', child: Text('Lease')),
                        DropdownMenuItem(value: 'compliance', child: Text('Compliance')),
                        DropdownMenuItem(value: 'prospecting', child: Text('Prospecting')),
                      ],
                      onChanged: (v) => setState(() => _eventType = v ?? 'manual'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Priority
                  const Text('Priority', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  _PriorityPills(selected: _priority, onChanged: (v) => setState(() => _priority = v)),
                  const SizedBox(height: 16),

                  // Toggles
                  Row(
                    children: [
                      const Expanded(child: Text('All day', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary))),
                      Switch.adaptive(value: _allDay, onChanged: (v) => setState(() => _allDay = v), activeTrackColor: AppTheme.brand),
                    ],
                  ),
                  Row(
                    children: [
                      const Expanded(child: Text('Send reminder', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary))),
                      Switch.adaptive(value: _sendReminder, onChanged: (v) => setState(() => _sendReminder = v), activeTrackColor: AppTheme.brand),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Description
                  TextField(
                    controller: _descriptionController,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                    decoration: _inputDecoration('Description (optional)'),
                  ),
                  const SizedBox(height: 20),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Add Event'),
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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppTheme.surface2,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radius), borderSide: BorderSide.none),
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
                color: isActive ? color.withValues(alpha: 0.15) : AppTheme.surface2,
                borderRadius: BorderRadius.circular(AppTheme.radius),
                border: isActive ? Border.all(color: color.withValues(alpha: 0.4)) : null,
              ),
              child: Center(
                child: Text(opt['label'] as String, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isActive ? color : AppTheme.textSecondary)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
