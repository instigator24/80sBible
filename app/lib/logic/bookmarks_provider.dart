import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _bookmarksKey = 'bookmarked_passage_ids';

/// Overridden in `main()` with the real `SharedPreferences.getInstance()`
/// result; left unimplemented here so tests are forced to override it
/// explicitly rather than accidentally hitting real device storage.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

class BookmarksNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    return ref.watch(sharedPreferencesProvider).getStringList(_bookmarksKey) ??
        <String>[];
  }

  Future<void> toggle(String passageId) async {
    final next = state.contains(passageId)
        ? state.where((id) => id != passageId).toList()
        : [...state, passageId];
    state = next;
    await ref.read(sharedPreferencesProvider).setStringList(_bookmarksKey, next);
  }
}

final bookmarksProvider = NotifierProvider<BookmarksNotifier, List<String>>(
  BookmarksNotifier.new,
);
