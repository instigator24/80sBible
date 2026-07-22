import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slang_bible/logic/bookmarks_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> makeContainer(
      {Map<String, Object> initial = const {}}) async {
    SharedPreferences.setMockInitialValues(initial);
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('bookmarksProvider', () {
    test('starts empty when no bookmarks are stored', () async {
      final container = await makeContainer();
      expect(container.read(bookmarksProvider), isEmpty);
    });

    test('starts with previously stored bookmarks', () async {
      final container = await makeContainer(initial: {
        'bookmarked_passage_ids': ['John-1-1-4'],
      });
      expect(container.read(bookmarksProvider), ['John-1-1-4']);
    });

    test('toggle adds an id and persists it', () async {
      final container = await makeContainer();
      await container.read(bookmarksProvider.notifier).toggle('John-1-1-4');

      expect(container.read(bookmarksProvider), ['John-1-1-4']);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('bookmarked_passage_ids'), ['John-1-1-4']);
    });

    test('toggle removes an id that is already bookmarked', () async {
      final container = await makeContainer(initial: {
        'bookmarked_passage_ids': ['John-1-1-4'],
      });
      await container.read(bookmarksProvider.notifier).toggle('John-1-1-4');

      expect(container.read(bookmarksProvider), isEmpty);
    });
  });
}
