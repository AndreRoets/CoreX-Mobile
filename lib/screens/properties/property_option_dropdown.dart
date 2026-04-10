import 'package:flutter/material.dart';
import '../../models/property_options.dart';
import '../../theme.dart';

/// Dropdown bound to a `List<PropertyOption>`.
///
/// Handles the three edge cases the spec calls out:
///   - empty list → disabled field with a "no options configured" hint;
///   - a selected value that isn't in the list (an admin disabled it mid-edit)
///     → keep it visible with a "(no longer available)" suffix and a warning
///     chip below, but never silently drop it;
///   - normal case → render display text, emit the submit value via
///     [onChanged].
class PropertyOptionDropdown extends StatelessWidget {
  final List<PropertyOption> options;
  final String? value;
  final ValueChanged<String?> onChanged;
  final String? emptyHint;

  const PropertyOptionDropdown({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.emptyHint,
  });

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.darkSurface2.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: AppTheme.darkSurface2),
        ),
        child: Text(
          emptyHint ??
              'No options configured — ask your admin to set them up',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textMuted(context),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    final knownValues = options.map((o) => o.submit).toSet();
    final isStale = value != null && value!.isNotEmpty && !knownValues.contains(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          items: [
            ...options.map(
              (o) => DropdownMenuItem<String>(
                value: o.submit,
                child: Text(o.display),
              ),
            ),
            if (isStale)
              DropdownMenuItem<String>(
                value: value,
                child: Text(
                  '$value (no longer available)',
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
          onChanged: onChanged,
          dropdownColor: AppTheme.darkSurface,
          decoration: const InputDecoration(),
        ),
        if (isStale)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 14, color: Colors.orange.shade400),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'This value is no longer available — pick a new one',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange.shade400,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
