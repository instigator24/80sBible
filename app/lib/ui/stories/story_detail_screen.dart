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
    return ListView(
      children: [for (final range in story.references) _rangeWidget(range)],
    );
  }

  Widget _rangeWidget(StoryReferenceRange range) {
    final passages = repository.passagesForChapterRange(
      range.book,
      range.chapterStart,
      range.chapterEnd,
    );
    if (passages.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          key: Key('not-translated-message-${range.book}-${range.chapterStart}'),
          child: const Text('Not translated yet'),
        ),
      );
    }
    return Column(
      children: [
        for (final p in passages) PassageCard(key: ValueKey(p.id), passage: p),
      ],
    );
  }
}
