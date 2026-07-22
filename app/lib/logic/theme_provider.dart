import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ui/theme/app_theme.dart';
import 'bookmarks_provider.dart';

const _themeKey = 'app_theme_id';

class ThemeNotifier extends Notifier<AppThemeId> {
  @override
  AppThemeId build() {
    final stored = ref.watch(sharedPreferencesProvider).getString(_themeKey);
    return AppThemeId.values.firstWhere(
      (v) => v.name == stored,
      orElse: () => AppThemeId.pastel,
    );
  }

  Future<void> select(AppThemeId id) async {
    state = id;
    await ref.read(sharedPreferencesProvider).setString(_themeKey, id.name);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, AppThemeId>(
  ThemeNotifier.new,
);
