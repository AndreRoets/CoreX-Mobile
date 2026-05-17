import 'package:flutter/material.dart';
import '../models/visibility.dart';
import '../theme.dart';

/// Agent-filter selector for the Contacts / Properties lists.
///
/// Renders nothing unless [module.canPickAgent] is true. Options are:
///   • "My {noun}"  (default)
///   • "All {noun}"
///   • a dropdown of in-scope agents
///
/// [noun] is the module label, e.g. "Contacts" or "Properties".
class AgentFilterBar extends StatelessWidget {
  final ModuleVisibility module;
  final AgentFilter selected;
  final ValueChanged<AgentFilter> onChanged;
  final String noun;

  const AgentFilterBar({
    super.key,
    required this.module,
    required this.selected,
    required this.onChanged,
    required this.noun,
  });

  @override
  Widget build(BuildContext context) {
    if (!module.canPickAgent) return const SizedBox.shrink();

    final sel = selected;
    final selectedAgentId =
        sel is SpecificAgentFilter ? sel.agentId : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          _chip(
            context,
            label: 'My $noun',
            isSelected: sel is MineFilter,
            onTap: () => onChanged(const MineFilter()),
          ),
          const SizedBox(width: 8),
          _chip(
            context,
            label: 'All $noun',
            isSelected: sel is AllAgentsFilter,
            onTap: () => onChanged(const AllAgentsFilter()),
          ),
          const SizedBox(width: 8),
          Expanded(child: _agentDropdown(context, selectedAgentId)),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: AppTheme.surface2(context),
      selectedColor: AppTheme.brand,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isSelected ? Colors.white : AppTheme.textPrimary(context),
      ),
      side: BorderSide.none,
    );
  }

  Widget _agentDropdown(BuildContext context, int? selectedAgentId) {
    final isActive = selectedAgentId != null;
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.brand : AppTheme.surface2(context),
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          isDense: true,
          value: selectedAgentId,
          hint: Text(
            'Agent',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary(context),
            ),
          ),
          icon: Icon(
            Icons.arrow_drop_down,
            color: isActive ? Colors.white : AppTheme.textPrimary(context),
          ),
          dropdownColor: AppTheme.surface(context),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppTheme.textPrimary(context),
          ),
          selectedItemBuilder: (_) => [
            for (final a in module.agents)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  a.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
          items: [
            for (final a in module.agents)
              DropdownMenuItem<int>(
                value: a.id,
                child: Text(
                  a.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
              ),
          ],
          onChanged: (id) {
            if (id != null) onChanged(SpecificAgentFilter(id));
          },
        ),
      ),
    );
  }
}
