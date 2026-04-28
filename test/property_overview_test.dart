import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:corex_mobile/models/gallery_tags.dart';
import 'package:corex_mobile/models/property_overview.dart';
import 'package:corex_mobile/screens/properties/property_overview_screen.dart';
import 'package:corex_mobile/services/api_service.dart';

class _FakeApi extends ApiService {
  PropertyOverview? overview;
  ApiException? overviewError;

  GalleryTagsData? addResult;
  ApiException? addError;

  @override
  Future<PropertyOverview> getPropertyOverview(int id,
      {bool forceRefresh = false}) async {
    if (overviewError != null) throw overviewError!;
    return overview!;
  }

  @override
  Future<GalleryTagsData> addGalleryTag(int propertyId, String tag) async {
    if (addError != null) throw addError!;
    return addResult!;
  }
}

PropertyOverview _baseOverview({List<Placement> placements = const []}) {
  return PropertyOverview(
    id: 7,
    title: '4 Bed House',
    status: 'Active',
    suburb: 'Uvongo',
    city: 'Margate',
    priceDisplay: 'R 2 950 000',
    daysOnMarket: 14,
    placements: placements,
    keyDates: const KeyDates(listed: '2026-01-10', expires: '2026-07-10'),
  );
}

Widget _wrap(Widget child) =>
    MaterialApp(theme: ThemeData.dark(), home: child);

void main() {
  testWidgets('renders placement card with portal URL', (tester) async {
    final api = _FakeApi()
      ..overview = _baseOverview(placements: const [
        Placement(
          key: 'property24',
          label: 'Property24',
          url: 'https://www.property24.com/listing/123',
          live: true,
        ),
      ]);

    await tester.pumpWidget(_wrap(
      PropertyOverviewScreen(propertyId: 7, api: api),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Property24'), findsOneWidget);
    expect(find.text('Live'), findsOneWidget);
    expect(find.text('View on portal'), findsOneWidget);
    expect(find.text('Where this listing is published'), findsOneWidget);
  });

  testWidgets('shows empty state when placements is empty', (tester) async {
    final api = _FakeApi()..overview = _baseOverview(placements: const []);

    await tester.pumpWidget(_wrap(
      PropertyOverviewScreen(propertyId: 7, api: api),
    ));
    await tester.pumpAndSettle();

    expect(
      find.textContaining(
          "isn't published anywhere yet"),
      findsOneWidget,
    );
  });

  test('addGalleryTag happy path returns new tag list', () async {
    final api = _FakeApi()
      ..addResult = GalleryTagsData.fromJson({
        'property_id': 7,
        'available_tags': ['Bedroom 1', 'Sea View'],
        'tag_counts': {'Bedroom 1': 0, 'Sea View': 0},
        'untagged_count': 0,
      });

    final result = await api.addGalleryTag(7, 'Sea View');
    expect(result.availableTags, contains('Sea View'));
    expect(result.availableTags, hasLength(2));
  });

  test('addGalleryTag surfaces 422 as ApiException', () async {
    final api = _FakeApi()..addError = ApiException(422, 'Tag already exists');
    expect(
      () => api.addGalleryTag(7, 'Bedroom 1'),
      throwsA(isA<ApiException>()
          .having((e) => e.statusCode, 'statusCode', 422)
          .having((e) => e.message, 'message', contains('exists'))),
    );
  });
}
