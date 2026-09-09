import 'package:flutter_test/flutter_test.dart';

import 'package:corex_mobile/models/notification_models.dart';

/// Regression test for a real incident: an agent's `open_hours.enabled` was
/// true but every weekday's window was off — a state the UI lets you reach by
/// flipping the master switch before touching any day — which silenced every
/// notification, permanently, with no visible cause. `allowsAt` must treat an
/// unconfigured schedule (master on, zero days on) as "not yet set up" and
/// fail open, not as "block always".
void main() {
  Map<int, DayWindow> allOffDays() => {
        for (var d = 1; d <= 7; d++)
          d: DayWindow(enabled: false, start: '09:00', end: '17:00'),
      };

  test('enabled with every day off allows notifications (fail open)', () {
    final oh = OpenHours(enabled: true, days: allOffDays());
    expect(oh.allowsAt(DateTime(2026, 9, 8, 3, 0)), isTrue); // 3am Tuesday
  });

  test('enabled with a real configured window still restricts', () {
    final days = allOffDays();
    days[2] = DayWindow(enabled: true, start: '09:00', end: '17:00'); // Tue
    final oh = OpenHours(enabled: true, days: days);

    expect(oh.allowsAt(DateTime(2026, 9, 8, 12, 0)), isTrue); // Tue noon
    expect(oh.allowsAt(DateTime(2026, 9, 8, 3, 0)), isFalse); // Tue 3am
  });

  test('disabled master switch always allows, regardless of days', () {
    final oh = OpenHours(enabled: false, days: allOffDays());
    expect(oh.allowsAt(DateTime(2026, 9, 8, 3, 0)), isTrue);
  });
}
