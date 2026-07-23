import 'package:flutter/material.dart';

import '../../data/models/story.dart';
import '../../data/passage_repository.dart';
import '../../data/story_repository.dart';
import 'story_detail_screen.dart';

class StoriesScreen extends StatefulWidget {
  final StoryRepository storyRepository;
  final PassageRepository passageRepository;

  const StoriesScreen({
    super.key,
    required this.storyRepository,
    required this.passageRepository,
  });

  @override
  State<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen> {
  Testament _testament = Testament.oldTestament;

  void _onTestamentChanged(Set<Testament> selection) {
    setState(() => _testament = selection.first);
  }

  void _openStory(Story story) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StoryDetailScreen(
          story: story,
          passageRepository: widget.passageRepository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stories = widget.storyRepository.forTestament(_testament);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SegmentedButton<Testament>(
            key: const Key('testament-toggle'),
            segments: const [
              ButtonSegment(
                value: Testament.oldTestament,
                label: Text('Old Testament'),
              ),
              ButtonSegment(
                value: Testament.newTestament,
                label: Text('New Testament'),
              ),
            ],
            selected: {_testament},
            onSelectionChanged: _onTestamentChanged,
          ),
        ),
        Expanded(
          child: ListView(
            children: stories
                .map((s) => ListTile(
                      key: Key('story-${s.id}'),
                      title: Text(s.title),
                      subtitle: Text(s.referenceDisplay),
                      onTap: () => _openStory(s),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}
