import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/branding.dart';
import '../providers/dashboard_provider.dart';
import '../providers/notifications_provider.dart';
import '../theme.dart';
import '../widgets/bell_icon.dart';
import 'calendar_screen.dart';
import 'tasks_screen.dart';
import 'today/today_screen.dart';

/// App-wide 3-tab shell. After login the agent lands here on Today.
/// The legacy Inbox tab was removed when the `/dashboard` surface was
/// retired — Today's `overdue_items` card now covers that workflow.
class MainTabsScreen extends StatefulWidget {
  const MainTabsScreen({super.key});

  @override
  State<MainTabsScreen> createState() => _MainTabsScreenState();
}

class _MainTabsScreenState extends State<MainTabsScreen> {
  int _index = 0;

  static const _titles = ['Today', 'Calendar', 'Tasks'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadToday();
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
        actions: const [BellIcon()],
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          TodayScreen(),
          CalendarScreen(embedded: true),
          TasksScreen(embedded: true),
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
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.today_rounded), label: 'Today'),
            BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month_rounded), label: 'Calendar'),
            BottomNavigationBarItem(
                icon: Icon(Icons.checklist_rounded), label: 'Tasks'),
          ],
        ),
      ),
    );
  }
}
