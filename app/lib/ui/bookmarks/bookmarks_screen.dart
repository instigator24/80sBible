import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/passage_repository.dart';
import '../../logic/bookmarks_provider.dart';

class BookmarksScreen extends ConsumerWidget {
  final PassageRepository repository;
  final void Function(String book, int chapter) onOpenPassage;

  const BookmarksScreen({
    super.key,
    required this.repository,
    required this.onOpenPassage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarkedIds = ref.watch(bookmarksProvider);
    final passages =
        repository.all.where((p) => bookmarkedIds.contains(p.id)).toList();

    if (passages.isEmpty) {
      return const Center(
        key: Key('no-bookmarks-message'),
        child: Text('No bookmarks yet'),
      );
    }

    return ListView(
      children: passages
          .map((p) => ListTile(
                key: Key('bookmark-${p.id}'),
                title: Text(p.reference),
                subtitle: Text(
                  p.slangText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => onOpenPassage(p.book, p.chapter),
              ))
          .toList(),
    );
  }
}
