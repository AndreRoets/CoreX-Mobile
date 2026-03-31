import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/dashboard_provider.dart';

class CreateTaskSheet extends StatefulWidget {
  const CreateTaskSheet({super.key});

  @override
  State<CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends State<CreateTaskSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _priority = 'normal';
  String _taskType = 'custom';
  DateTime? _dueDate;
  bool _sendReminder = true;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) return;
    setState(() => _submitting = true);

    final success = await context.read<DashboardProvider>().createTask(
      title: _titleController.text.trim(),
      taskType: _taskType,
      priority: _priority,
      dueDate: _dueDate?.toIso8601String().split('T').first,
      description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
      sendReminder: _sendReminder,
    );

    if (mounted) {
      if (success) {
        Navigator.pop(context);
      } else {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create task'), backgroundColor: Color(0xFFef4444)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).viewPadding.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 8), decoration: BoxDecoration(color: AppTheme.textMuted(context), borderRadius: BorderRadius.circular(2)))),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
              child: Row(
                children: [
                  Text('New Task', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context))),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close, size: 20, color: AppTheme.textSecondary(context))),
                ],
              ),
            ),
            Divider(height: 1, color: AppTheme.borderColor(context)),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  TextField(
                    controller: _titleController,
                    autofocus: true,
                    style: TextStyle(fontSize: 14, color: AppTheme.textPrimary(context)),
                    decoration: _inputDecoration('Task title'),
                  ),
                  const SizedBox(height: 16),

                  // Priority pills
                  Text('Priority', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textSecondary(context))),
                  const SizedBox(height: 8),
                  _PriorityPills(selected: _priority, onChanged: (v) => setState(() => _priority = v)),
                  const SizedBox(height: 16),

                  // Task type
                  Text('Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textSecondary(context))),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface2(context),
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                      border: Border.all(color: AppTheme.borderColor(context)),
                    ),
                    child: DropdownButtonFormField<String>(
                      initialValue: _taskType,
                      dropdownColor: AppTheme.surface2(context),
                      style: TextStyle(fontSize: 14, color: AppTheme.textPrimary(context)),
                      decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16)),
                      items: const [
                        DropdownMenuItem(value: 'custom', child: Text('Custom')),
                        DropdownMenuItem(value: 'follow_up', child: Text('Follow Up')),
                        DropdownMenuItem(value: 'document_upload', child: Text('Document Upload')),
                        DropdownMenuItem(value: 'compliance', child: Text('Compliance')),
                        DropdownMenuItem(value: 'review', child: Text('Review')),
                        DropdownMenuItem(value: 'deal_action', child: Text('Deal Action')),
                      ],
                      onChanged: (v) => setState(() => _taskType = v ?? 'custom'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Due date
                  Text('Due Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textSecondary(context))),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) => Theme(
                          data: ThemeData.dark().copyWith(colorScheme: ColorScheme.dark(primary: AppTheme.brand, surface: AppTheme.surface(context))),
                          child: child!,
                        ),
                      );
                      if (picked != null) setState(() => _dueDate = picked);
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
                        _dueDate != null ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}' : 'Select date',
                        style: TextStyle(fontSize: 14, color: _dueDate != null ? AppTheme.textPrimary(context) : AppTheme.textMuted(context)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextField(
                    controller: _descriptionController,
                    maxLines: 2,
                    style: TextStyle(fontSize: 14, color: AppTheme.textPrimary(context)),
                    decoration: _inputDecoration('Description (optional)'),
                  ),
                  const SizedBox(height: 16),

                  // Reminder toggle
                  Row(
                    children: [
                      Expanded(child: Text('Send reminder', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary(context)))),
                      Switch.adaptive(
                        value: _sendReminder,
                        onChanged: (v) => setState(() => _sendReminder = v),
                        activeTrackColor: AppTheme.brand,
                      ),
                    ],
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
                          : const Text('Add Task'),
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
      fillColor: AppTheme.surface2(context),
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
                color: isActive ? color.withValues(alpha: 0.15) : AppTheme.surface2(context),
                borderRadius: BorderRadius.circular(AppTheme.radius),
                border: isActive ? Border.all(color: color.withValues(alpha: 0.4)) : null,
              ),
              child: Center(
                child: Text(
                  opt['label'] as String,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isActive ? color : AppTheme.textSecondary(context)),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
