import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/dashboard_provider.dart';
import '../models/dashboard_data.dart';

class OverdueReviewScreen extends StatefulWidget {
  final List<CommandTask> tasks;
  final List<CalendarEvent> events;

  const OverdueReviewScreen({super.key, required this.tasks, required this.events});

  @override
  State<OverdueReviewScreen> createState() => _OverdueReviewScreenState();
}

class _OverdueReviewScreenState extends State<OverdueReviewScreen> {
  late List<_OverdueItem> _items;
  int _currentIndex = 0;
  int _resolvedCount = 0;
  int _extendDays = 3;
  bool _showExtend = false;

  @override
  void initState() {
    super.initState();
    _items = [
      ...widget.tasks.map((t) => _OverdueItem(
        id: t.id, type: 'task', title: t.title,
        typeLabel: t.taskType.replaceAll('_', ' '),
        colour: '#6b7280',
        address: t.propertyAddress,
        overdueSince: t.overdueDuration,
      )),
      ...widget.events.map((e) => _OverdueItem(
        id: e.id, type: 'event', title: e.title,
        typeLabel: e.eventType,
        colour: e.colour,
        address: e.propertyAddress,
        overdueSince: e.overdueDuration,
      )),
    ];
  }

  void _resolve(String resolution) async {
    final item = _items[_currentIndex];
    final dash = context.read<DashboardProvider>();

    if (item.type == 'task') {
      await dash.resolveTask(item.id, resolution: resolution, extendDays: resolution == 'extended' ? _extendDays : null);
    } else {
      await dash.resolveEvent(item.id, resolution: resolution, extendDays: resolution == 'extended' ? _extendDays : null);
    }

    setState(() {
      _resolvedCount++;
      _showExtend = false;
      if (_currentIndex < _items.length - 1) {
        _currentIndex++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final allResolved = _resolvedCount >= _items.length;

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: AppTheme.surface(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppTheme.textSecondary(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Overdue Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context))),
            Text('$_resolvedCount of ${_items.length} resolved', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context))),
          ],
        ),
      ),
      body: Column(
        children: [
          // Progress bar
          Container(
            height: 3,
            color: AppTheme.surface2(context),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 400),
                widthFactor: _items.isNotEmpty ? _resolvedCount / _items.length : 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.brand,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: allResolved
                ? _AllResolvedView(onContinue: () => Navigator.pop(context))
                : _items.isNotEmpty
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: _buildCard(_items[_currentIndex]),
                      )
                    : const SizedBox.shrink(),
          ),

          // Navigation
          if (!allResolved && _items.isNotEmpty)
            Container(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).viewPadding.bottom),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: AppTheme.borderColor(context)))),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _currentIndex > 0 ? () => setState(() { _currentIndex--; _showExtend = false; }) : null,
                    child: Text('← Previous', style: TextStyle(fontSize: 13, color: _currentIndex > 0 ? AppTheme.textSecondary(context) : AppTheme.textMuted(context))),
                  ),
                  const Spacer(),
                  Text('${_currentIndex + 1} / ${_items.length}', style: TextStyle(fontSize: 12, color: AppTheme.textMuted(context))),
                  const Spacer(),
                  GestureDetector(
                    onTap: _currentIndex < _items.length - 1 ? () => setState(() { _currentIndex++; _showExtend = false; }) : null,
                    child: Text('Next →', style: TextStyle(fontSize: 13, color: _currentIndex < _items.length - 1 ? AppTheme.textSecondary(context) : AppTheme.textMuted(context))),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCard(_OverdueItem item) {
    Color colour;
    try {
      colour = Color(int.parse(item.colour.replaceFirst('#', '0xFF')));
    } catch (_) {
      colour = const Color(0xFF6b7280);
    }

    return Column(
      children: [
        // Item card
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface(context),
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(color: AppTheme.borderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 3, decoration: BoxDecoration(color: colour, borderRadius: const BorderRadius.vertical(top: Radius.circular(5)))),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(item.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context)))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: colour.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                          child: Text(item.typeLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: colour)),
                        ),
                      ],
                    ),
                    if (item.address != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textSecondary(context)),
                          const SizedBox(width: 4),
                          Expanded(child: Text(item.address!, style: TextStyle(fontSize: 13, color: AppTheme.textSecondary(context)))),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text('${item.overdueSince} overdue', style: const TextStyle(fontSize: 13, color: Color(0xFFef4444))),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Completed
        _ResolutionButton(
          label: 'Completed',
          icon: Icons.check,
          color: const Color(0xFF22c55e),
          onTap: () => _resolve('completed'),
        ),
        const SizedBox(height: 8),

        // Extend Time
        _ResolutionButton(
          label: 'Extend Time',
          icon: Icons.schedule,
          color: AppTheme.brand,
          trailing: Icon(_showExtend ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 18, color: AppTheme.brand),
          onTap: () => setState(() => _showExtend = !_showExtend),
        ),
        if (_showExtend) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface(context),
              borderRadius: BorderRadius.circular(AppTheme.radius),
              border: Border.all(color: AppTheme.borderColor(context)),
            ),
            child: Row(
              children: [
                Text('Days:', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary(context))),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: AppTheme.surface2(context), borderRadius: BorderRadius.circular(AppTheme.radius)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _extendDays,
                        dropdownColor: AppTheme.surface2(context),
                        style: TextStyle(fontSize: 14, color: AppTheme.textPrimary(context)),
                        items: [1, 2, 3, 5, 7, 14].map((d) => DropdownMenuItem(value: d, child: Text(d == 7 ? '1 week' : d == 14 ? '2 weeks' : '$d day${d > 1 ? 's' : ''}'))).toList(),
                        onChanged: (v) => setState(() => _extendDays = v ?? 3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _resolve('extended'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: AppTheme.brand, borderRadius: BorderRadius.circular(AppTheme.radius)),
                    child: const Text('Extend', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),

        // Did Not Take Place
        _ResolutionButton(
          label: 'Did Not Take Place',
          icon: Icons.block,
          color: const Color(0xFF6b7280),
          onTap: () => _resolve('did_not_happen'),
        ),
      ],
    );
  }
}

class _OverdueItem {
  final int id;
  final String type;
  final String title;
  final String typeLabel;
  final String colour;
  final String? address;
  final String overdueSince;

  _OverdueItem({
    required this.id, required this.type, required this.title,
    required this.typeLabel, required this.colour, this.address,
    required this.overdueSince,
  });
}

class _ResolutionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Widget? trailing;
  final VoidCallback onTap;

  const _ResolutionButton({required this.label, required this.icon, required this.color, this.trailing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radius),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color))),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _AllResolvedView extends StatelessWidget {
  final VoidCallback onContinue;
  const _AllResolvedView({required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(color: const Color(0xFF22c55e).withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.check, size: 32, color: Color(0xFF22c55e)),
          ),
          const SizedBox(height: 16),
          Text('All caught up!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppTheme.textPrimary(context))),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onContinue,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(color: AppTheme.brand, borderRadius: BorderRadius.circular(AppTheme.radius)),
              child: const Text('Continue', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
