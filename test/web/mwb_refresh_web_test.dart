@TestOn('browser')
library;

import 'package:agora/data/mwb_cache.dart';
import 'package:agora/data/mwb_repository.dart';
import 'package:agora/data/mwb_store_web.dart';
import 'package:flutter_test/flutter_test.dart';

/// The manual catalog refresh was the one path that still asked the browser
/// for the workbook file itself. Every attempt died on the file host's missing
/// CORS header, and on the deployed site the page's Content-Security-Policy
/// blocked it a step earlier still — so each press logged a violation and
/// answered "could not refresh", as though the network had merely been
/// unlucky.
///
/// Run with: flutter test --platform chrome test/web
void main() {
  test('refreshing refuses instead of reaching for the file', () async {
    final repository = MwbRepository(MwbCache(store: IndexedDbMwbStore()));

    await expectLater(
      repository.refresh('202607', 'S'),
      throwsA(isA<NotebookNotDownloadable>()),
    );
  });
}
