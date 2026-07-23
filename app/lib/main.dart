import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/bible_books.dart';
import 'data/passage_repository.dart';
import 'data/story_repository.dart';
import 'logic/bookmarks_provider.dart';
import 'logic/theme_provider.dart';
import 'ui/bookmarks/bookmarks_screen.dart';
import 'ui/home/home_screen.dart';
import 'ui/reader/reader_screen.dart';
import 'ui/search/search_screen.dart';
import 'ui/settings/settings_screen.dart';
import 'ui/stories/stories_screen.dart';
import 'ui/theme/app_theme.dart';
import 'ui/theme/theme_decoration.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final repository = await PassageRepository.loadFromAssets(kBookAssetPaths);
  final storyRepository = await StoryRepository.loadFromAssets(kStoriesAssetPath);

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: SlangBibleApp(
        repository: repository,
        storyRepository: storyRepository,
      ),
    ),
  );
}

class SlangBibleApp extends ConsumerWidget {
  final PassageRepository repository;
  final StoryRepository storyRepository;

  const SlangBibleApp({
    super.key,
    required this.repository,
    required this.storyRepository,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeId = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Slang Bible',
      theme: buildTheme(themeId),
      home: RootShell(repository: repository, storyRepository: storyRepository),
    );
  }
}

class RootShell extends ConsumerStatefulWidget {
  final PassageRepository repository;
  final StoryRepository storyRepository;

  const RootShell({
    super.key,
    required this.repository,
    required this.storyRepository,
  });

  @override
  ConsumerState<RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<RootShell> {
  int _tabIndex = 0;
  String? _pendingBook;
  int? _pendingChapter;
  int _navSeq = 0;

  void _openInReader(String book, int chapter) {
    setState(() {
      _pendingBook = book;
      _pendingChapter = chapter;
      _navSeq++;
      _tabIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeId = ref.watch(themeProvider);
    final screens = [
      HomeScreen(repository: widget.repository, onOpenPassage: _openInReader),
      ReaderScreen(
        key: ValueKey('$_pendingBook-$_pendingChapter-$_navSeq'),
        repository: widget.repository,
        initialBook: _pendingBook,
        initialChapter: _pendingChapter,
      ),
      BookmarksScreen(
        repository: widget.repository,
        onOpenPassage: _openInReader,
      ),
      SearchScreen(repository: widget.repository, onOpenPassage: _openInReader),
      const SettingsScreen(),
      StoriesScreen(
        storyRepository: widget.storyRepository,
        passageRepository: widget.repository,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("80's Bible")),
      body: Stack(
        children: [
          Positioned.fill(child: rootBackgroundForTheme(themeId)),
          IndexedStack(index: _tabIndex, children: screens),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'Reader'),
          NavigationDestination(icon: Icon(Icons.star), label: 'Bookmarks'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.palette), label: 'Settings'),
          NavigationDestination(icon: Icon(Icons.auto_stories), label: 'Stories'),
        ],
      ),
    );
  }
}
