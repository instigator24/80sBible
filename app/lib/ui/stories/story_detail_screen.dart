import 'package:flutter/material.dart';

import '../../data/models/story.dart';
import '../../data/passage_repository.dart';
import '../reader/passage_card.dart';

class StoryDetailScreen extends StatelessWidget {
  final Story story;
  final PassageRepository repository;

  const StoryDetailScreen({
    super.key,
    required this.story,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(story.title),
          bottom: const TabBar(
            tabs: [Tab(text: 'Summary'), Tab(text: 'Verses')],
          ),
        ),
        body: TabBarView(
          children: [
            _SummaryTab(story: story),
            _VersesTab(story: story, repository: repository),
          ],
        ),
      ),
    );
  }
}

class _SummaryTab extends StatelessWidget {
  final Story story;

  const _SummaryTab({required this.story});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            story.referenceDisplay,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Text(story.summary),
        ],
      ),
    );
  }
}

class _VersesTab extends StatelessWidget {
  final Story story;
  final PassageRepository repository;

  const _VersesTab({required this.story, required this.repository});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (final range in story.references) {
      final passages = repository.passagesForChapterRange(
        range.book,
        range.chapterStart,
        range.chapterEnd,
      );
      if (passages.isEmpty) {
        children.add(
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              key: Key('not-translated-message'),
              child: Text('Not translated yet'),
            ),
          ),
        );
      } else {
        children.addAll(passages.map((p) => PassageCard(passage: p)));
      }
    }
    return ListView(children: children);
  }
}
