import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

/// The one disk cache every property photo goes through.
///
/// `DefaultCacheManager` keeps 200 objects for 30 days. A single large
/// property is ~90 photos and an agent works several at once, so the default
/// thrashes: the gallery an agent opened this morning is evicted by the ones
/// they browsed this afternoon, and "cached" stops meaning anything. This
/// budget is sized for a working set of a couple of thousand thumbnails —
/// tens of MB, not a concern on any phone that can install the app — and a
/// quarter's staleness, after which a photo is re-validated, not deleted.
///
/// Every `CachedNetworkImage` / `CachedNetworkImageProvider` must pass
/// [manager], or it silently lands in the default store with the default
/// limits and the Settings "Image cache" numbers won't include it.
class CoreXImageCache {
  CoreXImageCache._();

  /// Also the on-disk folder name under the temp directory and the sqlite
  /// index name — `ImageCacheDiagnostics` reads both by this key.
  static const String key = 'corexImages';

  static final CacheManager manager = _CoreXCacheManager();

  /// Decoded-bitmap width for a thumbnail cell: its logical size at the
  /// device's pixel ratio. Without this a 3-column grid decodes every cell at
  /// full camera resolution (~12MP × 4 bytes each) — fine for six photos,
  /// a memory-pressure kill on iPad for ninety.
  static int thumbPx(BuildContext context, double logicalSize) =>
      (logicalSize * MediaQuery.devicePixelRatioOf(context)).ceil();

  /// Drops [urls] from disk and from the in-memory decode cache — for photos
  /// the user just deleted, so a re-add at the same URL can't show the old
  /// bytes.
  static Future<void> evict(Iterable<String> urls) async {
    for (final u in urls) {
      try {
        // flutter_cache_manager 3.4.1 removes the index row but opens the
        // file by its *relative* path when deleting, so the bytes stay on
        // disk (verified: 55 files survived an emptyCache). Resolve the real
        // file first and delete it ourselves.
        final info = await manager.getFileFromCache(u);
        await CachedNetworkImage.evictFromCache(u, cacheManager: manager);
        if (info != null && await info.file.exists()) await info.file.delete();
      } catch (_) {
        // Best effort: an evict that fails leaves a stale file, not a bug.
      }
    }
  }

  /// Empties the index, then removes the folder itself — see [evict] for why
  /// `emptyCache()` alone leaves every file behind.
  static Future<void> clear() async {
    await manager.emptyCache();
    try {
      final dir = Directory('${(await getTemporaryDirectory()).path}/$key');
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
  }
}

/// `ImageCacheManager` is what lets a `CachedNetworkImageProvider` honour
/// `maxWidth` / `maxHeight` (a resized copy is cached on disk under its own
/// key). A plain `CacheManager` given those parameters doesn't fail — it
/// reports "needs to be an ImageCacheManager" through `FlutterError` on
/// every load, which this app's error hook prints as an uncaught error and
/// the Codemagic launch smoke test would grep as a failure.
class _CoreXCacheManager extends CacheManager with ImageCacheManager {
  _CoreXCacheManager()
      : super(Config(
          CoreXImageCache.key,
          stalePeriod: const Duration(days: 90),
          maxNrOfCacheObjects: 2000,
        ));
}
