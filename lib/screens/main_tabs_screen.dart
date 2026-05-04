import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/branding.dart';
import '../providers/dashboard_provider.dart';
import '../providers/notifications_provider.dart';
import '../theme.dart';
import '../widgets/bell_icon.dart';
import 'calendar_screen.dart';
import 'inbox/inbox_screen.dart';
import 'tasks_screen.dart';
import 'today/today_screen.dart';

/// App-wide 5-tab shell. Replaces the old HomeHubScreen → DashboardScreen
/// route chain: after login the agent lands here, on the Today tab.
class MainTabsScreen extends StatefulWidget {
  const MainTabsScreen({super.key});

  @override
  State<MainTabsScreen> createState() => _MainTabsScreenState();
}

class _MainTabsScreenState extends State<MainTabsScreen> {
  int _index = 0;

  static const _titles = ['Today', 'Calendar', 'Tasks', 'Inbox'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadDashboard();
      final notes = context.read<NotificationsProvider>();
      notes.loadFeed();
      notes.loadOverdue();
    });
  }

  void _jumpTo(int i) {
    if (i != _index) HapticFeedback.selectionClick();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final inboxTotal = context.select<DashboardProvider, int>(
      (p) => p.data.inboxTotal,
    );
    final brand = BrandColors.of(context);

    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        title: Text(_titles[_index]),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: AppTheme.textPrimary(context)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          const BellIcon(),
          if (_index == 0 && inboxTotal > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: GestureDetector(
                  onTap: () => _jumpTo(3),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFef4444).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                      border: Border.all(
                        color: const Color(0xFFef4444).withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      '$inboxTotal need action',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFef4444),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: [
          TodayScreen(onJumpToInbox: () => _jumpTo(3)),
          const CalendarScreen(embedded: true),
          const TasksScreen(embedded: true),
          const InboxScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.borderColor(context))),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: _jumpTo,
          backgroundColor: AppTheme.surface(context),
          selectedItemColor: brand.sidebar,
          unselectedItemColor: AppTheme.textMuted(context),
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.today_rounded), label: 'Today'),
            const BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_rounded), label: 'Calendar'),
            const BottomNavigationBarItem(
              icon: Icon(Icons.checklist_rounded), label: 'Tasks'),
            BottomNavigationBarItem(
              icon: _InboxIcon(count: inboxTotal),
              label: 'Inbox',
            ),
          ],
        ),
      ),
    );
  }

  // Exposed for debug only — current tab title.
  // ignore: unused_element
  String get _title => _titles[_index];
}

/// Inbox icon with a small dot (never a "9+" badge) when there's anything
/// actionable. Count itself lives on the Today header + Inbox header.
class _InboxIcon extends StatelessWidget {
  final int count;
  const _InboxIcon({required this.count});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.inbox_rounded),
        if (count > 0)
          Positioned(
            right: -3,
            top: -3,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFef4444),
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
