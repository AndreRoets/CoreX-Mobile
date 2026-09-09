import 'package:flutter_test/flutter_test.dart';
import 'package:corex_mobile/models/gallery_tags.dart';
import 'package:corex_mobile/models/property.dart';

/// Wire-shape edge cases the gallery manager depends on. Both came out of a
/// review, not a bug report — which is the point: each would have failed the
/// whole property fetch (or silently mis-filed a room) on real data.
void main() {
  group('Property.fromJson gallery fields', () {
    test("PHP's empty associative array (`[]`) for gallery_categories parses, "
        'not throws', () {
      final p = Property.fromJson({
        'id': 1,
        'address': 'x',
        'gallery_images': [],
        'gallery_categories': [], // json_encode([]) — not {}
        'gallery_tags': [],
      });
      expect(p.galleryCategories, isNull);
      expect(p.galleryImages, isEmpty);
      expect(GalleryCategories.fromJson(p.galleryCategories).categories,
          isEmpty);
    });

    test('non-string entries in gallery_images / gallery_tags are stringified, '
        'nulls and blanks dropped', () {
      final p = Property.fromJson({
        'id': 1,
        'address': 'x',
        'gallery_images': ['https://x/a.jpg', 7, null, ''],
        'gallery_tags': ['Kitchen', null, 3],
      });
      expect(p.galleryImages, ['https://x/a.jpg', '7']);
      expect(p.galleryTags, ['Kitchen', '3']);
    });

    test('a real categories map still comes through as a Map', () {
      final p = Property.fromJson({
        'id': 1,
        'address': 'x',
        'gallery_categories': {
          'categories': {
            'Kitchen': ['https://x/a.jpg'],
          },
          'unsorted': ['https://x/b.jpg'],
        },
      });
      final g = GalleryCategories.fromJson(p.galleryCategories);
      expect(g.categories, {
        'Kitchen': ['https://x/a.jpg'],
      });
      expect(g.unsorted, ['https://x/b.jpg']);
    });
  });

  group('GalleryCategories.fromJson and a room named "Unsorted"', () {
    test('modern shape: "Unsorted" under `categories` stays a room', () {
      final g = GalleryCategories.fromJson({
        'categories': {
          'Unsorted': ['https://x/a.jpg'],
          'Kitchen': ['https://x/b.jpg'],
        },
        'unsorted': ['https://x/c.jpg'],
      });
      expect(g.categories.keys, ['Unsorted', 'Kitchen']);
      expect(g.categories['Unsorted'], ['https://x/a.jpg']);
      expect(g.unsorted, ['https://x/c.jpg']);
    });

    test('legacy flat shape: `unsorted` beside the rooms is still the bucket',
        () {
      final g = GalleryCategories.fromJson({
        'Kitchen': ['https://x/b.jpg'],
        'unsorted': ['https://x/c.jpg'],
      });
      expect(g.categories.keys, ['Kitchen']);
      expect(g.unsorted, ['https://x/c.jpg']);
    });
  });
}
