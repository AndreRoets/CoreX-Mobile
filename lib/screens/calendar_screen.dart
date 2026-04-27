import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/dashboard_provider.dart';
import '../models/dashboard_data.dart';
import '../widgets/event_card.dart';
import 'shared/quick_add_sheet.dart';

class CalendarScreen extends StatefulWidget {
  final bool embedded;
  const CalendarScreen({super.key, this.embedded = false});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _currentMonth;
  bool _isAgendaView = false;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEvents();
    });
  }

  void _loadEvents() {
    final month = '${_currentMonth.year}-${_currentMonth.month.toString().padLeft(2, '0')}';
    context.read<DashboardProvider>().loadEvents(month: month);
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      _selectedDate = null;
    });
    _loadEvents();
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      _selectedDate = null;
    });
    _loadEvents();
  }

  Widget _buildBody(BuildContext context, List<CalendarEvent> events) {
    return Column(
        children: [
          // Sticky header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: AppTheme.background(context),
              border: Border(bottom: BorderSide(color: AppTheme.borderColor(context))),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _previousMonth,
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: AppTheme.surface(context), borderRadius: BorderRadius.circular(AppTheme.radius)),
                    child: Icon(Icons.chevron_left, size: 20, color: AppTheme.textSecondary(context)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _monthName(_currentMonth),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context)),
                  ),
                ),
                GestureDetector(
                  onTap: _nextMonth,
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: AppTheme.surface(context), borderRadius: BorderRadius.circular(AppTheme.radius)),
                    child: Icon(Icons.chevron_right, size: 20, color: AppTheme.textSecondary(context)),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
                      _selectedDate = DateTime.now();
                    });
                    _loadEvents();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(color: AppTheme.surface(context), borderRadius: BorderRadius.circular(AppTheme.radius)),
                    child: Text('Today', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textSecondary(context))),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                    border: Border.all(color: AppTheme.borderColor(context)),
                  ),
                  child: Row(
                    children: [
                      _ViewToggle(label: 'Month', active: !_isAgendaView, onTap: () => setState(() => _isAgendaView = false)),
                      _ViewToggle(label: 'Agenda', active: _isAgendaView, onTap: () => setState(() => _isAgendaView = true)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isAgendaView
                ? _AgendaView(events: events)
                : _MonthView(
                    currentMonth: _currentMonth,
                    events: events,
                    selectedDate: _selectedDate,
                    onDateSelected: (date) => setState(() => _selectedDate = date),
                    onSwipeLeft: _nextMonth,
                    onSwipeRight: _previousMonth,
                  ),
          ),
        ],
    );
  }

  Widget _buildFab(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'calendar_fab',
      onPressed: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const QuickAddSheet(initialMode: 'event'),
      ),
      backgroundColor: AppTheme.brand,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    final events = context.watch<DashboardProvider>().events;

    if (widget.embedded) {
      return Stack(
        children: [
          _buildBody(context, events),
          Positioned(right: 16, bottom: 16, child: _buildFab(context)),
        ],
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background(context),
      body: _buildBody(context, events),
      floatingActionButton: _buildFab(context),
    );
  }

  String _monthName(DateTime dt) {
    const months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    return '${months[dt.month - 1]} ${dt.year}';
  }
}

class _ViewToggle extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ViewToggle({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppTheme.brand : AppTheme.surface(context),
          borderRadius: BorderRadius.circular(AppTheme.radius - 1),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: active ? Colors.white : AppTheme.textSecondary(context))),
      ),
    );
  }
}

class _MonthView extends StatelessWidget {
  final DateTime currentMonth;
  final List<CalendarEvent> events;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;

  const _MonthView({
    required this.currentMonth,
    required this.events,
    this.selectedDate,
    required this.onDateSelected,
    required this.onSwipeLeft,
    required this.onSwipeRight,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(currentMonth.year, currentMonth.month, 1);
    final startWeekday = firstDay.weekday; // 1=Mon
    final daysInMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
    final today = DateTime.now();

    // Group events by day
    final byDay = <int, List<CalendarEvent>>{};
    for (final e in events) {
      if (e.eventDate.year == currentMonth.year && e.eventDate.month == currentMonth.month) {
        byDay.putIfAbsent(e.eventDate.day, () => []).add(e);
      }
    }

    // Selected day events
    final selectedDayEvents = selectedDate != null ? (byDay[selectedDate!.day] ?? []) : <CalendarEvent>[];

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -200) onSwipeLeft();
          if (details.primaryVelocity! > 200) onSwipeRight();
        }
      },
      child: Column(
        children: [
          // Day headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: ['M','T','W','T','F','S','S'].map((d) =>
                Expanded(child: Center(child: Text(d, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.textMuted(context))))),
              ).toList(),
            ),
          ),

          // Calendar grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              itemCount: 42,
              itemBuilder: (context, index) {
                final dayOffset = index - (startWeekday - 1);
                if (dayOffset < 0 || dayOffset >= daysInMonth) {
                  return const SizedBox.shrink();
                }
                final day = dayOffset + 1;
                final isToday = today.year == currentMonth.year && today.month == currentMonth.month && today.day == day;
                final isSelected = selectedDate?.day == day && selectedDate?.month == currentMonth.month;
                final dayEvents = byDay[day] ?? [];

                return GestureDetector(
                  onTap: () => onDateSelected(DateTime(currentMonth.year, currentMonth.month, day)),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.brandDark : (isToday ? AppTheme.brand.withValues(alpha: 0.12) : null),
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: isToday ? AppTheme.brand : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$day',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isToday || isSelected ? FontWeight.w600 : FontWeight.w400,
                                color: isToday ? Colors.white : AppTheme.textPrimary(context),
                              ),
                            ),
                          ),
                        ),
                        if (dayEvents.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: dayEvents.take(3).map((e) {
                              Color dotColor;
                              try {
                                dotColor = Color(int.parse(e.colour.replaceFirst('#', '0xFF')));
                              } catch (_) {
                                dotColor = const Color(0xFF6b7280);
                              }
                              return Container(
                                width: 5, height: 5,
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Selected day events
          if (selectedDate != null)
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surface(context),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  border: Border(top: BorderSide(color: AppTheme.borderColor(context))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        children: [
                          Text(
                            _formatSelectedDate(selectedDate!),
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context)),
                          ),
                          const Spacer(),
                          Text('${selectedDayEvents.length} events', style: TextStyle(fontSize: 12, color: AppTheme.textMuted(context))),
                        ],
                      ),
                    ),
                    Expanded(
                      child: selectedDayEvents.isEmpty
                          ? Center(child: Text('No events', style: TextStyle(fontSize: 13, color: AppTheme.textMuted(context))))
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              itemCount: selectedDayEvents.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, i) {
                                final event = selectedDayEvents[i];
                                return EventCard(
                                  event: event,
                                  onComplete: () => context.read<DashboardProvider>().completeEvent(event.id),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Center(
                child: Text('Tap a day to see events', style: TextStyle(fontSize: 13, color: AppTheme.textMuted(context))),
              ),
            ),
        ],
      ),
    );
  }

  String _formatSelectedDate(DateTime dt) {
    const days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    const months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]}';
  }
}

class _AgendaView extends StatelessWidget {
  final List<CalendarEvent> events;
  const _AgendaView({required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: AppTheme.surface(context), shape: BoxShape.circle),
              child: Icon(Icons.calendar_today_rounded, color: AppTheme.textMuted(context), size: 28),
            ),
            const SizedBox(height: 12),
            Text('No events this month', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textSecondary(context))),
          ],
        ),
      );
    }

    // Group by date
    final grouped = <String, List<CalendarEvent>>{};
    for (final e in events) {
      final key = '${e.eventDate.year}-${e.eventDate.month.toString().padLeft(2, '0')}-${e.eventDate.day.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(e);
    }
    final sortedKeys = grouped.keys.toList()..sort();
    final today = DateTime.now();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: sortedKeys.length,
      itemBuilder: (context, i) {
        final dateKey = sortedKeys[i];
        final dayEvents = grouped[dateKey]!;
        final date = DateTime.parse(dateKey);
        final isToday = date.year == today.year && date.month == today.month && date.day == today.day;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  if (isToday)
                    Container(
                      width: 8, height: 8,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: const BoxDecoration(color: AppTheme.brand, shape: BoxShape.circle),
                    ),
                  Text(
                    isToday ? 'Today · ${_formatAgendaDate(date)}' : _formatAgendaDate(date),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isToday ? AppTheme.brand : AppTheme.textSecondary(context)),
                  ),
                ],
              ),
            ),
            ...dayEvents.map((event) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: EventCard(
                event: event,
                onComplete: () => context.read<DashboardProvider>().completeEvent(event.id),
              ),
            )),
          ],
        );
      },
    );
  }

  String _formatAgendaDate(DateTime dt) {
    const days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    const months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    return '${days[dt.weekday - 1]} · ${dt.day} ${months[dt.month - 1]}';
  }
}
